//
//  OSStatus+Foundation.swift
//
//
//  Created by Charles Srstka on 1/10/23.
//

import Foundation
import CSErrors

#if canImport(Darwin)
import Darwin

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

/// Call an API that returns an OSStatus, throwing an error if it fails.
///
/// - Parameters:
///     - errorDescription: The description of the error, in the case where the API fails.
///     - url: The URL of a file associated with this operation.
///     - customErrorUserInfo: Custom user info to attach to an error, if one occurs.
///     - closure: A closure which returns an `OSStatus` as its result code.
public func callOSStatusAPI(
    errorDescription: String? = nil,
    url: URL? = nil,
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
    package static func getFailureReason(_ osStatus: OSStatus) -> String? {
        SecCopyErrorMessageString(osStatus, nil) as String?
    }

    public static var errorDomain: String { NSOSStatusErrorDomain }
    public var errorCode: Int { Int(self.rawValue) }
    public var errorUserInfo: [String : Any] { self.metadata.toUserInfo() }
}

#if compiler(>=6)
extension OSStatusError: @retroactive _CSErrorsOSStatusInternal {}
extension OSStatusError: @retroactive CustomNSError {}
#else
extension OSStatusError: _CSErrorsOSStatusInternal {}
extension OSStatusError: CustomNSError {}
#endif

#endif
