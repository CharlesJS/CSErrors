//
//  URLErrorTests.swift
//  
//
//  Created by Charles Srstka on 1/16/23.
//

import CSErrors_Foundation
import System
import XCTest

class URLErrorTests: XCTestCase {
    func testURLErrorMetadata() {
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

        XCTAssertEqual(err.code, .badURL)
        XCTAssertEqual(err.localizedDescription, "URL is bad")
        XCTAssertEqual(err.underlyingError as? Errno, Errno.badFileTypeOrFormat)

        let userInfo = err.userInfo
        XCTAssertEqual(userInfo[NSLocalizedFailureReasonErrorKey] as? String, "I hate this URL")
        XCTAssertEqual(userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String, "Burn it with fire")
        XCTAssertEqual(userInfo[NSLocalizedRecoveryOptionsErrorKey] as? [String], ["Go somewhere else", "Fret"])
        XCTAssertEqual(userInfo[NSRecoveryAttempterErrorKey] as? String, "Complain to Webmaster")
        XCTAssertEqual(userInfo[NSHelpAnchorErrorKey] as? String, "Haaaaalp")
        XCTAssertEqual(userInfo[NSStringEncodingErrorKey] as? UInt, String.Encoding.utf8.rawValue)
        XCTAssertEqual(userInfo[NSURLErrorKey] as? URL, url)
        XCTAssertNil(userInfo[NSFilePathErrorKey])
        XCTAssertEqual(userInfo["foo"] as? String, "bar")
    }

    func testProtocolCompliance() {
        XCTAssertTrue(URLError(.fileDoesNotExist).isFileNotFoundError)
        XCTAssertFalse(URLError(.fileDoesNotExist).isPermissionError)

        XCTAssertTrue(URLError(.noPermissionsToReadFile).isPermissionError)
        XCTAssertFalse(URLError(.noPermissionsToReadFile).isCancelledError)

        XCTAssertTrue(URLError(.cancelled).isCancelledError)
        XCTAssertFalse(URLError(.cancelled).isFileNotFoundError)

        XCTAssertTrue(URLError(.userCancelledAuthentication).isCancelledError)
        XCTAssertFalse(URLError(.userCancelledAuthentication).isPermissionError)
    }
}
