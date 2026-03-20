//
//  RecoverabilityTests.swift
//
//
//  Created by Charles Srstka on 1/16/23.
//

#if Foundation

import CSErrors
import Foundation
import System
import Testing

@Suite("Recoverability Tests")
struct RecoverabilityTests {
    @Test("No async attempter")
    func testNoAsyncAttempter() async {
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

        #expect(recoverableError.underlyingError as? CocoaError == originalError)
        #expect(recoverableError.localizedDescription == originalError.localizedDescription)

        #expect(!recoverableError.attemptRecovery(optionIndex: 0))
        #expect(recoverableError.attemptRecovery(optionIndex: 1))
        #expect(!recoverableError.attemptRecovery(optionIndex: 2))

        await confirmation("Recover Sync Errors Asynchronously", expectedCount: 3) { ranAttempter in
            recoverableError.attemptRecovery(optionIndex: 0) {
                #expect(!$0)
                ranAttempter()
            }

            recoverableError.attemptRecovery(optionIndex: 1) {
                #expect($0)
                ranAttempter()
            }

            recoverableError.attemptRecovery(optionIndex: 2) {
                #expect(!$0)
                ranAttempter()
            }
        }
    }

    @Test("Async attempter")
    func testAsyncAttempter() async throws {
        actor CallCounts {
            var sync = 0
            var async = 0

            func incrementSync() { self.sync += 1 }
            func incrementAsync() { self.async += 1 }
        }

        let callCounts = CallCounts()

        await confirmation("Recover Async Errors", expectedCount: 6) { ranAttempter in
            let originalError = CocoaError(
                .fileNoSuchFile,
                description: "Foo",
                failureReason: "Bar",
                recoverySuggestion: "Baz",
                helpAnchor: "Qux"
            )

            let syncAttempter: @Sendable (Int) -> Bool = {
                Task {
                    await callCounts.incrementSync()
                    ranAttempter()
                }

                return $0 == 1
            }

            let asyncAttempter: @Sendable (Int) async -> Bool = {
                await callCounts.incrementAsync()
                ranAttempter()

                return $0 == 0
            }

            let recoverableError = originalError.makeRecoverable(
                recoveryOptions: ["Continue if Async", "Continue if Sync", "Fail"],
                attempter: syncAttempter,
                asyncAttempter: asyncAttempter
            )

            #expect(recoverableError.underlyingError as? CocoaError == originalError)
            #expect(recoverableError.localizedDescription == originalError.localizedDescription)

            #expect(!recoverableError.attemptRecovery(optionIndex: 0))
            #expect(recoverableError.attemptRecovery(optionIndex: 1))
            #expect(!recoverableError.attemptRecovery(optionIndex: 2))

            await withTaskGroup { group in
                group.addTask {
                    await withUnsafeContinuation { continuation in
                        recoverableError.attemptRecovery(optionIndex: 0) {
                            #expect($0)
                            continuation.resume()
                        }
                    }
                }

                group.addTask {
                    await withUnsafeContinuation { continuation in
                        recoverableError.attemptRecovery(optionIndex: 1) {
                            #expect(!$0)
                            continuation.resume()
                        }
                    }
                }

                group.addTask {
                    await withUnsafeContinuation { continuation in
                        recoverableError.attemptRecovery(optionIndex: 2) {
                            #expect(!$0)
                            continuation.resume()
                        }
                    }
                }

                await group.waitForAll()
            }
        }

        let syncCount = await callCounts.sync
        let asyncCount = await callCounts.async

        #expect(syncCount == 3)
        #expect(asyncCount == 3)
    }

