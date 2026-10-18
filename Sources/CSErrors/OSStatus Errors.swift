//
//  OSStatus Errors.swift
//
//
//  Created by Charles Srstka on 1/10/23.
//

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

#if canImport(Darwin)
import Darwin
#else
#if canImport(Glibc)
import Glibc
#endif
public typealias OSStatus = Int32
#endif

#if Foundation
#if canImport(FoundationEssentials)
import FoundationEssentials
private let NSOSStatusErrorDomain = "NSOSStatusErrorDomain"
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
        internal static let noErr: OSStatus = 0
        internal static let kPOSIXErrorBase: OSStatus = 100000
        internal static let unimpErr: OSStatus = -4
        internal static let ioErr: OSStatus = -36
        internal static let eofErr: OSStatus = -39
        internal static let fnfErr: OSStatus = -43
        internal static let userCanceledErr: OSStatus = -128
        internal static let errAEWaitCanceled: OSStatus = -1711
        internal static let kernelCanceledErr: OSStatus = -2402
        internal static let kOTCanceledErr: OSStatus = -3180
        internal static let kEPERMErr: OSStatus = -3200
        internal static let kENOENTErr: OSStatus = -3201
        internal static let kEACCESErr: OSStatus = -3212
        internal static let kEINVALErr: OSStatus = -3221
        internal static let kECANCELErr: OSStatus = -3273
        internal static let coreFoundationUnknownErr = -4960
        internal static let afpAccessDenied: OSStatus = -5000
        internal static let errIACanceled: OSStatus = -5385
        internal static let kRAConnectionCanceled: OSStatus = -7109
        internal static let kTXNUserCanceledOperationErr: OSStatus = -22004
        internal static let kFBCindexingCanceled: OSStatus = -30520
        internal static let kFBCaccessCanceled: OSStatus = -30521
        internal static let kFBCsummarizationCanceled: OSStatus = -30529

        internal static let fileNotFoundErrors: [OSStatus] = [Self.fnfErr, Self.kENOENTErr]
        internal static let permissionErrors: [OSStatus] = [Self.afpAccessDenied, Self.kEPERMErr, Self.kEACCESErr]
        internal static let cancelErrors: [OSStatus] = [
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

#if !canImport(Darwin)
    // kPOSIXError* codes assume Darwin sys/errno.h, which can vary on other platforms

    switch osStatus {
        case 100001: return EPERM
        case 100002: return ENOENT
        case 100003: return ESRCH
        case 100004: return EINTR
        case 100005: return EIO
        case 100006: return ENXIO
        case 100007: return E2BIG
        case 100008: return ENOEXEC
        case 100009: return EBADF
        case 100010: return ECHILD
        case 100011: return EDEADLK
        case 100012: return ENOMEM
        case 100013: return EACCES
        case 100014: return EFAULT
        case 100015: return ENOTBLK
        case 100016: return EBUSY
        case 100017: return EEXIST
        case 100018: return EXDEV
        case 100019: return ENODEV
        case 100020: return ENOTDIR
        case 100021: return EISDIR
        case 100022: return EINVAL
        case 100023: return ENFILE
        case 100024: return EMFILE
        case 100025: return ENOTTY
        case 100026: return ETXTBSY
        case 100027: return EFBIG
        case 100028: return ENOSPC
        case 100029: return ESPIPE
        case 100030: return EROFS
        case 100031: return EMLINK
        case 100032: return EPIPE
        case 100033: return EDOM
        case 100034: return ERANGE
        case 100035: return EAGAIN
        case 100036: return EINPROGRESS
        case 100037: return EALREADY
        case 100038: return ENOTSOCK
        case 100039: return EDESTADDRREQ
        case 100040: return EMSGSIZE
        case 100041: return EPROTOTYPE
        case 100042: return ENOPROTOOPT
        case 100043: return EPROTONOSUPPORT
        case 100044: return ESOCKTNOSUPPORT
        case 100045: return ENOTSUP
        case 100046: return EPFNOSUPPORT
        case 100047: return EAFNOSUPPORT
        case 100048: return EADDRINUSE
        case 100049: return EADDRNOTAVAIL
        case 100050: return ENETDOWN
        case 100051: return ENETUNREACH
        case 100052: return ENETRESET
        case 100053: return ECONNABORTED
        case 100054: return ECONNRESET
        case 100055: return ENOBUFS
        case 100056: return EISCONN
        case 100057: return ENOTCONN
        case 100058: return ESHUTDOWN
        case 100059: return ETOOMANYREFS
        case 100060: return ETIMEDOUT
        case 100061: return ECONNREFUSED
        case 100062: return ELOOP
        case 100063: return ENAMETOOLONG
        case 100064: return EHOSTDOWN
        case 100065: return EHOSTUNREACH
        case 100066: return ENOTEMPTY
        case 100068: return EUSERS
        case 100069: return EDQUOT
        case 100070: return ESTALE
        case 100071: return EREMOTE
        case 100077: return ENOLCK
        case 100078: return ENOSYS
        case 100084: return EOVERFLOW
        case 100089: return ECANCELED
        case 100090: return EIDRM
        case 100091: return ENOMSG
        case 100092: return EILSEQ
        case 100094: return EBADMSG
        case 100095: return EMULTIHOP
        case 100096: return ENODATA
        case 100097: return ENOLINK
        case 100098: return ENOSR
        case 100099: return ENOSTR
        case 100100: return EPROTO
        case 100101: return ETIME
        case 100102: return EOPNOTSUPP
    default: break
    }
#endif

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

    guard err == OSStatusError.Codes.noErr else {
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

    guard err == OSStatusError.Codes.noErr else {
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

    guard err == OSStatusError.Codes.noErr else {
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

    guard err == OSStatusError.Codes.noErr else {
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

    guard err == OSStatusError.Codes.noErr, let ret = ret else {
        throw osStatusError(
            err != OSStatusError.Codes.noErr ? err : OSStatus(OSStatusError.Codes.coreFoundationUnknownErr),
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

    guard err == OSStatusError.Codes.noErr, let ret = ret else {
        throw osStatusError(
            err != OSStatusError.Codes.noErr ? err : OSStatus(OSStatusError.Codes.coreFoundationUnknownErr),
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

    guard err == OSStatusError.Codes.noErr else {
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

    guard err == OSStatusError.Codes.noErr else {
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

    guard err == OSStatusError.Codes.noErr, let ret = ret else {
        throw osStatusError(
            err != OSStatusError.Codes.noErr ? err : OSStatus(OSStatusError.Codes.coreFoundationUnknownErr),
            description: errorDescription,
            url: url,
            custom: customErrorUserInfo
        )
    }

    return ret
}

extension OSStatusError {
    internal static func getFailureReason(_ osStatus: OSStatus) -> String? {
#if canImport(Darwin)
        SecCopyErrorMessageString(osStatus, nil) as String?
#else
        nil
#endif
    }

    public static var errorDomain: String { NSOSStatusErrorDomain }
    public var errorCode: Int { Int(self.rawValue) }
    public var errorUserInfo: [String : Any] { self.metadata.toUserInfo() }
}

#if canImport(Darwin)
extension OSStatusError: CustomNSError {}
#endif

#endif
