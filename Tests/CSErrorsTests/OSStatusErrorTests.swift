//
//  OSStatusErrorTests.swift
//
//
//  Created by Charles Srstka on 1/12/23.
//

#if canImport(Darwin)

@testable import CSErrors
import Testing

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

@Suite("OSStatusError Tests")
struct OSStatusErrorTests {
    private struct SomeOtherError: Error {}

    private func checkOSStatusError<E: Error>(_ code: some BinaryInteger, error: E) throws {
        func funcThatSucceeds() -> OSStatus { 0 }
        func funcThatFails() -> OSStatus { OSStatus(code) }
        func takesPointerAndSucceeds(_ ptr: UnsafeMutablePointer<Int>) -> OSStatus { ptr.pointee = 1; return 0 }
        func takesPointerAndFails(_: UnsafeMutablePointer<Int>) -> OSStatus { OSStatus(code) }
        func optionalPointerSucceeds(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = 2; return 0 }
        func optionalPointerFails(_: UnsafeMutablePointer<Int?>) -> OSStatus { OSStatus(code) }
        func setsPointerToNil(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = nil; return 0 }

        func compareErrors(_ e1: any Error, _ e2: any Error, description: String? = nil, path: FilePath? = nil) {
            #expect(type(of: e1) == type(of: e2), "\(type(of: e1)) is not same type as \(type(of: e2))")
            #expect((e1 as NSError).domain == (e2 as NSError).domain)
            #expect((e1 as NSError).code == (e2 as NSError).code)

            if let description, let err = e1 as? OSStatusError {
                #expect(err.metadata.description == description)
            }

            if let path, let err = e1 as? OSStatusError {
                #expect(err.metadata.path == path)

                if versionCheck(11) {
                    #expect(err.metadata.pathString == path.string)
                }
            }
        }

        func assertUnknownError(_ e: some Error, description: String? = nil, path: FilePath? = nil) {
            let unknownError = OSStatusError(rawValue: OSStatus(OSStatusError.Codes.coreFoundationUnknownErr))
            compareErrors(e, unknownError, description: description, path: path)
        }

        compareErrors(error, osStatusError(OSStatus(code)))

        #expect(throws: Never.self) { try callOSStatusAPI { funcThatSucceeds() } }
        #expect(try callOSStatusAPI { takesPointerAndSucceeds($0) } == 1)
        #expect(try callOSStatusAPI { optionalPointerSucceeds($0) } == 2)

        compareErrors(try #require(throws: E.self) { try callOSStatusAPI { funcThatFails() } }, error)
        compareErrors(try #require(throws: E.self) { try callOSStatusAPI { takesPointerAndFails($0) } }, error)
        compareErrors(try #require(throws: E.self) { try callOSStatusAPI { optionalPointerFails($0) } }, error)
        assertUnknownError(try #require(throws: OSStatusError.self) { try callOSStatusAPI { setsPointerToNil($0) } })

        #expect(throws: Never.self) { try callOSStatusAPI(errorDescription: "not used") { funcThatSucceeds() } }
        #expect(try callOSStatusAPI(errorDescription: "not used") { takesPointerAndSucceeds($0) } == 1)
        #expect(try callOSStatusAPI(errorDescription: "not used") { optionalPointerSucceeds($0) } == 2)

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(errorDescription: "some description") { funcThatFails() }
        }, error, description: "some description")

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(errorDescription: "some description") { takesPointerAndFails($0) }
        }, error, description: "some description")

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(errorDescription: "some description") { optionalPointerFails($0) }
        }, error, description: "some description")

        assertUnknownError(try #require(throws: OSStatusError.self) {
            try callOSStatusAPI(errorDescription: "some description") { setsPointerToNil($0) }
        }, description: "some description")

        #expect(throws: Never.self) { try callOSStatusAPI(path: "/bin/sh") { funcThatSucceeds() } }
        #expect(try callOSStatusAPI(path: "/bin/sh") { takesPointerAndSucceeds($0) } == 1)
        #expect(try callOSStatusAPI(path: "/bin/sh") { optionalPointerSucceeds($0) } == 2)

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(path: "/bin/sh") { funcThatFails() }
        }, error, path: "/bin/sh")

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(path: "/bin/sh") { takesPointerAndFails($0) }
        }, error, path: "/bin/sh")

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(path: "/bin/sh") { optionalPointerFails($0) }
        }, error, path: "/bin/sh")

        assertUnknownError(try #require(throws: OSStatusError.self) {
            try callOSStatusAPI(path: "/bin/sh") { setsPointerToNil($0) }
        }, path: "/bin/sh")

        #expect(throws: Never.self) { try callOSStatusAPI(path: FilePath("/bin/sh")) { funcThatSucceeds() } }
        #expect(try callOSStatusAPI(path: FilePath("/bin/sh")) { takesPointerAndSucceeds($0) } == 1)
        #expect(try callOSStatusAPI(path: FilePath("/bin/sh")) { optionalPointerSucceeds($0) } == 2)

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(path: FilePath("/bin/sh")) { funcThatFails() }
        }, error, path: "/bin/sh")

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(path: FilePath("/bin/sh")) { takesPointerAndFails($0) }
        }, error, path: "/bin/sh")

        compareErrors(try #require(throws: E.self) {
            try callOSStatusAPI(path: FilePath("/bin/sh")) { optionalPointerFails($0) }
        }, error, path: "/bin/sh")

        assertUnknownError(try #require(throws: OSStatusError.self) {
            try callOSStatusAPI(path: FilePath("/bin/sh")) { setsPointerToNil($0) }
        }, path: "/bin/sh")
    }

    @Test(".isFileNotFoundError")
    func testFileNotFound() throws {
        func checkFNFError(_ code: some BinaryInteger, _ error: some Error, _ expectTrue: Bool) throws {
            try self.checkOSStatusError(code, error: error)
            #expect(osStatusError(OSStatus(code)).isFileNotFoundError == expectTrue)
        }

        try checkFNFError(fnfErr, OSStatusError(rawValue: OSStatusError.Codes.fnfErr), true)
        try checkFNFError(ioErr, OSStatusError(rawValue: OSStatusError.Codes.ioErr), false)

        try checkFNFError(kENOENTErr, OSStatusError(rawValue: OSStatusError.Codes.kENOENTErr), true)
        try checkFNFError(kEINVALErr, OSStatusError(rawValue: OSStatusError.Codes.kEINVALErr), false)

#if Foundation
        let nsfError = CocoaError(.fileReadNoSuchFile)
#else
        let nsfError = Errno.noSuchFileOrDirectory
#endif

        try checkFNFError(kPOSIXErrorENOENT, nsfError, true)
        try checkFNFError(kPOSIXErrorEINVAL, Errno.invalidArgument, false)

        #expect(GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.fnfErr)).isFileNotFoundError)
        #expect(!GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.ioErr)).isFileNotFoundError)

        #expect(GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kENOENTErr)).isFileNotFoundError)
        #expect(
            !GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kEINVALErr)).isFileNotFoundError
        )

        #expect(
            GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + ENOENT)
            ).isFileNotFoundError
        )

        #expect(
            !GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + EINVAL)
            ).isFileNotFoundError
        )

