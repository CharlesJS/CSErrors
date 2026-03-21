//
//  POSIXErrorTests.swift
//
//
//  Created by Charles Srstka on 1/15/23.
//

#if Foundation

import Testing
@testable import CSErrors

#if canImport(Darwin)
import Darwin
func setErrno(_ e: Int32) { Darwin.errno = e }
#elseif canImport(Glibc)
import Glibc
func setErrno(_ e: Int32) { Glibc.errno = e }
#endif

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

@Suite("POSIXError Tests")
struct POSIXErrorTests {
    private static let nonexistentPath: String = {
        let path = "/does/not/exist/\(UUID().uuidString)"
        #expect(!FileManager.default.fileExists(atPath: path)) // just in case
        return path
    }()

    private func assertErrno<I: BinaryInteger>(_ err: Errno, closure: () throws -> I) {
        let thrownError = #expect(throws: Swift.Error.self) { try closure() }
#if Foundation
        switch err {
        case .noSuchFileOrDirectory:
            #expect((thrownError as? CocoaError)?.code == .fileReadNoSuchFile)
        default:
            #expect(thrownError as? Errno == err)
        }
#else
        #expect(thrownError as? Errno == err)
#endif
    }

    @Test("isFileNotFoundError")
    func testFileNotFound() {
        #expect(Errno.noSuchFileOrDirectory.isFileNotFoundError)
        #expect(!Errno.invalidArgument.isFileNotFoundError)

        #expect(POSIXError(.ENOENT).isFileNotFoundError)
        #expect(!POSIXError(.EINVAL).isFileNotFoundError)

        #expect(GenericError(_domain: POSIXError.posixErrorDomain, _code: Int(ENOENT)).isFileNotFoundError)
        #expect(!GenericError(_domain: POSIXError.posixErrorDomain, _code: Int(EINVAL)).isFileNotFoundError)
    }

    @Test("isPermissionError")
    func testPermissionError() {
        #expect(Errno.permissionDenied.isPermissionError)
        #expect(Errno.notPermitted.isPermissionError)
        #expect(!Errno.noSuchFileOrDirectory.isPermissionError)

        #expect(POSIXError(.EACCES).isPermissionError)
        #expect(POSIXError(.EPERM).isPermissionError)
        #expect(!POSIXError(.ENOENT).isPermissionError)

        #expect(GenericError(_domain: POSIXError.posixErrorDomain, _code: Int(EACCES)).isPermissionError)
        #expect(GenericError(_domain: POSIXError.posixErrorDomain, _code: Int(EPERM)).isPermissionError)
        #expect(!GenericError(_domain: POSIXError.posixErrorDomain, _code: Int(ENOENT)).isPermissionError)
    }

    @Test("isCancelledError")
    func testCancelledError() {
        #expect(Errno.canceled.isCancelledError)
        #expect(!Errno.notPermitted.isCancelledError)

        #expect(POSIXError(.ECANCELED).isCancelledError)
        #expect(!POSIXError(.EINVAL).isCancelledError)

        #expect(GenericError(_domain: POSIXError.posixErrorDomain, _code: Int(ECANCELED)).isCancelledError)
        #expect(!GenericError(_domain: POSIXError.posixErrorDomain, _code: Int(EINVAL)).isCancelledError)
    }

    @Test("toErrno() conversion")
    func testToErrno() {
        let kPOSIXErrorEINVAL = 100022

        #expect(Errno.invalidArgument.toErrno() == EINVAL)
        #expect(OSStatusError(rawValue: OSStatus(kPOSIXErrorEINVAL)).toErrno() == EINVAL)
        #expect(POSIXError(.EINVAL).toErrno() == EINVAL)
        #expect(GenericError(_domain: POSIXError.posixErrorDomain, _code: Int(EINVAL)).toErrno() == EINVAL)
        #expect(GenericError(_domain: OSStatusError.osStatusErrorDomain, _code: kPOSIXErrorEINVAL).toErrno() == EINVAL)
#if canImport(Darwin)
        #expect(NSError(domain: POSIXError.posixErrorDomain, code: Int(EINVAL)).toErrno() == EINVAL)
        #expect(NSError(domain: OSStatusError.osStatusErrorDomain, code: kPOSIXErrorEINVAL).toErrno() == EINVAL)
#endif
        #expect(CocoaError(.fileReadNoSuchFile).toErrno() == nil)
    }

    @Test("errno() returns correct Errno")
    func testSystemErrno() {
        setErrno(EINVAL)
        #expect(errno() as? Errno == .invalidArgument)
        #expect(errno(path: "/dev/null") as? Errno == .invalidArgument)
        #expect(errno(path: FilePath("/dev/null")) as? Errno == .invalidArgument)

        setErrno(EBADF)
        #expect(errno() as? Errno == .badFileDescriptor)
        #expect(errno(path: "/dev/null") as? Errno == .badFileDescriptor)
        #expect(errno(path: FilePath("/dev/null")) as? Errno == .badFileDescriptor)

        setErrno(ECANCELED)
#if Foundation
        #expect((errno() as? CocoaError)?.code == .userCancelled)
        #expect((errno(path: "/dev/null") as? CocoaError)?.code == .userCancelled)
        #expect((errno(path: FilePath("/dev/null")) as? CocoaError)?.code == .userCancelled)
#else
        #expect(errno() as? Errno == .canceled)
        #expect(errno(path: "/dev/null") as? Errno == .canceled)
        #expect(errno(path: FilePath("/dev/null")) as? Errno == .canceled)
#endif
    }

