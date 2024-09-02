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
            XCTAssertEqual(e1 as NSError, e2 as NSError)
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
                if !failedTypeCheck, issue.description.contains("\(type(of: error)) is not same type as SomeOtherError") {
                    failedTypeCheck = true
                    matched = true
                } else if !failedEqualityCheck, issue.description.contains(" is not equal to ") {
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

        checkFNFError(kPOSIXErrorENOENT, Errno.noSuchFileOrDirectory, true)
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

        checkPermError(kPOSIXErrorEACCES, Errno.permissionDenied, true)
        checkPermError(kPOSIXErrorEPERM, Errno.notPermitted, true)

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
        }

        checkCancelError(OSStatusError.Codes.kPOSIXErrorBase + ECANCELED, Errno.canceled, true)
        checkCancelError(OSStatusError.Codes.ioErr, OSStatusError(rawValue: OSStatus(OSStatusError.Codes.ioErr)), false)

        XCTAssertTrue(
            GenericError(
                _domain: NSOSStatusErrorDomain,
                _code: Int(OSStatusError.Codes.kPOSIXErrorBase + ECANCELED)
            ).isCancelledError
        )

        XCTAssertFalse(GenericError(_domain: NSOSStatusErrorDomain, _code: Int(OSStatusError.Codes.ioErr)).isCancelledError)
    }
#endif
}
