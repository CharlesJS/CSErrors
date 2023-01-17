//
//  RecoverabilityTests.swift
//  
//
//  Created by Charles Srstka on 1/16/23.
//

import CSErrors_Foundation
import System
import XCTest

class RecoverabilityTests: XCTestCase {
    func testNoAsyncAttempter() {
        let originalError = CocoaError(
            .fileNoSuchFile,
            description: "Foo",
            failureReason: "Bar",
            recoverySuggestion: "Baz",
            helpAnchor: "Qux"
        )

        let recoverableError = originalError.makeRecoverable(
            recoveryOptions: ["Abort", "Continue", "Scream"],
            attempter: { $0 == 1 }
        )

        XCTAssertEqual(recoverableError.underlyingError as? CocoaError, originalError)
        XCTAssertEqual(recoverableError.localizedDescription, originalError.localizedDescription)

        XCTAssertFalse(recoverableError.attemptRecovery(optionIndex: 0))
        XCTAssertTrue(recoverableError.attemptRecovery(optionIndex: 1))
        XCTAssertFalse(recoverableError.attemptRecovery(optionIndex: 0))

        let expectation = self.expectation(description: "Recover Sync Errors Asynchronously")
        expectation.expectedFulfillmentCount = 3

        recoverableError.attemptRecovery(optionIndex: 0) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        recoverableError.attemptRecovery(optionIndex: 1) {
            XCTAssertTrue($0)
            expectation.fulfill()
        }

        recoverableError.attemptRecovery(optionIndex: 2) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }

    func testAsyncAttempter() async throws {
        actor CallCounts {
            var sync = 0
            var async = 0

            func incrementSync() { self.sync += 1 }
            func incrementAsync() { self.async += 1 }
        }

        let callCounts = CallCounts()
        let expectation = self.expectation(description: "Recover Async Errors")
        expectation.expectedFulfillmentCount = 9


        let originalError = CocoaError(
            .fileNoSuchFile,
            description: "Foo",
            failureReason: "Bar",
            recoverySuggestion: "Baz",
            helpAnchor: "Qux"
        )

        let syncAttempter: (Int) -> Bool = {
            Task {
                await callCounts.incrementSync()
                expectation.fulfill()
            }

            return $0 == 1
        }

        let asyncAttempter: (Int) async -> Bool = {
            await callCounts.incrementAsync()
            expectation.fulfill()

            return $0 == 0
        }

        let recoverableError = originalError.makeRecoverable(
            recoveryOptions: ["Continue if Async", "Continue if Sync", "Fail"],
            attempter: syncAttempter,
            asyncAttempter: asyncAttempter
        )

        XCTAssertEqual(recoverableError.underlyingError as? CocoaError, originalError)
        XCTAssertEqual(recoverableError.localizedDescription, originalError.localizedDescription)

        XCTAssertFalse(recoverableError.attemptRecovery(optionIndex: 0))
        XCTAssertTrue(recoverableError.attemptRecovery(optionIndex: 1))
        XCTAssertFalse(recoverableError.attemptRecovery(optionIndex: 0))

        recoverableError.attemptRecovery(optionIndex: 0) {
            XCTAssertTrue($0)
            expectation.fulfill()
        }

        recoverableError.attemptRecovery(optionIndex: 1) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        recoverableError.attemptRecovery(optionIndex: 2) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        await self.waitForExpectations(timeout: 10)

        let syncCount = await callCounts.sync
        let asyncCount = await callCounts.async

        XCTAssertEqual(syncCount, 3)
        XCTAssertEqual(asyncCount, 3)
    }

    func testWithButtonTitles() {
        let originalError = Errno.noSuchFileOrDirectory
        let recoverableError = originalError.makeRecoverable(continueButtonTitle: "OK", cancelButtonTitle: "Cancel")
        let defaultCancelError = originalError.makeRecoverable(
            continueButtonTitle: "OK",
            cancelButtonTitle: "Cancel",
            continueIsDefault: false
        )

        XCTAssertEqual(recoverableError.underlyingError as? Errno, originalError)
        XCTAssertEqual(defaultCancelError.underlyingError as? Errno, originalError)

        XCTAssertTrue(recoverableError.attemptRecovery(optionIndex: 0))
        XCTAssertFalse(recoverableError.attemptRecovery(optionIndex: 1))

        XCTAssertFalse(defaultCancelError.attemptRecovery(optionIndex: 0))
        XCTAssertTrue(defaultCancelError.attemptRecovery(optionIndex: 1))

        let expectation = self.expectation(description: "Recover Button Errors Asynchronously")
        expectation.expectedFulfillmentCount = 4

        recoverableError.attemptRecovery(optionIndex: 0) {
            XCTAssertTrue($0)
            expectation.fulfill()
        }

        recoverableError.attemptRecovery(optionIndex: 1) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        defaultCancelError.attemptRecovery(optionIndex: 0) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        defaultCancelError.attemptRecovery(optionIndex: 1) {
            XCTAssertTrue($0)
            expectation.fulfill()
        }


        self.waitForExpectations(timeout: 10)
    }

    func testCancelledError() {
        let expectation = self.expectation(description: "Test Cancelled Errors")
        expectation.expectedFulfillmentCount = 4

        let attempter: (Int) -> Bool = { $0 == 0 }
        let asyncAttempter: (Int) async -> Bool = { $0 == 0 }

        let nonCanceledErr = Errno.textFileBusy.makeRecoverable(
            recoveryOptions: ["foo", "bar"],
            attempter: attempter,
            asyncAttempter: asyncAttempter
        )

        XCTAssertTrue(nonCanceledErr.attemptRecovery(optionIndex: 0))
        XCTAssertFalse(nonCanceledErr.attemptRecovery(optionIndex: 1))

        nonCanceledErr.attemptRecovery(optionIndex: 0) {
            XCTAssertTrue($0)
            expectation.fulfill()
        }

        nonCanceledErr.attemptRecovery(optionIndex: 1) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        let canceledErr = Errno.canceled.makeRecoverable(
            recoveryOptions: ["foo", "bar"],
            attempter: attempter,
            asyncAttempter: asyncAttempter
        )

        XCTAssertFalse(canceledErr.attemptRecovery(optionIndex: 0))
        XCTAssertFalse(canceledErr.attemptRecovery(optionIndex: 1))

        canceledErr.attemptRecovery(optionIndex: 0) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        canceledErr.attemptRecovery(optionIndex: 1) {
            XCTAssertFalse($0)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10)
    }

    func testProtocolCompliance() {
        let a: (Int) -> Bool = { _ in true }
        XCTAssertTrue(a(0)) // just to satisfy the coverage check

        XCTAssertTrue(Errno.noSuchFileOrDirectory.makeRecoverable(recoveryOptions: [], attempter: a).isFileNotFoundError)
        XCTAssertFalse(Errno.noSuchFileOrDirectory.makeRecoverable(recoveryOptions: [], attempter: a).isCancelledError)

        XCTAssertTrue(Errno.notPermitted.makeRecoverable(recoveryOptions: [], attempter: a).isPermissionError)
        XCTAssertFalse(Errno.notPermitted.makeRecoverable(recoveryOptions: [], attempter: a).isFileNotFoundError)

        XCTAssertTrue(Errno.canceled.makeRecoverable(recoveryOptions: [], attempter: a).isCancelledError)
        XCTAssertFalse(Errno.canceled.makeRecoverable(recoveryOptions: [], attempter: a).isPermissionError)
    }
}
