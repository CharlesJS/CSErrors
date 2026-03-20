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
import Testing

@Suite("Errno URL Support Tests")
struct ErrnoURLSupportTests {
    private func checkTypeAndCode(error: some Error, code: Int32, cocoaCode: CocoaError.Code) throws {
        let cocoaError = try #require(error as? CocoaError)
        let errnoError = try #require(cocoaError.underlyingError as? Errno)

        #expect(cocoaError.code == cocoaCode)
        #expect(errnoError.rawValue == code)
    }

    private func checkMapping(code: Int32, cocoaCode: CocoaError.Code, isWrite: Bool = false) throws {
        let fileErr = errno(code, url: URL(filePath: "/path/to/file"), isWrite: isWrite)
        try self.checkTypeAndCode(error: fileErr, code: code, cocoaCode: cocoaCode)
        #expect((fileErr as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String == "/path/to/file")
        #expect((fileErr as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == URL(filePath: "/path/to/file"))

        let remoteURL = URL(string: "https://www.something.com/path/to/file")!
        let remoteErr = errno(code, url: remoteURL, isWrite: isWrite)
        try self.checkTypeAndCode(error: remoteErr, code: code, cocoaCode: cocoaCode)
        #expect((remoteErr as? CocoaError)?.userInfo[NSFilePathErrorKey] == nil)
        #expect((remoteErr as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == remoteURL)
    }

    @Test("CocoaError translation")
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

    @Test("Unmappable error")
    func testUnmappableError() {
        let url = URL(filePath: "/path/to/file")

        #expect(errno(EINVAL, url: url) as? Errno == Errno.invalidArgument)
        #expect(errno(EBADF, url: url) as? Errno == Errno.badFileDescriptor)
        #expect(errno(EINTR, url: url) as? Errno == Errno.interrupted)
    }

    @Test("System errno")
    func testSystemErrno() throws {
        let url = URL(filePath: "/path/to/some/file")

        Foundation.errno = ENOENT
        let enoent = errno(url: url, isWrite: true)
        try self.checkTypeAndCode(error: enoent, code: ENOENT, cocoaCode: .fileNoSuchFile)
        #expect((enoent as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == url)
        #expect((enoent as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String == url.path)

        Foundation.errno = ECANCELED
        let canceled = errno(url: url)
        try self.checkTypeAndCode(error: canceled, code: ECANCELED, cocoaCode: .userCancelled)
        #expect((canceled as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == url)
        #expect((canceled as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String == url.path)

        Foundation.errno = EINTR
        #expect(errno(url: url) as? Errno == Errno.interrupted)
    }

    @Test("POSIX function")
    func testPOSIXFunction() throws {
        let url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)

        try "Testing 1 2 3".write(to: url, atomically: true, encoding: .utf8)
        #expect(throws: Never.self) { try callPOSIXFunction(expect: .zero, url: url, isWrite: true) { unlink(url.path) } }


        let unlinkError = try #require(throws: CocoaError.self) {
            try callPOSIXFunction(expect: .zero, url: url, isWrite: true) { unlink(url.path) }
        }

        #expect(unlinkError.code == .fileNoSuchFile)
        #expect((unlinkError.userInfo[NSURLErrorKey] as? URL) == url)
        #expect((unlinkError.userInfo[NSFilePathErrorKey] as? String) == url.path)

        let opendirError = try #require(throws: CocoaError.self) {
            try callPOSIXFunction(url: url) { opendir(url.path) }
        }

        #expect(opendirError.code == .fileReadNoSuchFile)
        #expect((opendirError.userInfo[NSURLErrorKey] as? URL) == url)
        #expect((opendirError.userInfo[NSFilePathErrorKey] as? String) == url.path)

        #expect(try #require(throws: Errno.self) { try callPOSIXFunction(url: url) { acl_init(-1) } } == .invalidArgument)

        let acl: acl_t = try callPOSIXFunction(url: url) { acl_init(0) }
        defer { acl_free(UnsafeMutableRawPointer(acl)) }

        var optionalACL: acl_t? = acl

        let aclEntry = try callPOSIXFunction(expect: .zero, url: url) { acl_create_entry(&optionalACL, $0) }

        #expect(try #require(throws: Errno.self) {
            try callPOSIXFunction(url: url) { acl_get_qualifier(aclEntry) }
        } == .invalidArgument)

        try callPOSIXFunction(expect: .zero, url: url) { acl_set_tag_type(aclEntry, ACL_EXTENDED_ALLOW) }

        #expect(throws: Never.self) {
            let qualifier = try callPOSIXFunction(url: url) { acl_get_qualifier(aclEntry) }
            acl_free(qualifier)
        }
    }
}

#endif
