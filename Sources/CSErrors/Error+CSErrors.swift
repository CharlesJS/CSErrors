//
//  Error+CSErrors.swift
//  CSErrors
//
//  Created by Charles Srstka on 12/27/15.
//

import Foundation

extension Error {
    /**
     A helper for adding recoverability to an existing error. When passed to error presentation  methods such as macOS's
     `NSApplication.presentError` method, multiple buttons will appear in the resulting error dialog, some of which
     will allow the method to be recovered.
     - Parameters:
         - recoveryOptions: Provides a set of possible recovery options to present to the user.
         - attempter: A closure which should attempt to recover from this error when the user selected
             the option at the given index.
             Return true from this closure to indicate successful recovery, and false otherwise.
         - asyncAttempter: An optional asynchronous closure which should attempt to recover from this
             error when the user selected the option at the given index.
             Pass true to the passed-in closure to indicate successful recovery, and false otherwise.
     - Returns: An error which responds to the `RecoverableError` protocol.
     */
    public func makeRecoverable(
        recoveryOptions: [String],
        attempter: @escaping (Int) -> Bool,
        asyncAttempter: ((Int, @escaping (Bool) -> Void) -> Void)? = nil
    ) -> RecoverableError {
        RecoverableErrorWrapper(
            underlying: self,
            recoveryOptions: recoveryOptions,
            attempter: attempter,
            asyncAttempter: asyncAttempter
        )
    }

    /**
     A helper for adding recoverability to an existing error. When passed to error presentation  methods such as macOS's
     `NSApplication.presentError` method, multiple buttons will appear in the resulting error dialog, some of which
     will allow the method to be recovered.
     - Parameters:
         - continueButtonTitle: The localized title that should appear for the “Continue” button
             in an error presentation dialog.
         - cancelButtonTitle: The localized title that should appear for the “Cancel” button in an error
             presentation dialog.
         - continueIsDefault: `true` if the “Continue” button should be the default option,
             `false` if “Cancel” should be the default.
             Defaults to `true`.
     - Returns: An error which responds to the `RecoverableError` protocol.
     */
    public func makeRecoverable(
        continueButtonTitle: String,
        cancelButtonTitle: String,
        continueIsDefault: Bool = true
    ) -> RecoverableError {
        RecoverableErrorWrapper(
            underlying: self,
            continueButtonTitle: continueButtonTitle,
            cancelButtonTitle: cancelButtonTitle,
            continueIsDefault: continueIsDefault
        )
    }

    /// Convert an error to an `OSStatus`, if it is backed by one.
    public func toOSStatus() -> OSStatus? {
        let nsError = self as NSError

        return (nsError.domain == NSOSStatusErrorDomain) ? OSStatus(nsError.code) : nil
    }

    /// Returns the underlying error, if there is one.
    public var underlyingError: Error? {
        if let recoverableErrorWrapper = self as? RecoverableErrorWrapper {
            return recoverableErrorWrapper.underlying
        } else {
            return (self as NSError).userInfo[NSUnderlyingErrorKey] as? Error
        }
    }

    /// True if the error represents a “File Not Found” error, regardless of domain.
    public var isFileNotFoundError: Bool {
        if let posixErr = self as? POSIXError, posixErr == POSIXError(.ENOENT) {
            return true
        }

        let cocoaCodes: [CocoaError.Code] = [.fileNoSuchFile, .fileReadNoSuchFile, .ubiquitousFileUnavailable]
        if let cocoaErr = self as? CocoaError, cocoaCodes.contains(cocoaErr.code) {
            return true
        }

        if let urlErr = self as? URLError, urlErr.code == .fileDoesNotExist {
            return true
        }

        if let osStatus = self as? OSStatus, osStatus == OSStatus(fnfErr) {
            return true
        }

        if let underlyingError = self.underlyingError, underlyingError.isFileNotFoundError {
            return true
        }

        return false
    }

    /// True if the error represents a permission or access error, regardless of domain.
    public var isPermissionError: Bool {
        if let posixErr = self as? POSIXError, [.EACCES, .EPERM].contains(posixErr.code) {
            return true
        }

        let cocoaCodes: [CocoaError.Code] = [.fileReadNoPermission, .fileWriteNoPermission]
        if let cocoaErr = self as? Foundation.CocoaError, cocoaCodes.contains(cocoaErr.code) {
            return true
        }

        if let urlErr = self as? URLError, urlErr.code == .noPermissionsToReadFile {
            return true
        }

        if let osStatus = self as? OSStatus, osStatus == OSStatus(afpAccessDenied) {
            return true
        }

        if let underlyingError = self.underlyingError, underlyingError.isPermissionError {
            return true
        }

        return false
    }

    /// True if the error results from a user cancellation, regardless of domain.
    public var isCancelledError: Bool {
        if let cocoaErr = self as? Foundation.CocoaError, cocoaErr.code == .userCancelled {
            return true
        }

        if let posixErr = self as? POSIXError, posixErr.code == .ECANCELED {
            return true
        }

        if let urlErr = self as? URLError, [.cancelled, .userCancelledAuthentication].contains(urlErr.code) {
            return true
        }

        let osStatusErrors = [userCanceledErr, errAEWaitCanceled, kernelCanceledErr, kOTCanceledErr, kECANCELErr,
                              errIACanceled, kRAConnectionCanceled, kTXNUserCanceledOperationErr,
                              kFBCindexingCanceled, kFBCaccessCanceled, kFBCsummarizationCanceled]
        if let osStatus = self as? OSStatus, osStatusErrors.contains(Int(osStatus)) {
            return true
        }

        if let underlyingError = self.underlyingError, underlyingError.isCancelledError {
            return true
        }

        return false
    }
}

private struct RecoverableErrorWrapper: LocalizedError, RecoverableError {
    let underlying: Error
    let recoveryOptions: [String]
    let attempter: (Int) -> Bool
    let asyncAttempter: ((Int, @escaping (Bool) -> Void) -> Void)?

    var errorDescription: String? { return self.underlying.localizedDescription }
    var failureReason: String? { return (self.underlying as NSError).localizedFailureReason }
    var recoverySuggestion: String? { return (self.underlying as NSError).localizedRecoverySuggestion }
    var helpAnchor: String? { return (self.underlying as NSError).helpAnchor }

    init(
        underlying: Error,
        recoveryOptions: [String],
        attempter: @escaping (Int) -> Bool,
        asyncAttempter: ((Int, @escaping (Bool) -> Void) -> Void)? = nil
    ) {
        self.underlying = underlying
        self.recoveryOptions = recoveryOptions
        self.attempter = attempter
        self.asyncAttempter = asyncAttempter
    }

    init(underlying: Error, continueButtonTitle: String, cancelButtonTitle: String, continueIsDefault: Bool = true) {
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
                asyncAttempter(optionIndex, handler)
            }
        } else {
            handler(self.attemptRecovery(optionIndex: optionIndex))
        }
    }
}
