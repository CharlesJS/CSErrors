//
//  ErrorMetadataTests.swift
//  
//
//  Created by Charles Srstka on 1/16/23.
//

@testable import CSErrors
import CSErrors_Foundation
import System
import XCTest

@available(macOS 13.0, *)
class ErrorMetadataTests: XCTestCase {
    private struct WhatYouSay: Error {
        let description: String
        let additionalDescription: String
    }

    func testEmptyProperties() {
        let metadata = ErrorMetadata()

        XCTAssertNil(metadata.description)
        XCTAssertNil(metadata.failureReason)
        XCTAssertNil(metadata.recoverySuggestion)
        XCTAssertNil(metadata.recoveryOptions)
        XCTAssertNil(metadata.recoveryAttempter)
        XCTAssertNil(metadata.helpAnchor)
        XCTAssertNil(metadata.path)
        XCTAssertNil(metadata.pathString)
        XCTAssertNil(metadata.url)
        XCTAssertNil(metadata.stringEncoding)
        XCTAssertNil(metadata.underlying)
        XCTAssertNil(metadata.custom)
        XCTAssertEqual(metadata.toUserInfo().count, 0)
    }

    private func checkMetadata(_ metadata: ErrorMetadata) {
        let userInfo = metadata.toUserInfo()

        XCTAssertEqual(userInfo[NSLocalizedDescriptionKey] as? String, "In AD 2101, war was beginning.")
        XCTAssertEqual(userInfo[NSLocalizedFailureReasonErrorKey] as? String, "What happen? Somebody set up us the bomb.")
        XCTAssertEqual(userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String, "We get signal.")
        XCTAssertEqual(userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String], [
            "What!",
            "Main screen turn on.",
            "It's You!"
        ])
        XCTAssertEqual(userInfo[NSRecoveryAttempterErrorKey] as? String, "How are you gentlemen!")
        XCTAssertEqual(userInfo[NSHelpAnchorErrorKey] as? String, "All your base are belong to us.")
        XCTAssertEqual(userInfo[NSFilePathErrorKey] as? String, "/you/are/on/the/way/to/destruction")
        XCTAssertEqual(userInfo[NSURLErrorKey] as? URL, URL(filePath: "/you/are/on/the/way/to/destruction"))
        XCTAssertEqual(metadata.path, FilePath("/you/are/on/the/way/to/destruction"))
        XCTAssertEqual(metadata.pathString, "/you/are/on/the/way/to/destruction")
        XCTAssertEqual(metadata.url, URL(filePath: "/you/are/on/the/way/to/destruction"))

        let underlying = userInfo[NSUnderlyingErrorKey] as? WhatYouSay
        XCTAssertEqual(underlying?.description, "You have no chance to survive make your time.")
        XCTAssertEqual(underlying?.additionalDescription, "Ha ha ha ha ha...")

