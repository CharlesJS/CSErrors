//
//  ErrnoURLSupportTests.swift
//  
//
//  Created by Charles Srstka on 1/15/23.
//

import CSErrors_Foundation
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

        var err: Error? = nil
        XCTAssertThrowsError(try callPOSIXFunction(expect: .zero, url: url, isWrite: true) { unlink(url.path) }) { err = $0 }

        let cocoaErr = try XCTUnwrap(err as? CocoaError)
        XCTAssertEqual(cocoaErr.code, .fileNoSuchFile)
        XCTAssertEqual(cocoaErr.userInfo[NSURLErrorKey] as? URL, url)
        XCTAssertEqual(cocoaErr.userInfo[NSFilePathErrorKey] as? String, url.path)
    }
}
