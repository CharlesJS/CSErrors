//
//  OSStatusError+FoundationTests.swift
//  
//
//  Created by Charles Srstka on 1/16/23.
//

import CSErrors
import CSErrors_Foundation
import System
import XCTest

@available(macOS 13.0, *)
class OSStatusErrorFoundationTests: XCTestCase {
#if canImport(Darwin)
    func testCustomNSErrorConformance() throws {
        let err = try XCTUnwrap(osStatusError(OSStatus(fnfErr), description: "Hello World") as? OSStatusError)

        XCTAssertEqual(OSStatusError.errorDomain, NSOSStatusErrorDomain)
        XCTAssertEqual(err.errorCode, fnfErr)
        XCTAssertEqual(err.errorUserInfo[NSLocalizedDescriptionKey] as? String, "Hello World")
    }

    func testUserInfoWithFilePath() {
        let err = osStatusError(
            OSStatus(fnfErr),
            description: "desc",
            recoverySuggestion: "suggestion",
            recoveryOptions: ["one", "two", "three"],
            recoveryAttempter: "attempter",
            helpAnchor: "anchor",
            path: FilePath("/path/to/file"),
            underlying: Errno.noSuchFileOrDirectory,
            custom: ["foo" : "bar"]
        )

        XCTAssertEqual((err as? OSStatusError)?.rawValue, OSStatus(fnfErr))

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
            OSStatus(fnfErr),
            description: "desc",
            recoverySuggestion: "suggestion",
            recoveryOptions: ["one", "two", "three"],
            recoveryAttempter: "attempter",
            helpAnchor: "anchor",
            path: "/path/to/file",
            underlying: Errno.noSuchFileOrDirectory,
            custom: ["foo" : "bar"]
        )

        XCTAssertEqual((err as? OSStatusError)?.rawValue, OSStatus(fnfErr))

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
        let err = osStatusError(OSStatus(eofErr), stringEncoding: .windowsCP1250, url: URL(filePath: "/path/to/file"))

        XCTAssertEqual((err as? OSStatusError)?.rawValue, OSStatus(eofErr))

        let userInfo = (err as NSError).userInfo
        XCTAssertEqual(userInfo[NSStringEncodingErrorKey] as? UInt, String.Encoding.windowsCP1250.rawValue)
        XCTAssertEqual(userInfo[NSURLErrorKey] as? URL, URL(filePath: "/path/to/file"))
        XCTAssertEqual(userInfo[NSFilePathErrorKey] as? String, "/path/to/file")
    }

    func testPOSIXTranslationWithURL() {
        let err = osStatusError(OSStatus(kPOSIXErrorEAUTH), url: URL(filePath: "/path/to/file"))

        XCTAssertEqual(err as? Errno, .authenticationError)
    }

    func testErrorReason() throws {
        for code in (OSStatus(-65535)...OSStatus(0)) {
            let err = try XCTUnwrap(osStatusError(OSStatus(code)) as? OSStatusError)
            let failureReason = try XCTUnwrap(SecCopyErrorMessageString(code, nil) as String?)

            XCTAssertEqual(err.localizedDescription, failureReason)
            XCTAssertEqual(err.metadata.failureReason, failureReason)
        }

        XCTAssertEqual(osStatusError(OSStatus(unimpErr)).localizedDescription, "Function or operation not implemented.")
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

        func funcThatSucceeds() -> OSStatus { noErr }
        func funcThatFails() -> OSStatus { OSStatus(fnfErr) }
        func takesPointerAndSucceeds(_ ptr: UnsafeMutablePointer<Int>) -> OSStatus { ptr.pointee = 1; return noErr }
        func takesPointerAndFails(_: UnsafeMutablePointer<Int>) -> OSStatus { OSStatus(fnfErr) }
        func optionalPointerSucceeds(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = 2; return noErr }
        func optionalPointerFails(_: UnsafeMutablePointer<Int?>) -> OSStatus { OSStatus(fnfErr) }
        func setsPointerToNil(_ ptr: UnsafeMutablePointer<Int?>) -> OSStatus { ptr.pointee = nil; return noErr }

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
            checkError($0, code: coreFoundationUnknownErr, description: "desc", url: url)
        }
    }
#endif
}
