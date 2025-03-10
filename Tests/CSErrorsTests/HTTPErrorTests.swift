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
#if Foundation
            let reason = HTTPURLResponse.localizedString(forStatusCode: statusCode)

            XCTAssertEqual(err.failureReason, "HTTP \(statusCode) (\(reason))")
            XCTAssertEqual(err.errorDescription, "HTTP \(statusCode) (\(reason))")
#else
            XCTAssertEqual(err.failureReason, "HTTP \(statusCode)")
            XCTAssertEqual(err.errorDescription, "HTTP \(statusCode)")
#endif
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

#if Foundation
    func testFoundationMetadata() {
        let reasons: [Int : String] = [
            400: "bad request",
            401: "unauthorized",
            402: "payment required",
            403: "forbidden",
            404: "not found",
            405: "method not allowed",
            406: "unacceptable",
            407: "proxy authentication required",
            408: "request timed out",
            409: "conflict",
            410: "no longer exists",
            411: "length required",
            412: "precondition failed",
            413: "request too large",
            414: "requested URL too long",
            415: "unsupported media type",
            416: "requested range not satisfiable",
            417: "expectation failed",
            500: "internal server error",
            501: "unimplemented",
            502: "bad gateway",
            503: "service unavailable",
            504: "gateway timed out",
            505: "unsupported version"
        ]

        for statusCode in (400..<600) {
            let err = HTTPError(statusCode: statusCode)

            let reason = reasons[statusCode] ?? (statusCode < 500 ? "client error" : "server error")

            XCTAssertEqual(err.statusCode, statusCode)
            XCTAssertEqual(err._code, statusCode)
            XCTAssertEqual(err.failureReason, "HTTP \(statusCode) (\(reason))")
            XCTAssertEqual(err.errorDescription, "HTTP \(statusCode) (\(reason))")
        }
    }
#endif
}
