//
//  ErrorMetadata+Foundation.swift
//  
//
//  Created by Charles Srstka on 1/11/23.
//

import Foundation
import System
import CSErrors

extension ErrorMetadata {
    /// Create an `ErrorMetadata` representing metadata for an error.
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
        description: String? = nil,
        failureReason: String? = nil,
        recoverySuggestion: String? = nil,
        recoveryOptions: [String]? = nil,
        recoveryAttempter: Any? = nil,
        helpAnchor: String? = nil,
        stringEncoding: String.Encoding? = nil,
        url: URL? = nil,
        underlying: (any Error)? = nil,
        custom _custom: [String: Any]? = nil
    ) {
        var custom = _custom ?? [:]
        var path: String? = nil

        if let url {
            custom[NSURLErrorKey] = url

            if url.isFileURL {
                path = url.path
            }
        }

        if let stringEncoding {
            custom[NSStringEncodingErrorKey] = stringEncoding.rawValue
        }

        self.init(
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
    }

    /// Export this error's metadata as a `userInfo` dictionary.
    ///
    /// This can be useful when implementing the `CustomNSError` protocol, and for associating data with other
    /// error classes that take `userInfo` dictionaries (such as `CocoaError`).
    ///
    /// - Returns: A `userInfo` dictionary, suitable for implementing `CustomNSError`'s `userInfo` property.
    public func toUserInfo() -> [String : Any] {
        var userInfo = [String: Any]()

        if let desc = self.description {
            userInfo[NSLocalizedDescriptionKey] = desc
        } else if let failureReason = failureReason {
            userInfo[NSLocalizedDescriptionKey] = failureReason
        }

        if let failureReason = self.failureReason {
            userInfo[NSLocalizedFailureReasonErrorKey] = failureReason
        }

        if let suggestion = self.recoverySuggestion {
            userInfo[NSLocalizedRecoverySuggestionErrorKey] = suggestion
        }

        if let options = self.recoveryOptions {
            userInfo[NSLocalizedRecoveryOptionsErrorKey] = options
        }

        if let attempter = self.recoveryAttempter {
            userInfo[NSRecoveryAttempterErrorKey] = attempter
        }

        if let anchor = self.helpAnchor {
            userInfo[NSHelpAnchorErrorKey] = anchor
        }

        if let underlying = underlying {
            userInfo[NSUnderlyingErrorKey] = underlying
        }

        if let path = self.pathString {
            userInfo[NSFilePathErrorKey] = path
            userInfo[NSURLErrorKey] = URL(fileURLWithPath: path)
        }

        if let custom = custom {
            for (key, value) in custom {
                userInfo[key] = value
            }
        }

        return userInfo
    }

    public var url: URL? {
        if let url = self.custom?[NSURLErrorKey] as? URL {
            return url
        }

        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, macCatalyst 16.1, *),
           let path = self.path, let url = URL(filePath: path) {
            return url
        } else if let path = self.pathString {
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    public var stringEncoding: String.Encoding? {
        guard let rawEncoding = self.custom?[NSStringEncodingErrorKey] as? UInt else { return nil }

        return String.Encoding(rawValue: rawEncoding)
    }
}
