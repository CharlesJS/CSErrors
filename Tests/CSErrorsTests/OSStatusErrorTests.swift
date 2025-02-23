//
//  OSStatusErrorTests.swift
//  
//
//  Created by Charles Srstka on 1/12/23.
//

import System
import XCTest
@testable import CSErrors

class OSStatusErrorTests: XCTestCase {
#if canImport(Darwin)
    private struct SomeOtherError: Error {}

    private func checkOSStatusError<E: Error>(_ code: some BinaryInteger, error: E) {
        func funcThatSucceeds() -> OSStatus { 0 }
        func funcThatFails() -> OSStatus { OSStatus(code) }
        func takesPointerAndSucceeds(_ ptr: UnsafeMutablePointer<Int>) -> OSStatus { ptr.pointee = 1; return 0 }
        func takesPointerAndFails(_: UnsafeMutablePointer<Int>) -> OSStatus { OSStatus(code) }
        func optionalPointerSucceeds(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = 2; return 0 }
        func optionalPointerFails(_: UnsafeMutablePointer<Int?>) -> OSStatus { OSStatus(code) }
        func setsPointerToNil(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = nil; return 0 }

        func compareErrors(_ e1: any Error, _ e2: any Error) {
            XCTAssertTrue(type(of: e1) == type(of: e2), "\(type(of: e1)) is not same type as \(type(of: e2))")
            XCTAssertEqual((e1 as NSError).domain, (e2 as NSError).domain)
            XCTAssertEqual((e1 as NSError).code, (e2 as NSError).code)
        }

        func assertUnknownError(_ e: any Error) {
            XCTAssertTrue(e is OSStatusError)
            XCTAssertEqual((e as? OSStatusError)?.rawValue, OSStatus(OSStatusError.Codes.coreFoundationUnknownErr))
        }

        compareErrors(error, osStatusError(OSStatus(code)))

        XCTAssertNoThrow(try callOSStatusAPI { funcThatSucceeds() })
        XCTAssertEqual(try? callOSStatusAPI { takesPointerAndSucceeds($0) }, 1)
        XCTAssertEqual(try? callOSStatusAPI { optionalPointerSucceeds($0) }, 2)

        XCTAssertThrowsError(try callOSStatusAPI { funcThatFails() }) { compareErrors(error, $0) }
        XCTAssertThrowsError(try callOSStatusAPI { takesPointerAndFails($0) }) { compareErrors(error, $0) }
        XCTAssertThrowsError(try callOSStatusAPI { optionalPointerFails($0) }) { compareErrors(error, $0) }
        XCTAssertThrowsError(try callOSStatusAPI { setsPointerToNil($0) }) { assertUnknownError($0) }

        XCTAssertNoThrow(try callOSStatusAPI(errorDescription: "not used") { funcThatSucceeds() })
        XCTAssertEqual(try? callOSStatusAPI(errorDescription: "not used") { takesPointerAndSucceeds($0) }, 1)
        XCTAssertEqual(try? callOSStatusAPI(errorDescription: "not used") { optionalPointerSucceeds($0) }, 2)

        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "some description") { funcThatFails() }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.description, "some description")
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "some description") { takesPointerAndFails($0) }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.description, "some description")
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "some description") { optionalPointerFails($0) }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.description, "some description")
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "some description") { setsPointerToNil($0) }) {
            assertUnknownError($0)
            XCTAssertEqual(($0 as? OSStatusError)?.metadata.description, "some description")
        }

        XCTAssertNoThrow(try callOSStatusAPI(path: "/bin/sh") { funcThatSucceeds() })
        XCTAssertEqual(try? callOSStatusAPI(path: "/bin/sh") { takesPointerAndSucceeds($0) }, 1)
        XCTAssertEqual(try? callOSStatusAPI(path: "/bin/sh") { optionalPointerSucceeds($0) }, 2)

        XCTAssertThrowsError(try callOSStatusAPI(path: "/bin/sh") { funcThatFails() }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.pathString, "/bin/sh")
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(path: "/bin/sh") { takesPointerAndFails($0) }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.pathString, "/bin/sh")
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(path: "/bin/sh") { optionalPointerFails($0) }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.pathString, "/bin/sh")
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(path: "/bin/sh") { setsPointerToNil($0) }) {
            assertUnknownError($0)
            XCTAssertEqual(($0 as? OSStatusError)?.metadata.pathString, "/bin/sh")
        }

        XCTAssertNoThrow(try callOSStatusAPI(path: FilePath("/bin/sh")) { funcThatSucceeds() })
        XCTAssertEqual(try? callOSStatusAPI(path: FilePath("/bin/sh")) { takesPointerAndSucceeds($0) }, 1)
        XCTAssertEqual(try? callOSStatusAPI(path: FilePath("/bin/sh")) { optionalPointerSucceeds($0) }, 2)

        XCTAssertThrowsError(try callOSStatusAPI(path: FilePath("/bin/sh")) { funcThatFails() }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.path, FilePath("/bin/sh"))
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(path: FilePath("/bin/sh")) { takesPointerAndFails($0) }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.path, FilePath("/bin/sh"))
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(path: FilePath("/bin/sh")) { optionalPointerFails($0) }) {
            compareErrors(error, $0)

            if E.self == OSStatusError.self {
                XCTAssertEqual(($0 as? OSStatusError)?.metadata.path, FilePath("/bin/sh"))
            }
        }

        XCTAssertThrowsError(try callOSStatusAPI(path: FilePath("/bin/sh")) { setsPointerToNil($0) }) {
            assertUnknownError($0)
            XCTAssertEqual(($0 as? OSStatusError)?.metadata.pathString, "/bin/sh")
        }

        var failedTypeCheck = false
        var failedEqualityCheck = false
        let failureOptions = XCTExpectedFailure.Options()
        failureOptions.issueMatcher = { issue in
            var matched = false

            if issue.type == .assertionFailure, issue.associatedError == nil {
                if issue.description.contains("\(type(of: error)) is not same type as SomeOtherError") {
                    failedTypeCheck = true
                    matched = true
                } else if issue.description.contains(" is not equal to ") {
                    failedEqualityCheck = true
                    matched = true
                }
            }
            return matched
        }

        XCTExpectFailure(options: failureOptions) { compareErrors(error, SomeOtherError()) }
        XCTAssertTrue(failedTypeCheck)
        XCTAssertTrue(failedEqualityCheck)
    }

    func testFileNotFound() {
        func checkFNFError(_ code: some BinaryInteger, _ error: some Error, _ expectTrue: Bool) {
            self.checkOSStatusError(code, error: error)
            if expectTrue {
                XCTAssertTrue(osStatusError(OSStatus(code)).isFileNotFoundError)
            } else {
                XCTAssertFalse(osStatusError(OSStatus(code)).isFileNotFoundError)
            }
        }

        checkFNFError(fnfErr, OSStatusError(rawValue: OSStatusError.Codes.fnfErr), true)
        checkFNFError(ioErr, OSStatusError(rawValue: OSStatusError.Codes.ioErr), false)

        checkFNFError(kENOENTErr, OSStatusError(rawValue: OSStatusError.Codes.kENOENTErr), true)
        checkFNFError(kEINVALErr, OSStatusError(rawValue: OSStatusError.Codes.kEINVALErr), false)

#if Foundation
        let nsfError = CocoaError(.fileReadNoSuchFile)
#else
        let nsfError = Errno.noSuchFileOrDirectory
#endif

        checkFNFError(kPOSIXErrorENOENT, nsfError, true)
        checkFNFError(kPOSIXErrorEINVAL, Errno.invalidArgument, false)

        XCTAssertTrue(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.fnfErr)).isFileNotFoundError
        )

        XCTAssertFalse(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.ioErr)).isFileNotFoundError
        )

        XCTAssertTrue(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kENOENTErr)).isFileNotFoundError
        )

        XCTAssertFalse(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kEINVALErr)).isFileNotFoundError
        )

        XCTAssertTrue(
            GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + ENOENT)
            ).isFileNotFoundError
        )

        XCTAssertFalse(
            GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + EINVAL)
            ).isFileNotFoundError
        )