#if Foundation
        #expect(NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.fnfErr)).isFileNotFoundError)
        #expect(!NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.ioErr)).isFileNotFoundError)

        #expect(NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.kENOENTErr)).isFileNotFoundError)
        #expect(!NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.kEINVALErr)).isFileNotFoundError)

        #expect(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + ENOENT)
            ).isFileNotFoundError
        )

        #expect(
            !NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + EINVAL)
            ).isFileNotFoundError
        )
#endif
    }

    @Test(".isPermissionError")
    func testPermissionError() throws {
        func checkPermError(_ code: some BinaryInteger, _ error: some Error, _ expectTrue: Bool) throws {
            try self.checkOSStatusError(code, error: error)
            #expect(osStatusError(OSStatus(code)).isPermissionError == expectTrue)
        }

        try checkPermError(afpAccessDenied, OSStatusError(rawValue: OSStatus(afpAccessDenied)), true)
        try checkPermError(fnfErr, OSStatusError(rawValue: OSStatus(fnfErr)), false)

#if Foundation
        let eaccesError = CocoaError(.fileReadNoPermission)
        let epermError = CocoaError(.fileReadNoPermission)
#else
        let eaccesError = Errno.permissionDenied
        let epermError = Errno.notPermitted
#endif

        try checkPermError(kPOSIXErrorEACCES, eaccesError, true)
        try checkPermError(kPOSIXErrorEPERM, epermError, true)

        try checkPermError(kEACCESErr, OSStatusError(rawValue: OSStatus(kEACCESErr)), true)
        try checkPermError(kEPERMErr, OSStatusError(rawValue: OSStatus(kEPERMErr)), true)

        #expect(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.afpAccessDenied))
                .isPermissionError
        )

        #expect(
            !GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.fnfErr))
                .isPermissionError
        )

        #expect(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kPOSIXErrorBase + EACCES))
                .isPermissionError
        )

        #expect(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kPOSIXErrorBase + EPERM))
                .isPermissionError
        )

        #expect(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kEACCESErr)).isPermissionError
        )

        #expect(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kEPERMErr)).isPermissionError
        )

