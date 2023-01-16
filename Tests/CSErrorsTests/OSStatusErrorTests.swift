//
//  OSStatusErrorTests.swift
//  
//
//  Created by Charles Srstka on 1/12/23.
//

import System
import XCTest
@_spi(CSErrorsInternal) @testable import CSErrors

class OSStatusErrorTests: XCTestCase {
#if canImport(Darwin)
    private struct SomeOtherError: Error {}

    private func checkOSStatusError<E: Error>(_ code: some BinaryInteger, error: E) {
        func funcThatSucceeds() -> OSStatus { noErr }
        func funcThatFails() -> OSStatus { OSStatus(code) }
        func takesPointerAndSucceeds(_ ptr: UnsafeMutablePointer<Int>) -> OSStatus { ptr.pointee = 1; return noErr }
        func takesPointerAndFails(_: UnsafeMutablePointer<Int>) -> OSStatus { OSStatus(code) }
        func optionalPointerSucceeds(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = 2; return noErr }
        func optionalPointerFails(_: UnsafeMutablePointer<Int?>) -> OSStatus { OSStatus(code) }
        func setsPointerToNil(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = nil; return noErr }

        func compareErrors(_ e1: any Error, _ e2: any Error) {
            XCTAssertTrue(type(of: e1) == type(of: e2), "\(type(of: e1)) is not same type as \(type(of: e2))")
            XCTAssertEqual(e1 as NSError, e2 as NSError)
        }

        func assertUnknownError(_ e: any Error) {
            XCTAssertTrue(e is OSStatusError)
            XCTAssertEqual((e as? OSStatusError)?.rawValue, OSStatus(coreFoundationUnknownErr))
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

        checkFNFError(fnfErr, OSStatusError(rawValue: OSStatus(fnfErr)), true)
        checkFNFError(ioErr, OSStatusError(rawValue: OSStatus(ioErr)), false)

        checkFNFError(kENOENTErr, OSStatusError(rawValue: OSStatus(kENOENTErr)), true)
        checkFNFError(kEINVALErr, OSStatusError(rawValue: OSStatus(kEINVALErr)), false)

        checkFNFError(kPOSIXErrorENOENT, Errno.noSuchFileOrDirectory, true)
        checkFNFError(kPOSIXErrorEINVAL, Errno.invalidArgument, false)

        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: fnfErr).isFileNotFoundError)
        XCTAssertFalse(GenericError(_domain: NSOSStatusErrorDomain, _code: ioErr).isFileNotFoundError)

        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kENOENTErr).isFileNotFoundError)
        XCTAssertFalse(GenericError(_domain: NSOSStatusErrorDomain, _code: kEINVALErr).isFileNotFoundError)

        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kPOSIXErrorENOENT).isFileNotFoundError)
        XCTAssertFalse(GenericError(_domain: NSOSStatusErrorDomain, _code: kPOSIXErrorEINVAL).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: fnfErr).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: ioErr).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kENOENTErr).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: kEINVALErr).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorENOENT).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorEINVAL).isFileNotFoundError)
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

        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: afpAccessDenied).isPermissionError)
        XCTAssertFalse(GenericError(_domain: NSOSStatusErrorDomain, _code: fnfErr).isPermissionError)

        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kPOSIXErrorEACCES).isPermissionError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kPOSIXErrorEPERM).isPermissionError)

        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kEACCESErr).isPermissionError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kEPERMErr).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: afpAccessDenied).isPermissionError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: fnfErr).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorEACCES).isPermissionError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorEPERM).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kEACCESErr).isPermissionError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kEPERMErr).isPermissionError)
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

        checkCancelError(userCanceledErr, OSStatusError(rawValue: OSStatus(userCanceledErr)), true)
        checkCancelError(errAEWaitCanceled, OSStatusError(rawValue: OSStatus(errAEWaitCanceled)), true)
        checkCancelError(kernelCanceledErr, OSStatusError(rawValue: OSStatus(kernelCanceledErr)), true)
        checkCancelError(kOTCanceledErr, OSStatusError(rawValue: OSStatus(kOTCanceledErr)), true)
        checkCancelError(kECANCELErr, OSStatusError(rawValue: OSStatus(kECANCELErr)), true)
        checkCancelError(errIACanceled, OSStatusError(rawValue: OSStatus(errIACanceled)), true)
        checkCancelError(kRAConnectionCanceled, OSStatusError(rawValue: OSStatus(kRAConnectionCanceled)), true)
        checkCancelError(kTXNUserCanceledOperationErr, OSStatusError(rawValue: OSStatus(kTXNUserCanceledOperationErr)), true)
        checkCancelError(kFBCindexingCanceled, OSStatusError(rawValue: OSStatus(kFBCindexingCanceled)), true)
        checkCancelError(kFBCaccessCanceled, OSStatusError(rawValue: OSStatus(kFBCaccessCanceled)), true)
        checkCancelError(kFBCsummarizationCanceled, OSStatusError(rawValue: OSStatus(kFBCsummarizationCanceled)), true)
        checkCancelError(kPOSIXErrorECANCELED, Errno.canceled, true)
        checkCancelError(badFolderDescErr, OSStatusError(rawValue: OSStatus(badFolderDescErr)), false)

        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: userCanceledErr).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: errAEWaitCanceled).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kernelCanceledErr).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kOTCanceledErr).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kECANCELErr).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: errIACanceled).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kRAConnectionCanceled).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kTXNUserCanceledOperationErr).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kFBCindexingCanceled).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kFBCaccessCanceled).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kFBCsummarizationCanceled).isCancelledError)
        XCTAssertTrue(GenericError(_domain: NSOSStatusErrorDomain, _code: kPOSIXErrorECANCELED).isCancelledError)
        XCTAssertFalse(GenericError(_domain: NSOSStatusErrorDomain, _code: badFolderDescErr).isCancelledError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: userCanceledErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: errAEWaitCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kernelCanceledErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kOTCanceledErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kECANCELErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: errIACanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kRAConnectionCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kTXNUserCanceledOperationErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kFBCindexingCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kFBCaccessCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kFBCsummarizationCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorECANCELED).isCancelledError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: badFolderDescErr).isCancelledError)
    }
#endif
}