#if Foundation
        XCTAssertTrue(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.fnfErr)).isFileNotFoundError
        )

        XCTAssertFalse(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.ioErr)).isFileNotFoundError
        )

        XCTAssertTrue(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.kENOENTErr)).isFileNotFoundError
        )

        XCTAssertFalse(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.kEINVALErr)).isFileNotFoundError
        )

        XCTAssertTrue(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + ENOENT)
            ).isFileNotFoundError
        )

        XCTAssertFalse(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + EINVAL)
            ).isFileNotFoundError
        )
#endif
    }

    func testPermissionError() {
        func checkPermError(_ code: some BinaryInteger, _ error: some Error, _ expectTrue: Bool) {
            self.checkOSStatusError(code, error: error)
            if expectTrue {
                XCTAssertTrue(osStatusError(OSStatus(code)).isPermissionError)
            } else {
                XCTAssertFalse(osStatusError(OSStatus(code)).isPermissionError)
            }
        }

        checkPermError(afpAccessDenied, OSStatusError(rawValue: OSStatus(afpAccessDenied)), true)
        checkPermError(fnfErr, OSStatusError(rawValue: OSStatus(fnfErr)), false)

#if Foundation
        let eaccesError = CocoaError(.fileReadNoPermission)
        let epermError = CocoaError(.fileReadNoPermission)
#else
        let eaccesError = Errno.permissionDenied
        let epermError = Errno.notPermitted
#endif

        checkPermError(kPOSIXErrorEACCES, eaccesError, true)
        checkPermError(kPOSIXErrorEPERM, epermError, true)

        checkPermError(kEACCESErr, OSStatusError(rawValue: OSStatus(kEACCESErr)), true)
        checkPermError(kEPERMErr, OSStatusError(rawValue: OSStatus(kEPERMErr)), true)

        XCTAssertTrue(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.afpAccessDenied)).isPermissionError
        )

        XCTAssertFalse(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.fnfErr)).isPermissionError
        )

        XCTAssertTrue(
            GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + EACCES)
            ).isPermissionError
        )

        XCTAssertTrue(
            GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + EPERM)
            ).isPermissionError
        )

        XCTAssertTrue(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kEACCESErr)).isPermissionError
        )

        XCTAssertTrue(
            GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.kEPERMErr)).isPermissionError
        )