#if Foundation
        #expect(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.afpAccessDenied)).isPermissionError
        )

        #expect(
            !NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.fnfErr)).isPermissionError
        )

        #expect(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + EACCES)
            ).isPermissionError
        )

        #expect(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + EPERM)
            ).isPermissionError
        )

        #expect(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.kEACCESErr)).isPermissionError
        )

        #expect(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.kEPERMErr)).isPermissionError
        )
#endif
    }

    @Test("isCancelledError")
    func testCancelledError() throws {
        func checkCancelError(_ code: some BinaryInteger, _ error: some Error, _ expectTrue: Bool) throws {
            try self.checkOSStatusError(code, error: error)
            #expect(osStatusError(OSStatus(code)).isCancelledError == expectTrue)
        }

        for code in [
            OSStatusError.Codes.userCanceledErr,
            OSStatusError.Codes.errAEWaitCanceled,
            OSStatusError.Codes.kernelCanceledErr,
            OSStatusError.Codes.kOTCanceledErr,
            OSStatusError.Codes.kECANCELErr,
            OSStatusError.Codes.errIACanceled,
            OSStatusError.Codes.kRAConnectionCanceled,
            OSStatusError.Codes.kTXNUserCanceledOperationErr,
            OSStatusError.Codes.kFBCindexingCanceled,
            OSStatusError.Codes.kFBCaccessCanceled,
            OSStatusError.Codes.kFBCsummarizationCanceled
        ] {
            try checkCancelError(code, OSStatusError(rawValue: code), true)
            #expect(GenericError(_domain: NSOSStatusErrorDomain, _code: Int(code)).isCancelledError)
#if Foundation
            #expect(NSError(domain: NSOSStatusErrorDomain, code: Int(code)).isCancelledError)
#endif
        }

#if Foundation
        let cancelError = CocoaError(.userCancelled)
#else
        let cancelError = Errno.canceled
#endif

        try checkCancelError(OSStatusError.Codes.kPOSIXErrorBase + ECANCELED, cancelError, true)
        try checkCancelError(OSStatusError.Codes.ioErr, OSStatusError(rawValue: OSStatus(OSStatusError.Codes.ioErr)), false)

        #expect(
            GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + ECANCELED)
            ).isCancelledError
        )

#if Foundation
        #expect(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + ECANCELED)
            ).isCancelledError
        )
#endif

        #expect(!GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.ioErr)).isCancelledError)
    }

