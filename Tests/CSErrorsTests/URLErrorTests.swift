//
//  URLErrorTests.swift
//
//
//  Created by Charles Srstka on 1/16/23.
//

#if Foundation && canImport(Darwin)

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

@Suite("URLError Tests")
struct URLErrorTests {
    @Test("URLError metadata")
    func testURLErrormetadata() {
        let url = URL(string: "https://www.terribleurl.com/who/made/this/garbage")!

        let err = URLError(
            .badURL,
            description: "URL is bad",
            failureReason: "I hate this URL",
            recoverySuggestion: "Burn it with fire",
            recoveryOptions: ["Go somewhere else", "Fret"],
            recoveryAttempter: "Complain to Webmaster",
            helpAnchor: "Haaaaalp",
            stringEncoding: .utf8,
            url: url,
            underlying: Errno.badFileTypeOrFormat,
            custom: ["foo": "bar"]
        )

        #expect(err.code == .badURL)
        #expect(err.localizedDescription == "URL is bad")
        #expect(err.underlyingError as? Errno == Errno.badFileTypeOrFormat)

        let userInfo = err.userInfo
        #expect(userInfo[NSLocalizedFailureReasonErrorKey] as? String == "I hate this URL")
        #expect(userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String == "Burn it with fire")
        #expect(userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String] == ["Go somewhere else", "Fret"])
        #expect(userInfo[NSRecoveryAttempterErrorKey] as? String == "Complain to Webmaster")
        #expect(userInfo[NSHelpAnchorErrorKey] as? String == "Haaaaalp")
#if Foundation && canImport(Darwin)
        #expect(userInfo[NSStringEncodingErrorKey] as? UInt == String.Encoding.utf8.rawValue)
#endif
        #expect(userInfo[NSStringEncodingErrorKeyNonDarwin] as? Int == Int(String.Encoding.utf8.rawValue))
        #expect(userInfo[NSURLErrorKey] as? URL == url)
        #expect(userInfo[NSFilePathErrorKey] == nil)
        #expect(userInfo["foo"] as? String == "bar")
    }

    @Test("Protocol compliance")
    func testProtocolCompliance() {
        #expect(URLError(.fileDoesNotExist).isFileNotFoundError)
        #expect(!URLError(.fileDoesNotExist).isPermissionError)

        #expect(URLError(.noPermissionsToReadFile).isPermissionError)
        #expect(!URLError(.noPermissionsToReadFile).isCancelledError)

        #expect(URLError(.cancelled).isCancelledError)
        #expect(!URLError(.cancelled).isFileNotFoundError)

        #expect(URLError(.userCancelledAuthentication).isCancelledError)
        #expect(!URLError(.userCancelledAuthentication).isPermissionError)
    }
}

#endif

