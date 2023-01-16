////
////  Recoverability.swift
////
////
////  Created by Charles Srstka on 1/10/23.
////

import CSErrors
import Foundation

extension Error {
    /// A helper for adding recoverability to an existing error.
    ///
    /// When passed to error presentation  methods such as macOS's `NSApplication.presentError` method, multiple buttons will appear in the resulting error
    /// dialog, some of which will allow the method to be recovered.
    /// - Parameters:
    ///     - recoveryOptions: Provides a set of possible recovery options to present to the user.
    ///     - attempter: A closure which should attempt to recover from this error when the user selected
    ///         the option at the given index.
    ///         Return true from this closure to indicate successful recovery, and false otherwise.
    ///     - asyncAttempter: An optional asynchronous closure which should attempt to recover from this
    ///         error when the user selected the option at the given index.
    ///         Pass true to the passed-in closure to indicate successful recovery, and false otherwise.
    /// - Returns: An error which responds to the `RecoverableError` protocol.
    public func makeRecoverable(
        recoveryOptions: [String],
        attempter: @escaping (Int) -> Bool,
        asyncAttempter: ((Int) async -> Bool)? = nil
    ) -> some RecoverableError {
        RecoverableErrorWrapper(
            underlying: self,
            recoveryOptions: recoveryOptions,
            attempter: attempter,
            asyncAttempter: asyncAttempter
        )
    }

    /// A helper for adding recoverability to an existing error.
    ///
    /// When passed to error presentation  methods such as macOS's `NSApplication.presentError` method, multiple buttons will appear in the resulting error
    /// dialog, some of which will allow the method to be recovered.
    /// - Parameters:
    ///  - continueButtonTitle: The localized title that should appear for the “Continue” button
    ///      in an error presentation dialog.
    ///  - cancelButtonTitle: The localized title that should appear for the “Cancel” button in an error
    ///      presentation dialog.
    ///  - continueIsDefault: `true` if the “Continue” button should be the default option,
    ///      `false` if “Cancel” should be the default.
    ///      Defaults to `true`.
    /// - Returns: An error which responds to the `RecoverableError` protocol.
    public func makeRecoverable(
        continueButtonTitle: String,
        cancelButtonTitle: String,
        continueIsDefault: Bool = true
    ) -> some RecoverableError {
        RecoverableErrorWrapper(
            underlying: self,
            continueButtonTitle: continueButtonTitle,
            cancelButtonTitle: cancelButtonTitle,
            continueIsDefault: continueIsDefault
        )
    }

    /// Returns the underlying error, if there is one.
    public var underlyingError: (any Error)? {
        if let recoverableErrorWrapper = self as? RecoverableErrorWrapper {
            return recoverableErrorWrapper.underlying
        }

        return (self as NSError).userInfo[NSUnderlyingErrorKey] as? Error
    }
}

private struct RecoverableErrorWrapper: LocalizedError, RecoverableError {
    let underlying: any Error
    let recoveryOptions: [String]
    let attempter: (Int) -> Bool
    let asyncAttempter: ((Int) async -> Bool)?

    var errorDescription: String? { return self.underlying.localizedDescription }

    init(
        underlying: any Error,
        recoveryOptions: [String],
        attempter: @escaping (Int) -> Bool,
        asyncAttempter: ((Int) async -> Bool)?
    ) {
        self.underlying = underlying
        self.recoveryOptions = recoveryOptions
        self.attempter = attempter
        self.asyncAttempter = asyncAttempter
    }

    init(underlying: any Error, continueButtonTitle: String, cancelButtonTitle: String, continueIsDefault: Bool = true) {
        self.underlying = underlying
        self.asyncAttempter = nil

        if continueIsDefault {
            self.recoveryOptions = [continueButtonTitle, cancelButtonTitle]
            self.attempter = { $0 == 0 }
        } else {
            self.recoveryOptions = [cancelButtonTitle, continueButtonTitle]
            self.attempter = { $0 == 1 }
        }
    }

    func attemptRecovery(optionIndex: Int) -> Bool {
        return self.underlying.isCancelledError ? false : self.attempter(optionIndex)
    }

    func attemptRecovery(optionIndex: Int, resultHandler handler: @escaping (Bool) -> Void) {
        if let asyncAttempter = self.asyncAttempter {
            if self.underlying.isCancelledError {
                handler(false)
            } else {
                Task {
                    handler(await asyncAttempter(optionIndex))
                }
            }
        } else {
            handler(self.attemptRecovery(optionIndex: optionIndex))
        }
    }
}

extension RecoverableErrorWrapper: CSErrorProtocol {
    public var isFileNotFoundError: Bool {
        self.underlying.isFileNotFoundError
    }

    public var isPermissionError: Bool {
        self.underlying.isPermissionError
    }

    public var isCancelledError: Bool {
        self.underlying.isCancelledError
    }
}