#if Foundation
        XCTAssertTrue(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.afpAccessDenied)).isPermissionError
        )

        XCTAssertFalse(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.fnfErr)).isPermissionError
        )

        XCTAssertTrue(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + EACCES)
            ).isPermissionError
        )

        XCTAssertTrue(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + EPERM)
            ).isPermissionError
        )

        XCTAssertTrue(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.kEACCESErr)).isPermissionError
        )

        XCTAssertTrue(
            NSError(domain: NSOSStatusErrorDomain, code: Int(OSStatusError.Codes.kEPERMErr)).isPermissionError
        )
#endif
    }

    func testCancelledError() {
        func checkCancelError(_ code: some BinaryInteger, _ error: some Error, _ expectTrue: Bool) {
            self.checkOSStatusError(code, error: error)
            if expectTrue {
                XCTAssertTrue(osStatusError(OSStatus(code)).isCancelledError)
            } else {
                XCTAssertFalse(osStatusError(OSStatus(code)).isCancelledError)
            }
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
            checkCancelError(code, OSStatusError(rawValue: code), true)
            XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: Int(code)).isCancelledError)
#if Foundation
            XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: Int(code)).isCancelledError)
#endif
        }

#if Foundation
        let cancelError = CocoaError(.userCancelled)
#else
        let cancelError = Errno.canceled
#endif

        checkCancelError(OSStatusError.Codes.kPOSIXErrorBase + ECANCELED, cancelError, true)
        checkCancelError(OSStatusError.Codes.ioErr, OSStatusError(rawValue: OSStatus(OSStatusError.Codes.ioErr)), false)

        XCTAssertTrue(
            GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + ECANCELED)
            ).isCancelledError
        )

#if Foundation
        XCTAssertTrue(
            NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(OSStatusError.Codes.kPOSIXErrorBase + ECANCELED)
            ).isCancelledError
        )
#endif

        XCTAssertFalse(GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.ioErr)).isCancelledError)
    }

