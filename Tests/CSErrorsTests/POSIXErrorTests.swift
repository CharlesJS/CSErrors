//
//  POSIXErrorTests.swift
//  
//
//  Created by Charles Srstka on 1/15/23.
//

import System
import XCTest
@_spi(CSErrorsInternal) @testable import CSErrors

@available(macOS 13.0, *)
class POSIXErrorTests: XCTestCase {
    private static let nonexistentPath: String = {
        let path = "/does/not/exist/\(UUID().uuidString)"
        XCTAssertFalse(FileManager.default.fileExists(atPath: path)) // just in case

        return path
    }()

    private func assertErrno<I: BinaryInteger>(_ err: Errno, closure: () throws -> I) {
        XCTAssertThrowsError(try closure()) { XCTAssertEqual($0 as? Errno, err) }
    }

    func testFileNotFound() {
        XCTAssertTrue(Errno.noSuchFileOrDirectory.isFileNotFoundError)
        XCTAssertFalse(Errno.invalidArgument.isFileNotFoundError)

        XCTAssertTrue(POSIXError(.ENOENT).isFileNotFoundError)
        XCTAssertFalse(POSIXError(.EINVAL).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).isFileNotFoundError)

        XCTAssertTrue(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(ENOENT)).isFileNotFoundError)
        XCTAssertFalse(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EINVAL)).isFileNotFoundError)
    }

    func testPermissionError() {
        XCTAssertTrue(Errno.permissionDenied.isPermissionError)
        XCTAssertTrue(Errno.notPermitted.isPermissionError)
        XCTAssertFalse(Errno.noSuchFileOrDirectory.isPermissionError)

        XCTAssertTrue(POSIXError(.EACCES).isPermissionError)
        XCTAssertTrue(POSIXError(.EPERM).isPermissionError)
        XCTAssertFalse(POSIXError(.ENOENT).isPermissionError)

        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES)).isPermissionError)
        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM)).isPermissionError)
        XCTAssertFalse(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)).isPermissionError)

        XCTAssertTrue(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EACCES)).isPermissionError)
        XCTAssertTrue(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EPERM)).isPermissionError)
        XCTAssertFalse(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(ENOENT)).isPermissionError)
    }

    func testCancelledError() {
        XCTAssertTrue(Errno.canceled.isCancelledError)
        XCTAssertFalse(Errno.notPermitted.isCancelledError)

        XCTAssertTrue(POSIXError(.ECANCELED).isCancelledError)
        XCTAssertFalse(POSIXError(.EINVAL).isCancelledError)

        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(ECANCELED)).isCancelledError)
        XCTAssertFalse(NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).isCancelledError)

        XCTAssertTrue(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(ECANCELED)).isCancelledError)
        XCTAssertFalse(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EINVAL)).isCancelledError)
    }

    func testToErrno() {
        XCTAssertEqual(Errno.invalidArgument.toErrno(), EINVAL)
        XCTAssertEqual(OSStatusError(rawValue: OSStatus(kPOSIXErrorEINVAL)).toErrno(), EINVAL)
        XCTAssertEqual(POSIXError(.EINVAL).toErrno(), EINVAL)
        XCTAssertEqual(NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).toErrno(), EINVAL)
        XCTAssertEqual(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EINVAL)).toErrno(), EINVAL)
        XCTAssertEqual(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorEINVAL).toErrno(), EINVAL)
        XCTAssertEqual(GenericError(_domain: NSOSStatusErrorDomain, _code: kPOSIXErrorEINVAL).toErrno(), EINVAL)
        XCTAssertNil(CocoaError(.fileReadNoSuchFile).toErrno())
    }

    func testSystemErrno() {
        Foundation.errno = EINVAL
        XCTAssertEqual(errno() as? Errno, .invalidArgument)
        XCTAssertEqual(errno(path: "/dev/null") as? Errno, .invalidArgument)
        XCTAssertEqual(errno(path: FilePath("/dev/null")) as? Errno, .invalidArgument)

        Foundation.errno = EBADF
        XCTAssertEqual(errno() as? Errno, .badFileDescriptor)
        XCTAssertEqual(errno(path: "/dev/null") as? Errno, .badFileDescriptor)
        XCTAssertEqual(errno(path: FilePath("/dev/null")) as? Errno, .badFileDescriptor)

        Foundation.errno = ECANCELED
        XCTAssertEqual(errno() as? Errno, .canceled)
        XCTAssertEqual(errno(path: "/dev/null") as? Errno, .canceled)
        XCTAssertEqual(errno(path: FilePath("/dev/null")) as? Errno, .canceled)
    }

    func testPassedInErrno() {
        XCTAssertEqual(errno(EINVAL) as? Errno, .invalidArgument)
        XCTAssertEqual(errno(EBADF) as? Errno, .badFileDescriptor)
        XCTAssertEqual(errno(ECANCELED) as? Errno, .canceled)
    }

    func testZeroErrno() {
        XCTAssertEqual(errno(0) as NSError, CocoaError(.fileReadUnknown) as NSError)
        XCTAssertEqual(errno(0, path: "/dev/null") as NSError, CocoaError(.fileReadUnknown) as NSError)
        XCTAssertEqual(errno(0, path: FilePath("/dev/null")) as NSError, CocoaError(.fileReadUnknown) as NSError)

        XCTAssertEqual(errno(0, isWrite: true) as NSError, CocoaError(.fileWriteUnknown) as NSError)
        XCTAssertEqual(errno(0, path: "/dev/null", isWrite: true) as NSError, CocoaError(.fileWriteUnknown) as NSError)
        XCTAssertEqual(
            errno(0, path: FilePath("/dev/null"), isWrite: true) as NSError,
            CocoaError(.fileWriteUnknown) as NSError
        )
    }

    func testFunctionWithZeroReturn() throws {
        let url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)

        try "Testing 1 2 3".write(to: url, atomically: true, encoding: .utf8)
        XCTAssertNoThrow(try callPOSIXFunction(expect: .zero) { unlink(url.path) })
        self.assertErrno(.noSuchFileOrDirectory) { try callPOSIXFunction(expect: . zero) { unlink(url.path) } }
    }

    func testFunctionWithNonNegativeReturn() {
        XCTAssertNoThrow(try {
            let fd = try callPOSIXFunction(expect: .nonNegative) { Darwin.open("/dev/null", O_RDONLY) }
            defer { XCTAssertEqual(Darwin.close(fd), 0) }

            XCTAssertGreaterThan(fd, 2)

            var bytesRead = try callPOSIXFunction(expect: .nonNegative) { Darwin.read(fd, nil, 0) }
            XCTAssertEqual(bytesRead, 0)

            bytesRead = try callPOSIXFunction(expect: .nonNegative, path: FilePath("/dev/null")) { Darwin.read(fd, nil, 0) }
            XCTAssertEqual(bytesRead, 0)
        }())

        XCTAssertNoThrow(try {
            let fd = try callPOSIXFunction(expect: .nonNegative) { Darwin.open("/dev/random", O_RDONLY) }
            defer { XCTAssertEqual(Darwin.close(fd), 0) }

            XCTAssertGreaterThan(fd, 2)

            var bytesRead = try callPOSIXFunction(expect: .nonNegative) {
                var data = Data(count: 10)

                return data.withUnsafeMutableBytes {
                    Darwin.read(fd, $0.baseAddress, $0.count)
                }
            }
            XCTAssertEqual(bytesRead, 10)

            bytesRead = try callPOSIXFunction(expect: .nonNegative, path: FilePath("/dev/random")) {
                var data = Data(count: 10)

                return data.withUnsafeMutableBytes {
                    Darwin.read(fd, $0.baseAddress, $0.count)
                }
            }
            XCTAssertEqual(bytesRead, 10)
        }())

        self.assertErrno(.noSuchFileOrDirectory) {
            try callPOSIXFunction(expect: .nonNegative) { Darwin.open(Self.nonexistentPath, O_RDONLY) }
        }

        self.assertErrno(.noSuchFileOrDirectory) {
            try callPOSIXFunction(expect: .nonNegative, path: FilePath(Self.nonexistentPath)) {
                Darwin.open(Self.nonexistentPath, O_RDONLY)
            }
        }
    }

    func testFunctionWithSpecificReturn() {
        func someWeirdThingThatExpects5(_ i: Int32) -> Int32 {
            if i != 5 {
                Foundation.errno = EINVAL
            }

            return i
        }

        XCTAssertNoThrow(try callPOSIXFunction(expect: .specific(5)) { someWeirdThingThatExpects5(5) })

        self.assertErrno(.invalidArgument) {
            try callPOSIXFunction(expect: .specific(5)) { someWeirdThingThatExpects5(4) }
        }
    }

    func testReturnByReference() throws {
        var url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
        try "Hello World".write(to: url, atomically: true, encoding: .ascii)
        defer { _ = try? FileManager.default.removeItem(at: url) }

        var resourceValues = try url.resourceValues(forKeys: [.fileSecurityKey])
        CFFileSecuritySetMode(resourceValues.fileSecurity as CFFileSecurity?, 0o751)
        CFFileSecuritySetOwner(resourceValues.fileSecurity as CFFileSecurity?, getuid())
        try url.setResourceValues(resourceValues)

        let info = try callPOSIXFunction(expect: .zero, path: url.path) { lstat(url.path, $0) }
        XCTAssertEqual(info.st_size, 11)
        XCTAssertEqual(info.st_mode, 0o100751)
        XCTAssertEqual(info.st_uid, getuid())

        try "Why Hello There World".write(to: url, atomically: true, encoding: .ascii)

        resourceValues = try url.resourceValues(forKeys: [.fileSecurityKey])
        CFFileSecuritySetMode(resourceValues.fileSecurity as CFFileSecurity?, 0o644)
        try url.setResourceValues(resourceValues)

        let info2 = try callPOSIXFunction(expect: .zero, path: FilePath(url.path)) { lstat(url.path, $0) }
        XCTAssertEqual(info2.st_size, 21)
        XCTAssertEqual(info2.st_mode, 0o100644)

        XCTAssertThrowsError(try callPOSIXFunction(expect: .zero) { lstat(Self.nonexistentPath, $0) }) {
            XCTAssertEqual($0 as? Errno, .noSuchFileOrDirectory)
        }

        XCTAssertThrowsError(try callPOSIXFunction(expect: .zero, path: FilePath(Self.nonexistentPath)) {
            lstat(Self.nonexistentPath, $0)
        }) {
            XCTAssertEqual($0 as? Errno, .noSuchFileOrDirectory)
        }
    }

    func testDirectErrorReturn() {
        var attr: posix_spawnattr_t? = nil

        XCTAssertNoThrow(attr = try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) { posix_spawnattr_init($0) })
        defer {
            XCTAssertNoThrow(try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                posix_spawnattr_destroy(&attr)
            })
        }

        XCTAssertNoThrow(
            try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                posix_spawnattr_setflags(&attr, 1)
            }
        )

        XCTAssertThrowsError(
            try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) { posix_spawnattr_setflags(nil, 1) }
        ) {
            XCTAssertEqual($0 as? Errno, .invalidArgument)
        }
    }
}