    @Test("Passed-in errno()")
    func testPassedInErrno() {
        #expect(errno(EINVAL) as? Errno == .invalidArgument)
        #expect(errno(EBADF) as? Errno == .badFileDescriptor)

#if Foundation
        #expect((errno(ECANCELED) as? CocoaError)?.code == .userCancelled)
#else
        #expect(errno(ECANCELED) as? Errno == .canceled)
#endif
    }

    @Test("errno(0) maps to unknown errors")
    func testZeroErrno() {
        #expect((errno(0) as? CocoaError)?.code == .fileReadUnknown)
        #expect((errno(0, path: "/dev/null" as String) as? CocoaError)?.code == .fileReadUnknown)
        #expect((errno(0, path: "/dev/null" as FilePath) as? CocoaError)?.code == .fileReadUnknown)

        #expect((errno(0, isWrite: true) as? CocoaError)?.code == .fileWriteUnknown)
        #expect((errno(0, path: "/dev/null" as String, isWrite: true) as? CocoaError)?.code == .fileWriteUnknown)
        #expect((errno(0, path: "/dev/null" as FilePath, isWrite: true) as? CocoaError)?.code == .fileWriteUnknown)
    }

#if os(macOS)
    @Test("errno behavior on macOS 10.x")
    func testErrnoOnMacOS10() {
        emulateMacOSVersion(10) {
            for eachCode in [EINVAL, EBADF, ECANCELED] {
                let err = errno(eachCode)

#if Foundation
                if eachCode == ECANCELED {
                    #expect((err as? CocoaError)?.code == .userCancelled)
                } else {
                    #expect(((err as? POSIXError)?.code.rawValue == eachCode))
                }
#else
                #expect(err is GenericError)
                #expect(err._domain == POSIXError.posixErrorDomain)
                #expect(err._code == Int(eachCode))
#endif
            }
        }
    }
#endif

    @Test("callPOSIXFunction on function that returns zero on success")
    func testFunctionWithZeroReturn() throws {
        let url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)

        try "Testing 1 2 3".write(to: url, atomically: true, encoding: .utf8)
        #expect(throws: Never.self) { try callPOSIXFunction(expect: .zero) { unlink(url.path) } }
        self.assertErrno(.noSuchFileOrDirectory) { try callPOSIXFunction(expect: .zero) { unlink(url.path) } }
    }

    @Test("callPOSIXFunction on function that returns negative on error")
    func testFunctionWithNonNegativeReturn() throws {
        try {
            let fd = try callPOSIXFunction(expect: .nonNegative) { open("/dev/null", O_RDONLY) }
            defer { #expect(close(fd) == 0) }

            #expect(fd > 2)

            var bytesRead = try callPOSIXFunction(expect: .nonNegative) { read(fd, nil, 0) }
            #expect(bytesRead == 0)

            bytesRead = try callPOSIXFunction(expect: .nonNegative, path: FilePath("/dev/null")) { read(fd, nil, 0) }
            #expect(bytesRead == 0)
        }()

        try {
            let fd = try callPOSIXFunction(expect: .nonNegative) { open("/dev/random", O_RDONLY) }
            defer { #expect(close(fd) == 0) }

            #expect(fd > 2)

            var bytesRead = try callPOSIXFunction(expect: .nonNegative) {
                var data = Data(count: 10)

                return data.withUnsafeMutableBytes {
                    read(fd, $0.baseAddress, $0.count)
                }
            }
            #expect(bytesRead == 10)

            bytesRead = try callPOSIXFunction(expect: .nonNegative, path: FilePath("/dev/random")) {
                var data = Data(count: 10)

                return data.withUnsafeMutableBytes {
                    read(fd, $0.baseAddress, $0.count)
                }
            }
            #expect(bytesRead == 10)
        }()

        self.assertErrno(.noSuchFileOrDirectory) {
            try callPOSIXFunction(expect: .nonNegative) { open(Self.nonexistentPath, O_RDONLY) }
        }

        self.assertErrno(.noSuchFileOrDirectory) {
            try callPOSIXFunction(expect: .nonNegative, path: FilePath(Self.nonexistentPath)) {
                open(Self.nonexistentPath, O_RDONLY)
            }
        }
    }

    @Test("callPOSIXFunction on function that returns a specific value for success")
    func testFunctionWithSpecificReturn() throws {
        func someWeirdThingThatExpects5(_ i: Int32) -> Int32 {
            if i != 5 {
                setErrno(EINVAL)
            }
            return i
        }

        #expect(throws: Never.self) { try callPOSIXFunction(expect: .specific(5)) { someWeirdThingThatExpects5(5) } }

        self.assertErrno(.invalidArgument) {
            try callPOSIXFunction(expect: .specific(5)) { someWeirdThingThatExpects5(4) }
        }
    }

    @Test("callPOSIXFunction on function that returns a specific value for error")
    func testFunctionWithNotSpecificReturn() {
        #expect(throws: Never.self) { try callPOSIXFunction(expect: .notSpecific(-1)) { fcntl(STDOUT_FILENO, F_GETFD) } }

        self.assertErrno(.badFileDescriptor) {
            try callPOSIXFunction(expect: .notSpecific(-1)) { fcntl(-99, F_GETFD) }
        }

        func returnsOtherNegative() -> Int32 { -2 }

        #expect(throws: Never.self) { try callPOSIXFunction(expect: .notSpecific(-1)) { returnsOtherNegative() } }
    }

    @Test("callPOSIXFunction on function that returns by reference")
    func testReturnByReference() throws {
        let url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
        try "Hello World".write(to: url, atomically: true, encoding: .ascii)
        defer { _ = try? FileManager.default.removeItem(at: url) }

        try FileManager.default.setAttributes(
            [.ownerAccountID: getuid(), .posixPermissions: 0o751],
            ofItemAtPath: url.path
        )

        let info = try callPOSIXFunction(expect: .zero, path: url.path) { lstat(url.path, $0) }
        #expect(info.st_size == 11)
        #expect(info.st_mode == 0o100751)
        #expect(info.st_uid == getuid())

        try "Why Hello There World".write(to: url, atomically: true, encoding: .ascii)

        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: url.path)

        let info2 = try callPOSIXFunction(expect: .zero, path: FilePath(url.path)) { lstat(url.path, $0) }
        #expect(info2.st_size == 21)
        #expect(info2.st_mode == 0o100644)

#if Foundation
        #expect(
            try #require(throws: CocoaError.self) {
                try callPOSIXFunction(expect: .zero) { lstat(Self.nonexistentPath, $0) }
            }.code == .fileReadNoSuchFile
        )

        try #require(throws: CocoaError.self) {
            try callPOSIXFunction(expect: .zero, path: FilePath(Self.nonexistentPath)) {
                lstat(Self.nonexistentPath, $0)
            }
        }
