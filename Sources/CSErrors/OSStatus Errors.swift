//
//  OSStatus Errors.swift
//
//
//  Created by Charles Srstka on 1/10/23.
//

import System

#if canImport(Darwin)
import Darwin

extension Error {
    /// Convert an error to an `OSStatus`, if it is backed by one.
    public func toOSStatus() -> OSStatus? {
        if let err = self as? OSStatusError {
            return err.rawValue
        }

        if self._domain == OSStatusError.osStatusErrorDomain {
            return OSStatus(self._code)
        }

        return nil
    }
}

public struct OSStatusError: Error {
    package struct Codes {
        // Some OSStatus codes that we use elsewhere in this package.
        package static let kPOSIXErrorBase: Int32 = 100000
        package static let unimpErr: Int32 = -4
        package static let ioErr: Int32 = -36
        package static let eofErr: Int32 = -39
        package static let fnfErr: Int32 = -43
        package static let userCanceledErr: Int32 = -128
        package static let errAEWaitCanceled: Int32 = -1711
        package static let kernelCanceledErr: Int32 = -2402
        package static let kOTCanceledErr: Int32 = -3180
        package static let kEPERMErr: Int32 = -3200
        package static let kENOENTErr: Int32 = -3201
        package static let kEACCESErr: Int32 = -3212
        package static let kEINVALErr: Int32 = -3221
        package static let kECANCELErr: Int32 = -3273
        package static let coreFoundationUnknownErr = -4960
        package static let afpAccessDenied: Int32 = -5000
        package static let errIACanceled: Int32 = -5385
        package static let kRAConnectionCanceled: Int32 = -7109
        package static let kTXNUserCanceledOperationErr: Int32 = -22004
        package static let kFBCindexingCanceled: Int32 = -30520
        package static let kFBCaccessCanceled: Int32 = -30521
        package static let kFBCsummarizationCanceled: Int32 = -30529

        package static let fileNotFoundErrors: [Int32] = [Self.fnfErr, Self.kENOENTErr]
        package static let permissionErrors: [Int32] = [Self.afpAccessDenied, Self.kEPERMErr, Self.kEACCESErr]
        package static let cancelErrors: [Int32] = [
            Self.userCanceledErr,
            Self.errAEWaitCanceled,
            Self.kernelCanceledErr,
            Self.kOTCanceledErr,
            Self.kECANCELErr,
            Self.errIACanceled,
            Self.kRAConnectionCanceled,
            Self.kTXNUserCanceledOperationErr,
            Self.kFBCindexingCanceled,
            Self.kFBCaccessCanceled,
            Self.kFBCsummarizationCanceled
        ]
    }

    public static var osStatusErrorDomain: String { "NSOSStatusErrorDomain" }

    public let rawValue: OSStatus
    public let metadata: ErrorMetadata

    public var _domain: String { Self.osStatusErrorDomain }
    public var _code: Int { Int(self.rawValue) }

    package init(rawValue: OSStatus, metadata _metadata: ErrorMetadata = ErrorMetadata()) {
        var metadata = _metadata

        if let reason = (OSStatusError.self as? _CSErrorsOSStatusInternal.Type)?.getFailureReason(rawValue) {
            metadata.failureReason = reason
        }

        self.rawValue = rawValue
        self.metadata = metadata
    }
}