#if Foundation
    @Test("Custom NSError Conformance")
    func testCustomNSErrorConformance() throws {
        let err = try #require(osStatusError(OSStatusError.Codes.fnfErr, description: "Hello World") as? OSStatusError)

        #expect(OSStatusError.errorDomain == NSOSStatusErrorDomain)
        #expect(err.errorCode == fnfErr)
        #expect(err.errorUserInfo[NSLocalizedDescriptionKey] as? String == "Hello World")
    }

    @Test("User Info with FilePath")
    func testUserInfoWithFilePath() {
        let err = osStatusError(
            OSStatusError.Codes.fnfErr,
            description: "desc",
            recoverySuggestion: "suggestion",
            recoveryOptions: ["one", "two", "three"],
            recoveryAttempter: "attempter",
            helpAnchor: "anchor",
            path: FilePath("/path/to/file"),
            underlying: Errno.noSuchFileOrDirectory,
            custom: ["foo" : "bar"]
        )

        #expect((err as? OSStatusError)?.rawValue == OSStatusError.Codes.fnfErr)

        let userInfo = (err as NSError).userInfo
        #expect(userInfo[NSLocalizedDescriptionKey] as? String == "desc")
        #expect(userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String == "suggestion")
        #expect(userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String] == ["one", "two", "three"])
        #expect(userInfo[NSRecoveryAttempterErrorKey] as? String == "attempter")
        #expect(userInfo[NSHelpAnchorErrorKey] as? String == "anchor")
        #expect(userInfo[NSFilePathErrorKey] as? String == "/path/to/file")
        #expect(userInfo[NSUnderlyingErrorKey] as? Errno == .noSuchFileOrDirectory)
        #expect(userInfo["foo"] as? String == "bar")
    }

    @Test("User Info with String path")
    func testUserInfoWithStringPath() {
        let err = osStatusError(
            OSStatusError.Codes.fnfErr,
            description: "desc",
            recoverySuggestion: "suggestion",
            recoveryOptions: ["one", "two", "three"],
            recoveryAttempter: "attempter",
            helpAnchor: "anchor",
            path: "/path/to/file",
            underlying: Errno.noSuchFileOrDirectory,
            custom: ["foo" : "bar"]
        )

        #expect((err as? OSStatusError)?.rawValue == OSStatusError.Codes.fnfErr)

        let userInfo = (err as NSError).userInfo
        #expect(userInfo[NSLocalizedDescriptionKey] as? String == "desc")
        #expect(userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String == "suggestion")
        #expect(userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String] == ["one", "two", "three"])
        #expect(userInfo[NSRecoveryAttempterErrorKey] as? String == "attempter")
        #expect(userInfo[NSHelpAnchorErrorKey] as? String == "anchor")
        #expect(userInfo[NSFilePathErrorKey] as? String == "/path/to/file")
        #expect(userInfo[NSUnderlyingErrorKey] as? Errno == .noSuchFileOrDirectory)
        #expect(userInfo["foo"] as? String == "bar")
    }

    @Test("User Info with URL and StringEncoding")
    func testUserInfoWithURLAndStringEncoding() {
        let err = osStatusError(
            OSStatusError.Codes.eofErr,
            stringEncoding: .windowsCP1250,
            url: URL(filePath: "/path/to/file")
        )

        #expect((err as? OSStatusError)?.rawValue == OSStatusError.Codes.eofErr)

        let userInfo = (err as NSError).userInfo

#if Foundation && canImport(Darwin)
        #expect((userInfo[NSStringEncodingErrorKey] as? UInt) == String.Encoding.windowsCP1250.rawValue)
#endif

        #expect((userInfo[NSStringEncodingErrorKeyNonDarwin] as? Int) == Int(String.Encoding.windowsCP1250.rawValue))

        #expect(userInfo[NSURLErrorKey] as? URL == URL(filePath: "/path/to/file"))
        #expect(userInfo[NSFilePathErrorKey] as? String == "/path/to/file")
    }

    @Test("POSIX Translation with URL")
    func testPOSIXTranslationWithURL() {
        let err = osStatusError(OSStatusError.Codes.kPOSIXErrorBase + EAUTH, url: URL(filePath: "/path/to/file"))

        #expect(err as? Errno == .authenticationError)
    }

    @Test("Error reasons")
    func testErrorReason() throws {
        for code in (OSStatus(-65535)...OSStatus(0)) {
            let err = try #require(osStatusError(OSStatus(code)) as? OSStatusError)
            let failureReason = try #require(SecCopyErrorMessageString(code, nil) as String?)

            #expect(err.localizedDescription == failureReason)
            #expect(err.metadata.failureReason == failureReason)
        }

        #expect(osStatusError(OSStatusError.Codes.unimpErr).localizedDescription == "Function or operation not implemented.")

        #expect(
            osStatusError(OSStatus(errSecDataTooLarge)).localizedDescription ==
            "This item contains information which is too large or in a format that cannot be displayed."
        )
    }

    @Test("Call API with URL")
    func testCallAPIWithURL() throws {
        func checkError(_ err: (some Error)?, code: some BinaryInteger, description: String, url: URL) {
            #expect((err as? OSStatusError)?.rawValue == OSStatus(code))

            let userInfo = (err as NSError?)?.userInfo
            #expect(userInfo?[NSLocalizedDescriptionKey] as? String == description)
            #expect(userInfo?[NSURLErrorKey] as? URL == url)
            #expect(userInfo?[NSFilePathErrorKey] as? String == url.path)
        }

        func funcThatSucceeds() -> OSStatus { 0 }
        func funcThatFails() -> OSStatus { OSStatusError.Codes.fnfErr }
        func takesPointerAndSucceeds(_ ptr: UnsafeMutablePointer<Int>) -> OSStatus { ptr.pointee = 1; return 0 }
        func takesPointerAndFails(_: UnsafeMutablePointer<Int>) -> OSStatus { OSStatusError.Codes.fnfErr }
        func optionalPointerSucceeds(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = 2; return 0 }
        func optionalPointerFails(_: UnsafeMutablePointer<Int?>) -> OSStatus { OSStatusError.Codes.fnfErr }
        func setsPointerToNil(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = nil; return 0 }

        let url = URL(filePath: "/path/to/file")

        #expect(throws: Never.self) { try callOSStatusAPI(errorDescription: "desc", url: url) { funcThatSucceeds() } }
        checkError(
            try #require(throws: OSStatusError.self) {
                try callOSStatusAPI(errorDescription: "desc", url: url) { funcThatFails() }
            },
            code: fnfErr,
            description: "desc",
            url: url
        )

        #expect(throws: Never.self) { try callOSStatusAPI(errorDescription: "desc", url: url) { funcThatSucceeds() } }
        checkError(
            try #require(throws: OSStatusError.self) {
                try callOSStatusAPI(errorDescription: "desc", url: url) { funcThatFails() }
            },
            code: fnfErr,
            description: "desc",
            url: url
        )

        #expect(try callOSStatusAPI(errorDescription: "desc", url: url) { takesPointerAndSucceeds($0) } == 1)
        checkError(
            try #require(throws: OSStatusError.self) {
                try callOSStatusAPI(errorDescription: "desc", url: url) { takesPointerAndFails($0) }
            },
            code: fnfErr,
            description: "desc",
            url: url
        )

        #expect(try callOSStatusAPI(errorDescription: "desc", url: url) { optionalPointerSucceeds($0) } as Int == 2)
        checkError(
            try #require(throws: OSStatusError.self) {
                try callOSStatusAPI(errorDescription: "desc", url: url) { optionalPointerFails($0) }
            },
            code: fnfErr,
            description: "desc",
            url: url
        )
        checkError(
            try #require(throws: OSStatusError.self) {
                try callOSStatusAPI(errorDescription: "desc", url: url) { setsPointerToNil($0) }
            },
            code: OSStatusError.Codes.coreFoundationUnknownErr,
            description: "desc",
            url: url
        )
    }
#endif
}
#endif
