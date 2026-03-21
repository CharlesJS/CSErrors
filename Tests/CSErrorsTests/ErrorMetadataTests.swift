//
//  ErrorMetadataTests.swift
//
//
//  Created by Charles Srstka on 1/16/23.
//

#if Foundation

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

@Suite("Error Metadata Tests")
	struct ErrorMetadataTests {
    private struct WhatYouSay: Error {
        let description: String
        let additionalDescription: String
    }

    @Test("Empty properties are nil")
    func testEmptyPropertiesAreNil() {
        let metadata = ErrorMetadata()

        #expect(metadata.description == nil)
        #expect(metadata.failureReason == nil)
        #expect(metadata.recoverySuggestion == nil)
        #expect(metadata.recoveryOptions == nil)
        #expect(metadata.recoveryAttempter == nil)
        #expect(metadata.helpAnchor == nil)
        #expect(metadata.path == nil)
        #expect(metadata.pathString == nil)
        #expect(metadata.url == nil)
        #expect(metadata.stringEncoding == nil)
        #expect(metadata.underlying == nil)
        #expect(metadata.custom == nil)
        #expect(metadata.toUserInfo().isEmpty)
    }

    private func checkMetadata(_ metadata: ErrorMetadata) {
        let userInfo = metadata.toUserInfo()

        #expect(userInfo[NSLocalizedDescriptionKey] as? String == "In AD 2101, war was beginning.")
        #expect(userInfo[NSLocalizedFailureReasonErrorKey] as? String == "What happen? Somebody set up us the bomb.")
        #expect(userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String == "We get signal.")
        #expect(userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String] == ["What!", "Main screen turn on.", "It's You!"])
        #expect(userInfo[NSRecoveryAttempterErrorKey] as? String == "How are you gentlemen!")
        #expect(userInfo[NSHelpAnchorErrorKey] as? String == "All your base are belong to us.")
        #expect(userInfo[NSFilePathErrorKey] as? String == "/you/are/on/the/way/to/destruction")
        #expect(userInfo[NSURLErrorKey] as? URL == URL(filePath: "/you/are/on/the/way/to/destruction"))
        #expect(metadata.path == FilePath("/you/are/on/the/way/to/destruction"))
        #expect(metadata.pathString == "/you/are/on/the/way/to/destruction")
        #expect(metadata.url == URL(filePath: "/you/are/on/the/way/to/destruction"))

        let underlying = userInfo[NSUnderlyingErrorKey] as? WhatYouSay
        #expect(underlying?.description == "You have no chance to survive make your time.")
        #expect(underlying?.additionalDescription == "Ha ha ha ha ha...")

        #expect(userInfo["Take off"] as? String == "every Zig")
        #expect(userInfo["You know"] as? String == "what you doing")
        #expect(userInfo["Move Zig"] as? String == "for great justice.")
    }

    @Test("Initialize with String path")
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

    @Test("Initialize with FilePath path")
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

    @Test("Initialize with URL")
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

    @Test("Failure reason without description")
    func testFailureReasonWithoutDescription() {
        let metadata = ErrorMetadata(failureReason: "I just don't wanna")

        #expect(metadata.toUserInfo()[NSLocalizedDescriptionKey] as? String == "I just don't wanna")
    }

    @Test("String Encoding property")
    func testErrorWithStringEncoding() {
        let metadata = ErrorMetadata(description: "Et Tu Brute", stringEncoding: .isoLatin1)

        #expect(metadata.stringEncoding == .isoLatin1)
    }

    @Test("Non-file URL property")
    func testNonFileURL() {
        let url = URL(string: "http://something.com/file/path")!
        let metadata = ErrorMetadata(url: url)

        #expect(metadata.url == url)
        #expect(metadata.toUserInfo()[NSURLErrorKey] as? URL == url)

        #expect(metadata.path == nil)
        #expect(metadata.pathString == nil)
        #expect(metadata.toUserInfo()[NSFilePathErrorKey] == nil)
    }

    @Test("macOS 12")
    func testOnMacOS12() {
        let pathMetadata = ErrorMetadata(path: FilePath("/usr/bin/something"))
        let stringMetadata = ErrorMetadata(path: "/omg/wtf/bbq")

        emulateMacOSVersion(12) {
            #expect(pathMetadata.url == URL(filePath: "/usr/bin/something"))
            #expect(stringMetadata.url == URL(filePath: "/omg/wtf/bbq"))
        }
    }

    @Test("macOS 11")
    func testOnMacOS11() {
        let pathMetadata = ErrorMetadata(path: FilePath("/usr/bin/something"))
        let stringMetadata = ErrorMetadata(path: "/omg/wtf/bbq")

        emulateMacOSVersion(11) {
            #expect(pathMetadata.pathString == "/usr/bin/something")
            #expect(stringMetadata.pathString == "/omg/wtf/bbq")
            #expect(pathMetadata.url == URL(filePath: "/usr/bin/something"))
            #expect(stringMetadata.url == URL(filePath: "/omg/wtf/bbq"))
        }
    }

    @Test("Fails on macOS 10.15")
    func testFailOnMacOS10() async {
        await #expect(processExitsWith: .failure) {
            let pathMetadata = ErrorMetadata(path: FilePath("/usr/bin/something"))

            emulateMacOSVersion(10) {
                _ = pathMetadata.pathString
            }
        }
    }
}

#endif