/// Create an `Error` from an `OSStatus`.
///
/// - Parameters:
///     - osStatus: The `OSStatus` error code to convert to an `Error`.
///     - description: A localized message describing what error occurred.
///         Corresponds to `NSLocalizedDescriptionKey` in the `userInfo` dictionary.
///         If provided, this value will be returned by the `localizedDescription` method.
///     - recoverySuggestion: A localized message describing how one might recover from the failure.
///         Corresponds to `NSLocalizedRecoverySuggestionErrorKey` in the `userInfo` dictionary.
///     - recoveryOptions: A localized message providing “help” text if the user requests help.
///         Corresponds to `NSLocalizedRecoveryOptionsErrorKey` in the `userInfo` dictionary.
///     - recoveryAttempter: An object that conforms to the `NSErrorRecoveryAttempting` informal protocol.
///         Corresponds to `NSRecoveryAttempterErrorKey` in the `userInfo` dictionary.
///     - helpAnchor: A string to display in response to an alert panel help anchor button being pressed.
///         Corresponds to `NSHelpAnchorErrorKey` in the `userInfo` dictionary.
///     - path: A path associated with the error. Corresponds to `NSFilePathErrorKey` in the `userInfo` dictionary.
///         This is very useful for customizing the  error's `localizedDescription` based on the associated filename.
///     - underlying: The underlying error which caused this error, if any. Corresponds to `NSUnderlyingErrorKey`
///         in the `userInfo` dictionary.
///     - custom: A dictionary containing additional key-value pairs to insert in the `userInfo` dictionary.
/// - Returns: An `Error` wrapping the `OSStatus`.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
public func osStatusError(
    _ osStatus: OSStatus,
    description: String? = nil,
    isWrite: Bool = false,
    recoverySuggestion: String? = nil,
    recoveryOptions: [String]? = nil,
    recoveryAttempter: (any Sendable)? = nil,
    helpAnchor: String? = nil,
    path: FilePath,
    underlying: (any Error)? = nil,
    custom: [String: any Sendable]? = nil
) -> any Error {
    if let err = translateOSStatusToPOSIX(osStatus) {
        return errno(err, path: path, isWrite: isWrite)
    }

    let metadata = ErrorMetadata(
        description: description,
        recoverySuggestion: recoverySuggestion,
        recoveryOptions: recoveryOptions,
        recoveryAttempter: recoveryAttempter,
        helpAnchor: helpAnchor,
        path: path,
        underlying: underlying,
        custom: custom
    )

    return OSStatusError(rawValue: osStatus, metadata: metadata)
}

/// Create an `Error` from an `OSStatus`.
///
/// - Parameters:
///     - osStatus: The `OSStatus` error code to convert to an `Error`.
///     - description: A localized message describing what error occurred.
///         Corresponds to `NSLocalizedDescriptionKey` in the `userInfo` dictionary.
///         If provided, this value will be returned by the `localizedDescription` method.
///     - recoverySuggestion: A localized message describing how one might recover from the failure.
///         Corresponds to `NSLocalizedRecoverySuggestionErrorKey` in the `userInfo` dictionary.
///     - recoveryOptions: A localized message providing “help” text if the user requests help.
///         Corresponds to `NSLocalizedRecoveryOptionsErrorKey` in the `userInfo` dictionary.
///     - recoveryAttempter: An object that conforms to the `NSErrorRecoveryAttempting` informal protocol.
///         Corresponds to `NSRecoveryAttempterErrorKey` in the `userInfo` dictionary.
///     - helpAnchor: A string to display in response to an alert panel help anchor button being pressed.
///         Corresponds to `NSHelpAnchorErrorKey` in the `userInfo` dictionary.
///     - path: A path associated with the error. Corresponds to `NSFilePathErrorKey` in the `userInfo` dictionary.
///         This is very useful for customizing the  error's `localizedDescription` based on the associated filename.
///     - underlying: The underlying error which caused this error, if any. Corresponds to `NSUnderlyingErrorKey`
///         in the `userInfo` dictionary.
///     - custom: A dictionary containing additional key-value pairs to insert in the `userInfo` dictionary.
/// - Returns: An `Error` wrapping the `OSStatus`.
public func osStatusError(
    _ osStatus: OSStatus,
    description: String? = nil,
    isWrite: Bool = false,
    recoverySuggestion: String? = nil,
    recoveryOptions: [String]? = nil,
    recoveryAttempter: (any Sendable)? = nil,
    helpAnchor: String? = nil,
    path: String? = nil,
    underlying: (any Error)? = nil,
    custom: [String: any Sendable]? = nil
) -> any Error {
    if let err = translateOSStatusToPOSIX(osStatus) {
        return errno(err, path: path, isWrite: isWrite)
    }

    let metadata = ErrorMetadata(
        description: description,
        recoverySuggestion: recoverySuggestion,
        recoveryOptions: recoveryOptions,
        recoveryAttempter: recoveryAttempter,
        helpAnchor: helpAnchor,
        path: path,
        underlying: underlying,
        custom: custom
    )

    return OSStatusError(rawValue: OSStatus(osStatus), metadata: metadata)
}