#else
        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(expect: .zero) { lstat(Self.nonexistentPath, $0) }
            } == .noSuchFileOrDirectory
        )

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(expect: .zero, path: FilePath(Self.nonexistentPath)) {
                    lstat(Self.nonexistentPath, $0)
                }
            } == .noSuchFileOrDirectory
        )
#endif
    }

    @Test("callPOSIXFunction on function that returns pointer directly")
    func testDirectPointerReturn() throws {
        let tempURL = FileManager.default.temporaryDirectory
        let tempFileName = UUID().uuidString
        let tempFileURL = tempURL.appending(path: tempFileName)

#if canImport(Darwin)
        typealias DirType = UnsafeMutablePointer<DIR>
        func nameLen(_ entry: UnsafeMutablePointer<dirent>) -> Int { Int(entry.pointee.d_namlen) }
#else
        typealias DirType = OpaquePointer
        func nameLen(_ entry: UnsafeMutablePointer<dirent>) -> Int {
            withUnsafeBytes(of: entry.pointee.d_name) { strlen($0.baseAddress!) }
        }
#endif

        try Data().write(to: tempFileURL)
        defer { _ = try? FileManager.default.removeItem(at: tempFileURL) }

        func checkDir(_ dir: DirType) -> Bool {
            defer { closedir(dir) }
            var foundIt = false

            while let entry = readdir(dir) {
                var nameBytes = entry.pointee.d_name
                let name = withUnsafePointer(to: &nameBytes) {
                    String(data: Data(bytes: $0, count: nameLen(entry)), encoding: .utf8)
                }

                if name == tempFileName {
                    foundIt = true
                }
            }

            return foundIt
        }

        #expect(checkDir(try callPOSIXFunction(path: tempURL.path) { opendir(tempURL.path) }))
        #expect(checkDir(try callPOSIXFunction(path: FilePath(tempURL.path)) { opendir(tempURL.path) }))

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(path: tempURL.path) { opendir(tempFileURL.path) }
            } == .notDirectory
        )

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(path: FilePath(tempURL.path)) { opendir(tempFileURL.path) }
            } == .notDirectory
        )
    }

    @Test("callPOSIXFunction with .returnValue errorFrom")
    func testDirectErrorReturn() throws {
        var attr = pthread_mutexattr_t()
        try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) { pthread_mutexattr_init(&attr) }
        defer {
            #expect(throws: Never.self) {
                _ = try? callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                    pthread_mutexattr_destroy(&attr)
                }
            }
        }

        #expect(throws: Never.self) {
            try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_NORMAL))
            }
        }

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                    pthread_mutexattr_settype(&attr, -99999)
                }
            } == .invalidArgument
        )
    }
}

#endif

