//
//  POSIXErrorTests.swift
//
//
//  Created by Charles Srstka on 1/15/23.
//

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

        #expect(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(ENOENT)).isFileNotFoundError)
        #expect(!GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EINVAL)).isFileNotFoundError)
    }

    @Test("isPermissionError")
    func testPermissionError() {
        #expect(Errno.permissionDenied.isPermissionError)
        #expect(Errno.notPermitted.isPermissionError)
        #expect(!Errno.noSuchFileOrDirectory.isPermissionError)

        #expect(POSIXError(.EACCES).isPermissionError)
        #expect(POSIXError(.EPERM).isPermissionError)
        #expect(!POSIXError(.ENOENT).isPermissionError)

        #expect(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EACCES)).isPermissionError)
        #expect(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EPERM)).isPermissionError)
        #expect(!GenericError(_domain: NSPOSIXErrorDomain, _code: Int(ENOENT)).isPermissionError)
    }

    @Test("isCancelledError")
    func testCancelledError() {
        #expect(Errno.canceled.isCancelledError)
        #expect(!Errno.notPermitted.isCancelledError)

        #expect(POSIXError(.ECANCELED).isCancelledError)
        #expect(!POSIXError(.EINVAL).isCancelledError)

        #expect(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(ECANCELED)).isCancelledError)
        #expect(!GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EINVAL)).isCancelledError)
    }

    @Test("toErrno() conversion")
    func testToErrno() {
        #expect(Errno.invalidArgument.toErrno() == EINVAL)
        #expect(OSStatusError(rawValue: OSStatus(kPOSIXErrorEINVAL)).toErrno() == EINVAL)
        #expect(POSIXError(.EINVAL).toErrno() == EINVAL)
        #expect(NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).toErrno() == EINVAL)
        #expect(GenericError(_domain: NSPOSIXErrorDomain, _code: Int(EINVAL)).toErrno() == EINVAL)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorEINVAL).toErrno() == EINVAL)
        #expect(GenericError(_domain: NSOSStatusErrorDomain, _code: kPOSIXErrorEINVAL).toErrno() == EINVAL)
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
        #expect(errno(0) as NSError == CocoaError(.fileReadUnknown) as NSError)
        #expect(errno(0, path: "/dev/null") as NSError == CocoaError(.fileReadUnknown) as NSError)
        #expect(errno(0, path: FilePath("/dev/null")) as NSError == CocoaError(.fileReadUnknown) as NSError)

        #expect(errno(0, isWrite: true) as NSError == CocoaError(.fileWriteUnknown) as NSError)
        #expect(errno(0, path: "/dev/null", isWrite: true) as NSError == CocoaError(.fileWriteUnknown) as NSError)
        #expect(
            errno(0, path: FilePath("/dev/null"), isWrite: true) as NSError
                == CocoaError(.fileWriteUnknown) as NSError
        )
    }

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
                #expect(err._domain == NSPOSIXErrorDomain)
                #expect(err._code == Int(eachCode))