    @Test("With button titles")
    func testWithButtonTitles() async {
        let originalError = Errno.noSuchFileOrDirectory
        let recoverableError = originalError.makeRecoverable(continueButtonTitle: "OK", cancelButtonTitle: "Cancel")
        let defaultCancelError = originalError.makeRecoverable(
            continueButtonTitle: "OK",
            cancelButtonTitle: "Cancel",
            continueIsDefault: false
        )

        #expect(recoverableError.underlyingError as? Errno == originalError)
        #expect(defaultCancelError.underlyingError as? Errno == originalError)

        #expect(recoverableError.attemptRecovery(optionIndex: 0))
        #expect(!recoverableError.attemptRecovery(optionIndex: 1))

        #expect(!defaultCancelError.attemptRecovery(optionIndex: 0))
        #expect(defaultCancelError.attemptRecovery(optionIndex: 1))

        await confirmation("Recover Button Errors Asynchronously", expectedCount: 4) { ranAttempter in
            recoverableError.attemptRecovery(optionIndex: 0) {
                #expect($0)
                ranAttempter()
            }
            
            recoverableError.attemptRecovery(optionIndex: 1) {
                #expect(!$0)
                ranAttempter()
            }

            defaultCancelError.attemptRecovery(optionIndex: 0) {
                #expect(!$0)
                ranAttempter()
            }
            defaultCancelError.attemptRecovery(optionIndex: 1) {
                #expect($0)
                ranAttempter()
            }
        }
    }

    @Test("Cancelled error")
    func testCancelledError() async throws {
        let attempter: @Sendable (Int) -> Bool = { $0 == 0 }
        let asyncAttempter: @Sendable (Int) async -> Bool = { $0 == 0 }

        let nonCanceledErr = Errno.textFileBusy.makeRecoverable(
            recoveryOptions: ["foo", "bar"],
            attempter: attempter,
            asyncAttempter: asyncAttempter
        )

        #expect(nonCanceledErr.attemptRecovery(optionIndex: 0))
        #expect(!nonCanceledErr.attemptRecovery(optionIndex: 1))

        await confirmation("Recover NonCanceled Errors Asynchronously", expectedCount: 2) { ranAttempter in
            await withTaskGroup { group in
                group.addTask {
                    await withUnsafeContinuation { continuation in
                        nonCanceledErr.attemptRecovery(optionIndex: 0) {
                            #expect($0)
                            ranAttempter()
                            continuation.resume()
                        }
                    }
                }

                group.addTask {
                    await withUnsafeContinuation { continuation in
                        nonCanceledErr.attemptRecovery(optionIndex: 1) {
                            #expect(!$0)
                            ranAttempter()
                            continuation.resume()
                        }
                    }
                }

                await group.waitForAll()
            }
        }

        let canceledErr = Errno.canceled.makeRecoverable(
            recoveryOptions: ["foo", "bar"],
            attempter: attempter,
            asyncAttempter: asyncAttempter
        )

        #expect(!canceledErr.attemptRecovery(optionIndex: 0))
        #expect(!canceledErr.attemptRecovery(optionIndex: 1))

        await confirmation("Recover Cancelled Errors Asynchronously", expectedCount: 2) { ranAttempter in
            canceledErr.attemptRecovery(optionIndex: 0) {
                #expect(!$0)
                ranAttempter()
            }

            canceledErr.attemptRecovery(optionIndex: 1) {
                #expect(!$0)
                ranAttempter()
            }
        }
    }

    @Test("Protocol compliance")
    func testProtocolCompliance() {
        let a: @Sendable (Int) -> Bool = { _ in true }
        #expect(a(0))

        #expect(Errno.noSuchFileOrDirectory.makeRecoverable(recoveryOptions: [], attempter: a).isFileNotFoundError)
        #expect(!Errno.noSuchFileOrDirectory.makeRecoverable(recoveryOptions: [], attempter: a).isCancelledError)

        #expect(Errno.notPermitted.makeRecoverable(recoveryOptions: [], attempter: a).isPermissionError)
        #expect(!Errno.notPermitted.makeRecoverable(recoveryOptions: [], attempter: a).isFileNotFoundError)

        #expect(Errno.canceled.makeRecoverable(recoveryOptions: [], attempter: a).isCancelledError)
        #expect(!Errno.canceled.makeRecoverable(recoveryOptions: [], attempter: a).isPermissionError)
    }
}

#endif

