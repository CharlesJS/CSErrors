//
//  POSIX Errors+Foundation.swift
//  
//
//  Created by Charles Srstka on 1/11/23.
//

import Foundation
import System
@_spi(CSErrorsInternal) import CSErrors

public func errno(_ code: Int32 = Foundation.errno, url: URL?, isWrite: Bool = false) -> any Error {
    if code == 0 {
        return CocoaError(isWrite ? .fileWriteUnknown : .fileReadUnknown)
    }

    let cocoaCode = cocoaCode(posixCode: code, isWrite: isWrite)
    let err: any Error

    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *) {
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

public func callPOSIXFunction(
    expect expectedReturn: POSIXReturnExpectation,
    errorFrom errorReturn: POSIXErrorReturn = .globalErrno,
    url: URL,
    isWrite: Bool = false,
    closure: () -> Int32
) throws {
    let (err, isError) = _callPOSIXFunction(expect: expectedReturn, errorFrom: errorReturn, closure: closure)
    if isError {
        throw errno(err, url: url, isWrite: isWrite)
    }
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

@_spi(CSErrorsInternal) extension POSIXConnector: _CSErrorsPOSIXErrorInternal {
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
    public func translateErrno(_ code: Int32, path: FilePath, isWrite: Bool) -> any Error {
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, macCatalyst 16.1, *) {
            return errno(code, url: URL(filePath: path), isWrite: isWrite)
        } else if #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *) {
            return self.translateErrno(code, path: path.string, isWrite: isWrite)
        } else {
            return self.translateErrno(code, path: String(decoding: path), isWrite: isWrite)
        }
    }

    public func translateErrno(_ code: Int32, path: String?, isWrite: Bool) -> any Error {
        let url: URL?

        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, macCatalyst 16.0, *) {
            url = path.flatMap { URL(filePath: $0) }
        } else {
            url = path.map { URL(fileURLWithPath: $0) }
        }

        return errno(code, url: url, isWrite: isWrite)
    }
}

