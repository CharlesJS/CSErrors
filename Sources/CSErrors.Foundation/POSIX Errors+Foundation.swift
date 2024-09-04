//
//  POSIX Errors+Foundation.swift
//  
//
//  Created by Charles Srstka on 1/11/23.
//

import Foundation
import System
import CSErrors

public func errno(_ code: Int32 = Foundation.errno, url: URL?, isWrite: Bool = false) -> any Error {
    if code == 0 {
        return CocoaError(isWrite ? .fileWriteUnknown : .fileReadUnknown)
    }

    let cocoaCode = cocoaCode(posixCode: code, isWrite: isWrite)
    let err: any Error

    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *), versionCheck(11) {
        err = System.Errno(rawValue: code)
    } else if let posixCode = POSIXErrorCode(rawValue: code) {
        err = POSIXError(posixCode)
    } else {
        err = NSError(domain: NSPOSIXErrorDomain, code: Int(code))
    }

    if err.isCancelledError {
        return CocoaError(.userCancelled, url: url, underlying: err)
    }

    if let cocoaCode {
        return CocoaError(cocoaCode, url: url, underlying: err)
    }

    return err
}

public func callPOSIXFunction<I: BinaryInteger>(
    expect expectedReturn: POSIXReturnExpectation<I>,
    errorFrom errorReturn: POSIXErrorReturn = .globalErrno,
    url: URL,
    isWrite: Bool = false,
    closure: () -> I
) throws {
    let (err, isError) = _callPOSIXFunction(expect: expectedReturn, errorFrom: errorReturn, closure: closure)
    if isError {
        throw errno(Int32(err), url: url, isWrite: isWrite)
    }
}

public func callPOSIXFunction<T, I: BinaryInteger>(
    expect: POSIXReturnExpectation<I>,
    errorFrom: POSIXErrorReturn = .globalErrno,
    url: URL,
    isWrite: Bool = false,
    closure: (UnsafeMutablePointer<T>) -> I
) throws -> T {
    try callPOSIXFunction(expect: expect, errorFrom: errorFrom, path: url.path, isWrite: isWrite, closure: closure)
}

public func callPOSIXFunction<T>(url: URL, closure: () -> UnsafeMutablePointer<T>?) throws -> UnsafeMutablePointer<T> {
    try callPOSIXFunction(path: url.path, closure: closure)
}

public func callPOSIXFunction(url: URL, closure: () -> UnsafeMutableRawPointer?) throws -> UnsafeMutableRawPointer {
    try callPOSIXFunction(path: url.path, closure: closure)
}

public func callPOSIXFunction(url: URL, closure: () -> OpaquePointer?) throws -> OpaquePointer {
    try callPOSIXFunction(path: url.path, closure: closure)
}

private func cocoaCode(posixCode: Int32, isWrite: Bool) -> CocoaError.Code? {
    switch posixCode {
    case EPERM, EACCES:
        return isWrite ? .fileWriteNoPermission : .fileReadNoPermission
    case ENOENT:
        return isWrite ? .fileNoSuchFile : .fileReadNoSuchFile
    case EEXIST:
        return .fileWriteFileExists
    case EFBIG:
        return .fileReadTooLarge
    case ENOSPC:
        return .fileWriteOutOfSpace
    case EROFS:
        return .fileWriteVolumeReadOnly
    case EFTYPE:
        return .fileReadCorruptFile
    case ECANCELED:
        return .userCancelled
    default:
        return nil
    }
}

extension POSIXConnector {
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
    package func translateErrno(_ code: Int32, path: FilePath, isWrite: Bool) -> any Error {
        guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *), versionCheck(12) else {
            return self.translateErrno(code, path: String(decoding: path), isWrite: isWrite)
        }

        guard #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, macCatalyst 16.1, *), versionCheck(13) else {
            return self.translateErrno(code, path: path.string, isWrite: isWrite)
        }

        return errno(code, url: URL(filePath: path), isWrite: isWrite)
    }

    package func translateErrno(_ code: Int32, path: String?, isWrite: Bool) -> any Error {
        let url: URL?

        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, macCatalyst 16.0, *), versionCheck(13) {
            url = path.flatMap { URL(filePath: $0) }
        } else {
            url = path.map { URL(fileURLWithPath: $0) }
        }

        return errno(code, url: url, isWrite: isWrite)
    }
}

#if compiler(>=6)
extension POSIXConnector: @retroactive _CSErrorsPOSIXErrorInternal {}
#else
extension POSIXConnector: _CSErrorsPOSIXErrorInternal {}
#endif
