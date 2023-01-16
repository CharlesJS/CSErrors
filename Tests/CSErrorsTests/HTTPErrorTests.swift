//
//  HTTPErrorTests.swift
//  
//
//  Created by Charles Srstka on 1/12/23.
//

import XCTest
import CSErrors

class HTTPErrorTests: XCTestCase {
    func testErrorProperties() {
        for statusCode in (400..<600) {
            let err = HTTPError(statusCode: statusCode)

            XCTAssertEqual(err.statusCode, statusCode)
            XCTAssertEqual(err._code, statusCode)
            XCTAssertEqual(err.failureReason, "HTTP \(statusCode)")
            XCTAssertEqual(err.errorDescription, "HTTP \(statusCode)")
        }
    }

    func testErrorProtocolConformance() {
        XCTAssertTrue(HTTPError(statusCode: 404).isFileNotFoundError)
        XCTAssertFalse(HTTPError(statusCode: 403).isFileNotFoundError)

        XCTAssertTrue(HTTPError(statusCode: 401).isPermissionError)
        XCTAssertTrue(HTTPError(statusCode: 403).isPermissionError)
        XCTAssertTrue(HTTPError(statusCode: 407).isPermissionError)
        XCTAssertFalse(HTTPError(statusCode: 404).isPermissionError)

        for statusCode in (400..<600) {
            XCTAssertFalse(HTTPError(statusCode: statusCode).isCancelledError)
        }
    }
}
