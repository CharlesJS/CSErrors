//
//  OSStatus Errors.swift
//
//
//  Created by Charles Srstka on 1/10/23.
//

import System

#if canImport(Darwin)
import Darwin

#if Foundation
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

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
    internal struct Codes {
        // Some OSStatus codes that we use elsewhere in this package.
        internal static let kPOSIXErrorBase: Int32 = 100000
        internal static let unimpErr: Int32 = -4
        internal static let ioErr: Int32 = -36
        internal static let eofErr: Int32 = -39
        internal static let fnfErr: Int32 = -43
        internal static let userCanceledErr: Int32 = -128
        internal static let errAEWaitCanceled: Int32 = -1711
        internal static let kernelCanceledErr: Int32 = -2402
        internal static let kOTCanceledErr: Int32 = -3180
        internal static let kEPERMErr: Int32 = -3200
        internal static let kENOENTErr: Int32 = -3201
        internal static let kEACCESErr: Int32 = -3212
        internal static let kEINVALErr: Int32 = -3221
        internal static let kECANCELErr: Int32 = -3273
        internal static let coreFoundationUnknownErr = -4960
        internal static let afpAccessDenied: Int32 = -5000
        internal static let errIACanceled: Int32 = -5385
        internal static let kRAConnectionCanceled: Int32 = -7109
        internal static let kTXNUserCanceledOperationErr: Int32 = -22004
        internal static let kFBCindexingCanceled: Int32 = -30520
        internal static let kFBCaccessCanceled: Int32 = -30521
        internal static let kFBCsummarizationCanceled: Int32 = -30529

        internal static let fileNotFoundErrors: [Int32] = [Self.fnfErr, Self.kENOENTErr]
        internal static let permissionErrors: [Int32] = [Self.afpAccessDenied, Self.kEPERMErr, Self.kEACCESErr]
        internal static let cancelErrors: [Int32] = [
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

    internal init(rawValue: OSStatus, metadata _metadata: ErrorMetadata = ErrorMetadata()) {
        var metadata = _metadata

#if Foundation
        if let reason = OSStatusError.getFailureReason(rawValue) {
            metadata.failureReason = reason
        }
#endif

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

#if Foundation

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
///     - stringEncoding: The string encoding associated with this error, if any.
///         Corresponds to `NSStringEncodingErrorKey` in the `userInfo` dictionary.
///     - url: A URL associated with the error. Corresponds to `NSURLErrorKey` in the `userInfo` dictionary.
///         If the URL is a `file` URL, this also sets `NSFilePathErrorKey` in the `userInfo` dictionary,
///         which is very useful for customizing the  error's `localizedDescription` based on the associated filename.
///     - underlying: The underlying error which caused this error, if any. Corresponds to `NSUnderlyingErrorKey`
///         in the `userInfo` dictionary.
///     - custom: A dictionary containing additional key-value pairs to insert in the `userInfo` dictionary.
/// - Returns: An `Error` representing the `OSStatus`.
public func osStatusError(
    _ osStatus: OSStatus,
    description: String? = nil,
    recoverySuggestion: String? = nil,
    recoveryOptions: [String]? = nil,
    recoveryAttempter: (any Sendable)? = nil,
    helpAnchor: String? = nil,
    stringEncoding: String.Encoding? = nil,
    url: URL?,
    underlying: (any Error)? = nil,
    custom: [String: any Sendable]? = nil
) -> any Error {
    let metadata = ErrorMetadata(
        description: description,
        recoverySuggestion: recoverySuggestion,
        recoveryOptions: recoveryOptions,
        recoveryAttempter: recoveryAttempter,
        helpAnchor: helpAnchor,
        stringEncoding: stringEncoding,
        url: url,
        underlying: underlying,
        custom: custom
    )

    let err = OSStatusError(rawValue: osStatus, metadata: metadata)

    if let posixErr = err.toErrno() {
        return errno(posixErr)
    }

    return err
}

#endif

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

#if Foundation

/// Call an API that returns an OSStatus, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - url: The URL of a file associated with this operation.
///     - customErrorUserInfo: Custom user info to attach to an error, if one occurs.
///     - closure: A closure which returns an `OSStatus` as its result code.
public func callOSStatusAPI(
    errorDescription: String? = nil,
    url: URL?,
    custom customErrorUserInfo: [String : any Sendable]? = nil,
    closure: () -> OSStatus
) throws {
    let err = closure()

    guard err == noErr else {
        throw osStatusError(err, description: errorDescription, url: url, custom: customErrorUserInfo)
    }
}

/// Call an API that returns an `OSStatus` and returns a value by reference, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - url: The URL of a file associated with this operation.
///     - customErrorUserInfo: Custom user info to attach to an error, if one occurs.
///     - closure: A closure which returns an `OSStatus` as its result code.
public func callOSStatusAPI<T>(
    errorDescription: String? = nil,
    url: URL? = nil,
    customErrorUserInfo: [String : any Sendable]? = nil,
    closure: (UnsafeMutablePointer<T>) -> OSStatus
) throws -> T {
    let ptr = UnsafeMutablePointer<T>.allocate(capacity: 1)
    defer { ptr.deallocate() }

    let err = closure(ptr)

    guard err == noErr else {
        throw osStatusError(err, description: errorDescription, url: url, custom: customErrorUserInfo)
    }

    return ptr.pointee
}

/// Call an API that returns an `OSStatus` and returns a value by reference, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - url: The URL of a file associated with this operation.
///     - customErrorUserInfo: Custom user info to attach to an error, if one occurs.
///     - closure: A closure which returns an `OSStatus` as its result code.
public func callOSStatusAPI<T>(
    errorDescription: String? = nil,
    url: URL? = nil,
    customErrorUserInfo: [String : any Sendable]? = nil,
    closure: (UnsafeMutablePointer<T?>) -> OSStatus
) throws -> T {
    var ret: T? = nil
    let err = closure(&ret)

    guard err == noErr, let ret = ret else {
        throw osStatusError(
            err != noErr ? err : OSStatus(OSStatusError.Codes.coreFoundationUnknownErr),
            description: errorDescription,
            url: url,
            custom: customErrorUserInfo
        )
    }

    return ret
}

extension OSStatusError {
    internal static func getFailureReason(_ osStatus: OSStatus) -> String? {
        SecCopyErrorMessageString(osStatus, nil) as String?
    }

    public static var errorDomain: String { NSOSStatusErrorDomain }
    public var errorCode: Int { Int(self.rawValue) }
    public var errorUserInfo: [String : Any] { self.metadata.toUserInfo() }
}

extension OSStatusError: CustomNSError {}

#endif

#endif
