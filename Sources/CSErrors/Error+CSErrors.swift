//
//  Error+CSErrors.swift
//  CSErrors
//
//  Created by Charles Srstka on 12/27/15.
//

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if Foundation
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

extension Error {
    /// True if the error represents a “File Not Found” error, regardless of domain.
    public var isFileNotFoundError: Bool {
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *), versionCheck(11),
           let errno = self as? Errno, errno == .noSuchFileOrDirectory {
            return true
        }

        if let err = self.toErrno(), err == ENOENT {
            return true
        }

        if let osStatus = self.toOSStatus(), OSStatusError.Codes.fileNotFoundErrors.contains(osStatus) {
            return true
        }

        if let err = self as? any CSErrorProtocol, err.isFileNotFoundError {
            return true
        }

        if let err = self.toCSErrorProtocol(), err.isFileNotFoundError {
            return true
        }

        return false
    }

    /// True if the error represents a permission or access error, regardless of domain.
    public var isPermissionError: Bool {
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *), versionCheck(11),
            let errno = self as? Errno, [.permissionDenied, .notPermitted].contains(errno)
        {
            return true
        }

        if let err = self.toErrno(), [EACCES, EPERM].contains(err) {
            return true
        }

        if let osStatus = self.toOSStatus(), OSStatusError.Codes.permissionErrors.contains(osStatus) {
            return true
        }

        if let err = self as? any CSErrorProtocol, err.isPermissionError {
            return true
        }

        if let err = self.toCSErrorProtocol(), err.isPermissionError {
            return true
        }

        return false
    }

    /// True if the error results from a user cancellation, regardless of domain.
    public var isCancelledError: Bool {
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *), versionCheck(11),
            let errno = self as? Errno, errno == .canceled
        {
            return true
        }

        if let err = self.toErrno(), err == ECANCELED {
            return true
        }
        
        if let err = self.toOSStatus(), OSStatusError.Codes.cancelErrors.contains(err) {
            return true
        }

        if let err = self as? any CSErrorProtocol, err.isCancelledError {
            return true
        }

        if let err = self.toCSErrorProtocol(), err.isCancelledError {
            return true
        }

        return false
    }

    private func toCSErrorProtocol() -> (any CSErrorProtocol)? {
#if Foundation
#if canImport(Darwin)
        (self as NSError).nserrorToCSErrorProtocol()
#else
        switch self._domain {
        case cocoaErrorDomain: CocoaError(CocoaError.Code(rawValue: self._code))
        default: nil
        }
#endif
#else
        nil
#endif
    }
}
