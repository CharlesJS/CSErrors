//
//  CocoaError+CSErrors.swift
//  CSErrors
//
//  Created by Charles Srstka on 4/17/20.
//

import Foundation
import System
import CSErrors

extension CocoaError {
    /// Create a `CocoaError` with an associated `userInfo` dictionary.
    ///
    /// In many cases, the resulting error's `localizedDescription` will be adjusted based on the provided information.
    /// - Parameters:
    ///     - code: A Cocoa error code.
    ///     - description: A localized message describing what error occurred.
    ///         Corresponds to `NSLocalizedDescriptionKey` in the `userInfo` dictionary.
    ///         If provided, this value will be returned by the `localizedDescription` method.
    ///     - failureReason: A localized message describing the reason for the failure.
    ///         Corresponds to `NSLocalizedFailureReasonErrorKey` in the `userInfo` dictionary.
    ///         If no value is provided for `description`, this value will be returned by the `localizedDescription`
    ///         method.
    ///     - recoverySuggestion: A localized message describing how one might recover from the failure.
    ///         Corresponds to `NSLocalizedRecoverySuggestionErrorKey` in the `userInfo` dictionary.
    ///     - recoveryOptions: A localized message providing “help” text if the user requests help.
    ///         Corresponds to `NSLocalizedRecoveryOptionsErrorKey` in the `userInfo` dictionary.
    ///     - recoveryAttempter: An object that conforms to the `NSErrorRecoveryAttempting` informal protocol.
    ///         Corresponds to `NSRecoveryAttempterErrorKey` in the `userInfo` dictionary.
    ///     - helpAnchor: A string to display in response to an alert panel help anchor button being pressed.
    ///         Corresponds to `NSHelpAnchorErrorKey` in the `userInfo` dictionary.
    ///     - stringEncoding: The string encoding associated with this error, if any.
    ///         Corresponds to `NSStringEncodingErrorKey` in the `userInfo` dictionary.
    ///     - path: A path associated with the error. Corresponds to `NSFilePathErrorKey` in the `userInfo` dictionary.
    ///         This can be very useful for customizing the  error's `localizedDescription` based on the associated filename.
    ///     - underlying: The underlying error which caused this error, if any. Corresponds to `NSUnderlyingErrorKey`
    ///         in the `userInfo` dictionary.
    ///     - custom: A dictionary containing additional key-value pairs to insert in the `userInfo` dictionary.
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
    public init(
        _ code: Code,
        description: String? = nil,
        failureReason: String? = nil,
        recoverySuggestion: String? = nil,
        recoveryOptions: [String]? = nil,
        recoveryAttempter: Any? = nil,
        helpAnchor: String? = nil,
        stringEncoding: String.Encoding? = nil,
        path: FilePath,
        underlying: (any Error)? = nil,
        custom: [String: Any]? = nil
    ) {
        let metadata = ErrorMetadata(
            description: description,
            failureReason: failureReason,
            recoverySuggestion: recoverySuggestion,
            recoveryOptions: recoveryOptions,
            recoveryAttempter: recoveryAttempter,
            helpAnchor: helpAnchor,
            path: path,
            underlying: underlying,
            custom: custom
        )

        var userInfo = metadata.toUserInfo()

        if let stringEncoding {
            userInfo[NSStringEncodingErrorKey] = stringEncoding.rawValue
        }

        self.init(code, userInfo: userInfo)
    }
    /// Create a `CocoaError` with an associated `userInfo` dictionary.
    ///
    /// In many cases, the resulting error's `localizedDescription` will be adjusted based on the provided information.
    /// - Parameters:
    ///     - code: A Cocoa error code.
    ///     - description: A localized message describing what error occurred.
    ///         Corresponds to `NSLocalizedDescriptionKey` in the `userInfo` dictionary.
    ///         If provided, this value will be returned by the `localizedDescription` method.
    ///     - failureReason: A localized message describing the reason for the failure.
    ///         Corresponds to `NSLocalizedFailureReasonErrorKey` in the `userInfo` dictionary.
    ///         If no value is provided for `description`, this value will be returned by the `localizedDescription`
    ///         method.
    ///     - recoverySuggestion: A localized message describing how one might recover from the failure.
    ///         Corresponds to `NSLocalizedRecoverySuggestionErrorKey` in the `userInfo` dictionary.
    ///     - recoveryOptions: A localized message providing “help” text if the user requests help.
    ///         Corresponds to `NSLocalizedRecoveryOptionsErrorKey` in the `userInfo` dictionary.
    ///     - recoveryAttempter: An object that conforms to the `NSErrorRecoveryAttempting` informal protocol.
    ///         Corresponds to `NSRecoveryAttempterErrorKey` in the `userInfo` dictionary.
    ///     - helpAnchor: A string to display in response to an alert panel help anchor button being pressed.
    ///         Corresponds to `NSHelpAnchorErrorKey` in the `userInfo` dictionary.
    ///     - stringEncoding: The string encoding associated with this error, if any.
    ///         Corresponds to `NSStringEncodingErrorKey` in the `userInfo` dictionary.
    ///     - url: A URL associated with the error. Corresponds to `NSURLErrorKey` in the `userInfo` dictionary.
    ///         If the URL is a `file` URL, this also sets `NSFilePathErrorKey` in the `userInfo` dictionary,
    ///         which is very useful for customizing the  error's `localizedDescription` based on the associated filename.
    ///     - underlying: The underlying error which caused this error, if any. Corresponds to `NSUnderlyingErrorKey`
    ///         in the `userInfo` dictionary.
    ///     - custom: A dictionary containing additional key-value pairs to insert in the `userInfo` dictionary.
    public init(
        _ code: Code,
        description: String? = nil,
        failureReason: String? = nil,
        recoverySuggestion: String? = nil,
        recoveryOptions: [String]? = nil,
        recoveryAttempter: Any? = nil,
        helpAnchor: String? = nil,
        stringEncoding: String.Encoding? = nil,
        url: URL? = nil,
        underlying: (any Error)? = nil,
        custom: [String: Any]? = nil
    ) {
        let metadata = ErrorMetadata(
            description: description,
            failureReason: failureReason,
            recoverySuggestion: recoverySuggestion,
            recoveryOptions: recoveryOptions,
            recoveryAttempter: recoveryAttempter,
            helpAnchor: helpAnchor,
            stringEncoding: stringEncoding,
            url: url,
            underlying: underlying,
            custom: custom
        )

        self.init(code, userInfo: metadata.toUserInfo())
    }
}

extension CocoaError: CSErrorProtocol {
    public var isFileNotFoundError: Bool {
        [.fileNoSuchFile, .fileReadNoSuchFile, .ubiquitousFileUnavailable].contains(self.code)
    }

    public var isPermissionError: Bool {
        [.fileReadNoPermission, .fileWriteNoPermission].contains(self.code)
    }

    public var isCancelledError: Bool {
        self.code == .userCancelled
    }
}
