//
//  ErrnoURLSupportTests.swift
//
//
//  Created by Charles Srstka on 1/15/23.
//

#if Foundation

@testable import CSErrors
import Testing

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

@Suite("Errno URL Support Tests")
struct ErrnoURLSupportTests {
    private func checkTypeAndCode(error: some Error, code: Int32, cocoaCode: CocoaError.Code) throws {
        let cocoaError = try #require(error as? CocoaError)
        #expect(cocoaError.code == cocoaCode)

#if canImport(Darwin)
        let errnoError = try #require(cocoaError.underlyingError as? Errno)
        #expect(errnoError.rawValue == code)
#endif
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
#if canImport(Darwin)
        try self.checkMapping(code: EFTYPE, cocoaCode: .fileReadCorruptFile)
#endif
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

        setErrno(ENOENT)
        let enoent = errno(url: url, isWrite: true)
        try self.checkTypeAndCode(error: enoent, code: ENOENT, cocoaCode: .fileNoSuchFile)
        #expect((enoent as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == url)
        #expect((enoent as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String == url.path)

        setErrno(ECANCELED)
        let canceled = errno(url: url)
        try self.checkTypeAndCode(error: canceled, code: ECANCELED, cocoaCode: .userCancelled)
        #expect((canceled as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == url)
        #expect((canceled as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String == url.path)

        setErrno(EINTR)
        #expect(errno(url: url) as? Errno == Errno.interrupted)
    }

    @Test("POSIX function")
    func testPOSIXFunction() throws {
        let url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)

        try "Testing 1 2 3".write(to: url, atomically: true, encoding: .utf8)

        #expect(try #require(throws: Errno.self) {
            try callPOSIXFunction(url: url) { fopen(url.path, "z") }
        } == .invalidArgument)

        #expect(throws: Never.self) {
            let file = try callPOSIXFunction(url: url) { fopen(url.path, "r") }
            fclose(file)
        }

        let limit = try callPOSIXFunction(expect: .zero, url: url) {
#if canImport(Darwin)
            getrlimit(RLIMIT_CORE, $0)
#else
            getrlimit(Int32(RLIMIT_CORE.rawValue), $0)
#endif
        }
        #expect(limit.rlim_max >= limit.rlim_cur)

        #expect(try #require(throws: Errno.self) {
            _ = try callPOSIXFunction(expect: .zero, url: url) { getrlimit(999, $0) }
        } == .invalidArgument)

        try callPOSIXFunction(expect: .zero, url: url) { kill(getpid(), 0) }
        #expect(try #require(throws: Errno.self) {
            try callPOSIXFunction(expect: .zero, url: url) { kill(getpid(), -1) }
        } == .invalidArgument)

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
    }
}

#endif