#if Foundation

    func testCustomNSErrorConformance() throws {
        let err = try XCTUnwrap(osStatusError(OSStatusError.Codes.fnfErr, description: "Hello World") as? OSStatusError)

        XCTAssertEqual(OSStatusError.errorDomain, NSOSStatusErrorDomain)
        XCTAssertEqual(err.errorCode, fnfErr)
        XCTAssertEqual(err.errorUserInfo[NSLocalizedDescriptionKey] as? String, "Hello World")
    }

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

        XCTAssertEqual((err as? OSStatusError)?.rawValue, OSStatusError.Codes.fnfErr)

        let userInfo = (err as NSError).userInfo
        XCTAssertEqual(userInfo[NSLocalizedDescriptionKey] as? String, "desc")
        XCTAssertEqual(userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String, "suggestion")
        XCTAssertEqual(userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String], ["one", "two", "three"])
        XCTAssertEqual(userInfo[NSRecoveryAttempterErrorKey] as? String, "attempter")
        XCTAssertEqual(userInfo[NSHelpAnchorErrorKey] as? String, "anchor")
        XCTAssertEqual(userInfo[NSFilePathErrorKey] as? String, "/path/to/file")
        XCTAssertEqual(userInfo[NSUnderlyingErrorKey] as? Errno, .noSuchFileOrDirectory)
        XCTAssertEqual(userInfo["foo"] as? String, "bar")
    }

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

        XCTAssertEqual((err as? OSStatusError)?.rawValue, OSStatusError.Codes.fnfErr)

        let userInfo = (err as NSError).userInfo
        XCTAssertEqual(userInfo[NSLocalizedDescriptionKey] as? String, "desc")
        XCTAssertEqual(userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String, "suggestion")
        XCTAssertEqual(userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String], ["one", "two", "three"])
        XCTAssertEqual(userInfo[NSRecoveryAttempterErrorKey] as? String, "attempter")
        XCTAssertEqual(userInfo[NSHelpAnchorErrorKey] as? String, "anchor")
        XCTAssertEqual(userInfo[NSFilePathErrorKey] as? String, "/path/to/file")
        XCTAssertEqual(userInfo[NSUnderlyingErrorKey] as? Errno, .noSuchFileOrDirectory)
        XCTAssertEqual(userInfo["foo"] as? String, "bar")
    }

    func testUserInfoWithURLAndStringEncoding() {
        let err = osStatusError(
            OSStatusError.Codes.eofErr,
            stringEncoding: .windowsCP1250,
            url: URL(filePath: "/path/to/file")
        )

        XCTAssertEqual((err as? OSStatusError)?.rawValue, OSStatusError.Codes.eofErr)

        let userInfo = (err as NSError).userInfo
        XCTAssertEqual(userInfo[NSStringEncodingErrorKey] as? UInt, String.Encoding.windowsCP1250.rawValue)
        XCTAssertEqual(userInfo[NSURLErrorKey] as? URL, URL(filePath: "/path/to/file"))
        XCTAssertEqual(userInfo[NSFilePathErrorKey] as? String, "/path/to/file")
    }

    func testPOSIXTranslationWithURL() {
        let err = osStatusError(OSStatusError.Codes.kPOSIXErrorBase + EAUTH, url: URL(filePath: "/path/to/file"))

        XCTAssertEqual(err as? Errno, .authenticationError)
    }

    func testErrorReason() throws {
        for code in (OSStatus(-65535)...OSStatus(0)) {
            let err = try XCTUnwrap(osStatusError(OSStatus(code)) as? OSStatusError)
            let failureReason = try XCTUnwrap(SecCopyErrorMessageString(code, nil) as String?)

            XCTAssertEqual(err.localizedDescription, failureReason)
            XCTAssertEqual(err.metadata.failureReason, failureReason)
        }

        XCTAssertEqual(
            osStatusError(OSStatusError.Codes.unimpErr).localizedDescription,
            "Function or operation not implemented."
        )

        XCTAssertEqual(
            osStatusError(OSStatus(errSecDataTooLarge)).localizedDescription,
            "This item contains information which is too large or in a format that cannot be displayed."
        )
    }

    func testCallAPIWithURL() {
        func checkError(_ err: some Error, code: some BinaryInteger, description: String, url: URL) {
            XCTAssertEqual((err as? OSStatusError)?.rawValue, OSStatus(code))

            let userInfo = (err as NSError).userInfo
            XCTAssertEqual(userInfo[NSLocalizedDescriptionKey] as? String, description)
            XCTAssertEqual(userInfo[NSURLErrorKey] as? URL, url)
            XCTAssertEqual(userInfo[NSFilePathErrorKey] as? String, url.path)
        }

        func funcThatSucceeds() -> OSStatus { 0 }
        func funcThatFails() -> OSStatus { OSStatusError.Codes.fnfErr }
        func takesPointerAndSucceeds(_ ptr: UnsafeMutablePointer<Int>) -> OSStatus { ptr.pointee = 1; return 0 }
        func takesPointerAndFails(_: UnsafeMutablePointer<Int>) -> OSStatus { OSStatusError.Codes.fnfErr }
        func optionalPointerSucceeds(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = 2; return 0 }
        func optionalPointerFails(_: UnsafeMutablePointer<Int?>) -> OSStatus { OSStatusError.Codes.fnfErr }
        func setsPointerToNil(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = nil; return 0 }

        let url = URL(filePath: "/path/to/file")

        XCTAssertNoThrow(try callOSStatusAPI(errorDescription: "desc", url: url) { funcThatSucceeds() })
        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "desc", url: url) { funcThatFails() }) {
            checkError($0, code: fnfErr, description: "desc", url: url)
        }

        XCTAssertNoThrow(try callOSStatusAPI(errorDescription: "desc", url: url) { funcThatSucceeds() })
        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "desc", url: url) { funcThatFails() }) {
            checkError($0, code: fnfErr, description: "desc", url: url)
        }

        XCTAssertEqual(try? callOSStatusAPI(errorDescription: "desc", url: url) { takesPointerAndSucceeds($0) }, 1)
        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "desc", url: url) { takesPointerAndFails($0) }) {
            checkError($0, code: fnfErr, description: "desc", url: url)
        }

        XCTAssertEqual(try? callOSStatusAPI(errorDescription: "desc", url: url) { optionalPointerSucceeds($0) } as Int, 2)
        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "desc", url: url) { optionalPointerFails($0) }) {
            checkError($0, code: fnfErr, description: "desc", url: url)
        }
        XCTAssertThrowsError(try callOSStatusAPI(errorDescription: "desc", url: url) { setsPointerToNil($0) }) {
            checkError($0, code: OSStatusError.Codes.coreFoundationUnknownErr, description: "desc", url: url)
        }
    }

#endif

#endif
}