        XCTAssertEqual(userInfo["Take off"] as? String, "every Zig")
        XCTAssertEqual(userInfo["You know"] as? String, "what you doing")
        XCTAssertEqual(userInfo["Move Zig"] as? String, "for great justice.")
    }

    func testInitializeWithStringPath() {
        let metadata = ErrorMetadata(
            description: "In AD 2101, war was beginning.",
            failureReason: "What happen? Somebody set up us the bomb.",
            recoverySuggestion: "We get signal.",
            recoveryOptions: ["What!", "Main screen turn on.", "It's You!"],
            recoveryAttempter: "How are you gentlemen!",
            helpAnchor: "All your base are belong to us.",
            path: "/you/are/on/the/way/to/destruction",
            underlying: WhatYouSay(
                description: "You have no chance to survive make your time.",
                additionalDescription: "Ha ha ha ha ha..."
            ),
            custom: [
                "Take off": "every Zig",
                "You know": "what you doing",
                "Move Zig": "for great justice."
            ]
        )

        self.checkMetadata(metadata)
    }

    func testInitializeWithFilePath() {
        let metadata = ErrorMetadata(
            description: "In AD 2101, war was beginning.",
            failureReason: "What happen? Somebody set up us the bomb.",
            recoverySuggestion: "We get signal.",
            recoveryOptions: ["What!", "Main screen turn on.", "It's You!"],
            recoveryAttempter: "How are you gentlemen!",
            helpAnchor: "All your base are belong to us.",
            path: FilePath("/you/are/on/the/way/to/destruction"),
            underlying: WhatYouSay(
                description: "You have no chance to survive make your time.",
                additionalDescription: "Ha ha ha ha ha..."
            ),
            custom: [
                "Take off": "every Zig",
                "You know": "what you doing",
                "Move Zig": "for great justice."
            ]
        )

        self.checkMetadata(metadata)
    }

    func testInitializeWithURL() {
        let metadata = ErrorMetadata(
            description: "In AD 2101, war was beginning.",
            failureReason: "What happen? Somebody set up us the bomb.",
            recoverySuggestion: "We get signal.",
            recoveryOptions: ["What!", "Main screen turn on.", "It's You!"],
            recoveryAttempter: "How are you gentlemen!",
            helpAnchor: "All your base are belong to us.",
            url: URL(filePath: "/you/are/on/the/way/to/destruction"),
            underlying: WhatYouSay(
                description: "You have no chance to survive make your time.",
                additionalDescription: "Ha ha ha ha ha..."
            ),
            custom: [
                "Take off": "every Zig",
                "You know": "what you doing",
                "Move Zig": "for great justice."
            ]
        )

        self.checkMetadata(metadata)
    }

    func testFailureReasonWithoutDescription() {
        let metadata = ErrorMetadata(failureReason: "I just don't wanna")

        XCTAssertEqual(metadata.toUserInfo()[NSLocalizedDescriptionKey] as? String, "I just don't wanna")
    }

    func testErrorWithStringEncoding() {
        let metadata = ErrorMetadata(description: "Et Tu Brute", stringEncoding: .isoLatin1)

        XCTAssertEqual(metadata.stringEncoding, .isoLatin1)
        XCTAssertEqual(metadata.toUserInfo()[NSStringEncodingErrorKey] as? UInt, String.Encoding.isoLatin1.rawValue)
    }

    func testNonFileURL() {
        let url = URL(string: "http://something.com/file/path")!
        let metadata = ErrorMetadata(url: url)

        XCTAssertEqual(metadata.url, url)
        XCTAssertEqual(metadata.toUserInfo()[NSURLErrorKey] as? URL, url)

        XCTAssertNil(metadata.path)
        XCTAssertNil(metadata.pathString)
        XCTAssertNil(metadata.toUserInfo()[NSFilePathErrorKey])
    }

    func testOnMacOS12() {
        let pathMetadata = ErrorMetadata(path: FilePath("/usr/bin/something"))
        let stringMetadata = ErrorMetadata(path: "/omg/wtf/bbq")

        emulateMacOSVersion(12) {
            XCTAssertEqual(pathMetadata.url, URL(filePath: "/usr/bin/something"))
            XCTAssertEqual(stringMetadata.url, URL(filePath: "/omg/wtf/bbq"))
        }
    }

    func testOnMacOS11() {
        let pathMetadata = ErrorMetadata(path: FilePath("/usr/bin/something"))
        let stringMetadata = ErrorMetadata(path: "/omg/wtf/bbq")

        emulateMacOSVersion(11) {
            XCTAssertEqual(pathMetadata.pathString, "/usr/bin/something")
            XCTAssertEqual(stringMetadata.pathString, "/omg/wtf/bbq")
            XCTAssertEqual(pathMetadata.url, URL(filePath: "/usr/bin/something"))
            XCTAssertEqual(stringMetadata.url, URL(filePath: "/omg/wtf/bbq"))
        }
    }

    func testFailOnMacOS10() {
        let pathMetadata = ErrorMetadata(path: FilePath("/usr/bin/something"))

        emulateMacOSVersion(10) {
            let failMessage = allowFailure { _ = pathMetadata.pathString }

            XCTAssertEqual(failMessage, "Should not be reached")
        }
    }
}
