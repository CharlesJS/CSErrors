//
//  ErrnoURLSupportTests.swift
//  
//
//  Created by Charles Srstka on 1/15/23.
//

#if Foundation

import CSErrors
import Foundation
import System
import XCTest

@available(macOS 13.0, *)
class ErrnoURLSupportTests: XCTestCase {
    private func checkTypeAndCode(error: some Error, code: Int32, cocoaCode: CocoaError.Code) throws {
        let cocoaError = try XCTUnwrap(error as? CocoaError)
        let errnoError = try XCTUnwrap(cocoaError.underlyingError as? Errno)

        XCTAssertEqual(cocoaError.code, cocoaCode)
        XCTAssertEqual(errnoError.rawValue, code)
    }

    private func checkMapping(code: Int32, cocoaCode: CocoaError.Code, isWrite: Bool = false) throws {
        let fileErr = errno(code, url: URL(filePath: "/path/to/file"), isWrite: isWrite)
        try self.checkTypeAndCode(error: fileErr, code: code, cocoaCode: cocoaCode)
        XCTAssertEqual((fileErr as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String, "/path/to/file")
        XCTAssertEqual((fileErr as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, URL(filePath: "/path/to/file"))

        let remoteURL = URL(string: "https://www.something.com/path/to/file")!
        let remoteErr = errno(code, url: remoteURL, isWrite: isWrite)
        try self.checkTypeAndCode(error: remoteErr, code: code, cocoaCode: cocoaCode)
        XCTAssertNil((remoteErr as? CocoaError)?.userInfo[NSFilePathErrorKey])
        XCTAssertEqual((remoteErr as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, remoteURL)
    }

    func testCocoaErrorTranslation() throws {
        try self.checkMapping(code: EPERM, cocoaCode: .fileReadNoPermission, isWrite: false)
        try self.checkMapping(code: EPERM, cocoaCode: .fileWriteNoPermission, isWrite: true)
        try self.checkMapping(code: ENOENT, cocoaCode: .fileReadNoSuchFile, isWrite: false)
        try self.checkMapping(code: ENOENT, cocoaCode: .fileNoSuchFile, isWrite: true)
        try self.checkMapping(code: EEXIST, cocoaCode: .fileWriteFileExists)
        try self.checkMapping(code: EFBIG, cocoaCode: .fileReadTooLarge)
        try self.checkMapping(code: ENOSPC, cocoaCode: .fileWriteOutOfSpace)
        try self.checkMapping(code: EROFS, cocoaCode: .fileWriteVolumeReadOnly)
        try self.checkMapping(code: EFTYPE, cocoaCode: .fileReadCorruptFile)
        try self.checkMapping(code: ECANCELED, cocoaCode: .userCancelled)
    }

    func testUnmappableError() {
        let url = URL(filePath: "/path/to/file")

        XCTAssertEqual(errno(EINVAL, url: url) as? Errno, Errno.invalidArgument)
        XCTAssertEqual(errno(EBADF, url: url) as? Errno, Errno.badFileDescriptor)
        XCTAssertEqual(errno(EINTR, url: url) as? Errno, Errno.interrupted)
    }

    func testSystemErrno() throws {
        let url = URL(filePath: "/path/to/some/file")

        Foundation.errno = ENOENT
        let enoent = errno(url: url, isWrite: true)
        try self.checkTypeAndCode(error: enoent, code: ENOENT, cocoaCode: .fileNoSuchFile)
        XCTAssertEqual((enoent as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, url)
        XCTAssertEqual((enoent as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String, url.path)

        Foundation.errno = ECANCELED
        let canceled = errno(url: url)
        try self.checkTypeAndCode(error: canceled, code: ECANCELED, cocoaCode: .userCancelled)
        XCTAssertEqual((canceled as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, url)
        XCTAssertEqual((canceled as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String, url.path)

        Foundation.errno = EINTR
        XCTAssertEqual(errno(url: url) as? Errno, Errno.interrupted)
    }

    func testPOSIXFunction() throws {
        let url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)

        try "Testing 1 2 3".write(to: url, atomically: true, encoding: .utf8)
        XCTAssertNoThrow(try callPOSIXFunction(expect: .zero, url: url, isWrite: true) { unlink(url.path) })

        XCTAssertThrowsError(try callPOSIXFunction(expect: .zero, url: url, isWrite: true) { unlink(url.path) }) {
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileNoSuchFile)
            XCTAssertEqual(($0 as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, url)
            XCTAssertEqual(($0 as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String, url.path)
        }

        XCTAssertThrowsError(try callPOSIXFunction(url: url) { opendir(url.path) }) {
            XCTAssertEqual(($0 as? CocoaError)?.code, .fileReadNoSuchFile)
            XCTAssertEqual(($0 as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, url)
            XCTAssertEqual(($0 as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String, url.path)
        }

        XCTAssertThrowsError(try callPOSIXFunction(url: url) { acl_init(-1) }) {
            XCTAssertEqual($0 as? Errno, .invalidArgument)
        }

        let acl: acl_t = try callPOSIXFunction(url: url) { acl_init(0) }
        defer { acl_free(UnsafeMutableRawPointer(acl)) }

        var optionalACL: acl_t? = acl

        let aclEntry = try callPOSIXFunction(expect: .zero, url: url) { acl_create_entry(&optionalACL, $0) }

        XCTAssertThrowsError(try callPOSIXFunction(url: url) { acl_get_qualifier(aclEntry) }) {
            XCTAssertEqual($0 as? Errno, .invalidArgument)
        }

        try callPOSIXFunction(expect: .zero, url: url) { acl_set_tag_type(aclEntry, ACL_EXTENDED_ALLOW) }

        let qualifier = try callPOSIXFunction(url: url) { acl_get_qualifier(aclEntry) }
        defer { acl_free(qualifier) }

        XCTAssertNotNil(qualifier)
    }
}

#endif