#endif
            }
        }
    }

    @Test("callPOSIXFunction with .zero expectation")
    func testFunctionWithZeroReturn() throws {
        let url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)

        try "Testing 1 2 3".write(to: url, atomically: true, encoding: .utf8)
        #expect(throws: Never.self) { try callPOSIXFunction(expect: .zero) { unlink(url.path) } }
        self.assertErrno(.noSuchFileOrDirectory) { try callPOSIXFunction(expect: .zero) { unlink(url.path) } }
    }

    @Test("callPOSIXFunction with .nonNegative expectation")
    func testFunctionWithNonNegativeReturn() throws {
        try {
            let fd = try callPOSIXFunction(expect: .nonNegative) { Darwin.open("/dev/null", O_RDONLY) }
            defer { #expect(Darwin.close(fd) == 0) }

            #expect(fd > 2)

            var bytesRead = try callPOSIXFunction(expect: .nonNegative) { Darwin.read(fd, nil, 0) }
            #expect(bytesRead == 0)

            bytesRead = try callPOSIXFunction(expect: .nonNegative, path: FilePath("/dev/null")) { Darwin.read(fd, nil, 0) }
            #expect(bytesRead == 0)
        }()

        try {
            let fd = try callPOSIXFunction(expect: .nonNegative) { Darwin.open("/dev/random", O_RDONLY) }
            defer { #expect(Darwin.close(fd) == 0) }

            #expect(fd > 2)

            var bytesRead = try callPOSIXFunction(expect: .nonNegative) {
                var data = Data(count: 10)

                return data.withUnsafeMutableBytes {
                    Darwin.read(fd, $0.baseAddress, $0.count)
                }
            }
            #expect(bytesRead == 10)

            bytesRead = try callPOSIXFunction(expect: .nonNegative, path: FilePath("/dev/random")) {
                var data = Data(count: 10)

                return data.withUnsafeMutableBytes {
                    Darwin.read(fd, $0.baseAddress, $0.count)
                }
            }
            #expect(bytesRead == 10)
        }()

        self.assertErrno(.noSuchFileOrDirectory) {
            try callPOSIXFunction(expect: .nonNegative) { Darwin.open(Self.nonexistentPath, O_RDONLY) }
        }

        self.assertErrno(.noSuchFileOrDirectory) {
            try callPOSIXFunction(expect: .nonNegative, path: FilePath(Self.nonexistentPath)) {
                Darwin.open(Self.nonexistentPath, O_RDONLY)
            }
        }
    }

    @Test("callPOSIXFunction with .specific expectation")
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

    @Test("callPOSIXFunction with .notSpecific expectation")
    func testFunctionWithNotSpecificReturn() {
        #expect(throws: Never.self) { try callPOSIXFunction(expect: .notSpecific(-1)) { fcntl(STDOUT_FILENO, F_GETFD) } }

        self.assertErrno(.badFileDescriptor) {
            try callPOSIXFunction(expect: .notSpecific(-1)) { fcntl(-99, F_GETFD) }
        }

        func returnsOtherNegative() -> Int32 { -2 }

        #expect(throws: Never.self) { try callPOSIXFunction(expect: .notSpecific(-1)) { returnsOtherNegative() } }
    }

    @Test("callPOSIXFunction with .zero and path — lstat()")
    func testReturnByReference() throws {
        var url = FileManager.default.temporaryDirectory.appending(component: UUID().uuidString)
        try "Hello World".write(to: url, atomically: true, encoding: .ascii)
        defer { _ = try? FileManager.default.removeItem(at: url) }

        var resourceValues = try url.resourceValues(forKeys: [.fileSecurityKey])
        CFFileSecuritySetMode(resourceValues.fileSecurity as CFFileSecurity?, 0o751)
        CFFileSecuritySetOwner(resourceValues.fileSecurity as CFFileSecurity?, getuid())
        try url.setResourceValues(resourceValues)

        let info = try callPOSIXFunction(expect: .zero, path: url.path) { lstat(url.path, $0) }
        #expect(info.st_size == 11)
        #expect(info.st_mode == 0o100751)
        #expect(info.st_uid == getuid())

        try "Why Hello There World".write(to: url, atomically: true, encoding: .ascii)

        resourceValues = try url.resourceValues(forKeys: [.fileSecurityKey])
        CFFileSecuritySetMode(resourceValues.fileSecurity as CFFileSecurity?, 0o644)
        try url.setResourceValues(resourceValues)

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

    @Test("callPOSIXFunction with direct pointer returns — opendir()")
    func testDirectPointerReturn() throws {
        let tempURL = FileManager.default.temporaryDirectory
        let tempFileName = UUID().uuidString
        let tempFileURL = tempURL.appending(path: tempFileName)

        try Data().write(to: tempFileURL)
        defer { _ = try? FileManager.default.removeItem(at: tempFileURL) }

        func checkDir(_ dir: UnsafeMutablePointer<DIR>) -> Bool {
            defer { closedir(dir) }
            var foundIt = false

            while let entry = readdir(dir) {
                var nameBytes = entry.pointee.d_name
                let name = withUnsafePointer(to: &nameBytes) {
                    String(data: Data(bytes: $0, count: Int(entry.pointee.d_namlen)), encoding: .utf8)
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

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(path: "/tmp") { acl_init(-1) }
            } == .invalidArgument
        )

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(path: FilePath("/tmp")) { acl_init(-1) }
            } == .invalidArgument
        )

        let acl: acl_t = try callPOSIXFunction(path: "/tmp") { acl_init(0) }
        defer { acl_free(UnsafeMutableRawPointer(acl)) }

        let acl2: acl_t = try callPOSIXFunction(path: FilePath("/tmp")) { acl_init(0) }
        defer { acl_free(UnsafeMutableRawPointer(acl2)) }

        var optionalACL: acl_t? = acl

        let aclEntry = try callPOSIXFunction(expect: .zero) { acl_create_entry(&optionalACL, $0) }

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(path: "/tmp") { acl_get_qualifier(aclEntry) }
            } == .invalidArgument
        )

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(path: FilePath("/tmp")) { acl_get_qualifier(aclEntry) }
            } == .invalidArgument
        )

        try callPOSIXFunction(expect: .zero) { acl_set_tag_type(aclEntry, ACL_EXTENDED_ALLOW) }

        #expect(throws: Never.self) {
            let qualifier: UnsafeMutableRawPointer? = try callPOSIXFunction(path: "/tmp") {
                acl_get_qualifier(aclEntry)
            }
            acl_free(qualifier)
        }

        #expect(throws: Never.self) {
            let qualifier: UnsafeMutableRawPointer? = try callPOSIXFunction(path: FilePath("/tmp")) {
                acl_get_qualifier(aclEntry)
            }
            acl_free(qualifier)
        }
    }

    @Test("callPOSIXFunction with .returnValue errorFrom")
    func testDirectErrorReturn() throws {
        var attr = try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) { posix_spawnattr_init($0) }
        defer {
            #expect(throws: Never.self) {
                _ = try? callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                    posix_spawnattr_destroy(&attr)
                }
            }
        }

        #expect(throws: Never.self) {
            try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) {
                posix_spawnattr_setflags(&attr, 1)
            }
        }

        #expect(
            try #require(throws: Errno.self) {
                try callPOSIXFunction(expect: .zero, errorFrom: .returnValue) { posix_spawnattr_setflags(nil, 1) }
            } == .invalidArgument
        )
    }
}