internal func translateOSStatusToPOSIX(_ code: some BinaryInteger) -> Int32? {
    let osStatus = OSStatus(code)
    
    if ((OSStatusError.Codes.kPOSIXErrorBase + 1)..<(OSStatusError.Codes.kPOSIXErrorBase + 1000)).contains(osStatus) {
        return osStatus - OSStatusError.Codes.kPOSIXErrorBase
    }

    return nil
}

/// Call an API that returns an OSStatus, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - path: A path to a file associated with this operation.
///     - customErrorUserInfo: Custom user info to attach to an error, if one occurs.
///     - closure: A closure which returns an `OSStatus` as its result code.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
public func callOSStatusAPI(
    errorDescription: String? = nil,
    path: FilePath,
    customErrorUserInfo: [String : any Sendable]? = nil,
    closure: () -> OSStatus
) throws {
    let err = closure()

    guard err == noErr else {
        throw osStatusError(err, description: errorDescription, path: path, custom: customErrorUserInfo)
    }
}

/// Call an API that returns an OSStatus, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - path: A path to a file associated with this operation.
///     - closure: A closure which returns an `OSStatus` as its result code.
public func callOSStatusAPI(
    errorDescription: String? = nil,
    path: String? = nil,
    customErrorUserInfo: [String : any Sendable]? = nil,
    closure: () -> OSStatus
) throws {
    let err = closure()

    guard err == noErr else {
        throw osStatusError(err, description: errorDescription, path: path, custom: customErrorUserInfo)
    }
}

/// Call an API that returns an `OSStatus` and returns a value by reference, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - path: A path to a file associated with this operation.
///     - closure: A closure which returns an `OSStatus` as its result code.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
public func callOSStatusAPI<T: Numeric>(
    errorDescription: String? = nil,
    path: FilePath,
    customErrorUserInfo: [String : any Sendable]? = nil,
    closure: (UnsafeMutablePointer<T>) -> OSStatus
) throws -> T {
    var ret = 0 as T
    let err = closure(&ret)

    guard err == noErr else {
        throw osStatusError(err, description: errorDescription, path: path, custom: customErrorUserInfo)
    }

    return ret
}

/// Call an API that returns an `OSStatus` and returns a value by reference, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - path: A path to a file associated with this operation.
///     - closure: A closure which returns an `OSStatus` as its result code.
public func callOSStatusAPI<T: Numeric>(
    errorDescription: String? = nil,
    path: String? = nil,
    customErrorUserInfo: [String : any Sendable]? = nil,
    closure: (UnsafeMutablePointer<T>) -> OSStatus
) throws -> T {
    var ret = 0 as T
    let err = closure(&ret)

    guard err == noErr else {
        throw osStatusError(err, description: errorDescription, path: path, custom: customErrorUserInfo)
    }

    return ret
}

/// Call an API that returns an `OSStatus` and returns a value by reference, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - path: A path to a file associated with this operation.
///     - closure: A closure which returns an `OSStatus` as its result code.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
public func callOSStatusAPI<T>(
    errorDescription: String? = nil,
    path: FilePath,
    customErrorUserInfo: [String : any Sendable]? = nil,
    closure: (UnsafeMutablePointer<T?>) -> OSStatus
) throws -> T {
    var ret: T? = nil
    let err = closure(&ret)

    guard err == noErr, let ret = ret else {
        throw osStatusError(
            err != noErr ? err : OSStatus(OSStatusError.Codes.coreFoundationUnknownErr),
            description: errorDescription,
            path: path,
            custom: customErrorUserInfo
        )
    }

    return ret
}

/// Call an API that returns an `OSStatus` and returns a value by reference, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - path: A path to a file associated with this operation.
///     - closure: A closure which returns an `OSStatus` as its result code.
public func callOSStatusAPI<T>(
    errorDescription: String? = nil,
    path: String? = nil,
    closure: (UnsafeMutablePointer<T?>) -> OSStatus
) throws -> T {
    var ret: T? = nil
    let err = closure(&ret)

    guard err == noErr, let ret = ret else {
        throw osStatusError(
            err != noErr ? err : OSStatus(OSStatusError.Codes.coreFoundationUnknownErr),
            description: errorDescription,
            path: path
        )
    }

    return ret
}

package protocol _CSErrorsOSStatusInternal {
    static func getFailureReason(_ osStatus: OSStatus) -> String?
}

#endif
