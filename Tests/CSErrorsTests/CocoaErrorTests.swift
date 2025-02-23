//
//  CocoaErrorTests.swift
//  
//
//  Created by Charles Srstka on 1/16/23.
//

#if Foundation

import CSErrors
import System
import XCTest

@available(macOS 13.0, *)
class CocoaErrorTests: XCTestCase {
    func testCocoaErrorWithPath() {
        let err = CocoaError(
            .fileNoSuchFile,
            description: "no can do",
            failureReason: "i don't wanna",
            stringEncoding: .macOSRoman,
            path: FilePath("/path/to/file")
        )

        XCTAssertEqual(err.code, .fileNoSuchFile)
        XCTAssertEqual(err.errorCode, CocoaError.Code.fileNoSuchFile.rawValue)
        XCTAssertEqual(err.localizedDescription, "no can do")
        XCTAssertEqual(err.userInfo[NSLocalizedFailureReasonErrorKey] as? String, "i don't wanna")
        XCTAssertEqual(err.stringEncoding, .macOSRoman)
        XCTAssertEqual(err.url, URL(filePath: "/path/to/file"))
    }

    func testCocoaErrorWithURL() {
        let err = CocoaError(
            .fileNoSuchFile,
            description: "no can do",
            failureReason: "i don't wanna",
            stringEncoding: .macOSRoman,
            url: URL(filePath: "/path/to/file")
        )

        XCTAssertEqual(err.code, .fileNoSuchFile)
        XCTAssertEqual(err.errorCode, CocoaError.Code.fileNoSuchFile.rawValue)
        XCTAssertEqual(err.localizedDescription, "no can do")
        XCTAssertEqual(err.userInfo[NSLocalizedFailureReasonErrorKey] as? String, "i don't wanna")
        XCTAssertEqual(err.stringEncoding, .macOSRoman)
        XCTAssertEqual(err.url, URL(filePath: "/path/to/file"))
    }

    func testFileNotFound() {
        XCTAssertTrue(CocoaError(.fileNoSuchFile).isFileNotFoundError)
        XCTAssertTrue(CocoaError(.fileReadNoSuchFile).isFileNotFoundError)
        XCTAssertTrue(CocoaError(.ubiquitousFileUnavailable).isFileNotFoundError)
        XCTAssertFalse(CocoaError(.fileWriteNoPermission).isFileNotFoundError)
    }

    func testPermissionError() {
        XCTAssertTrue(CocoaError(.fileReadNoPermission).isPermissionError)
        XCTAssertTrue(CocoaError(.fileWriteNoPermission).isPermissionError)
        XCTAssertFalse(CocoaError(.fileNoSuchFile).isPermissionError)
    }

    func testCancelledError() {
        XCTAssertTrue(CocoaError(.userCancelled).isCancelledError)
        XCTAssertFalse(CocoaError(.fileNoSuchFile).isCancelledError)
    }
}

#endif
