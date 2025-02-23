//
//  Error+CSErrors.swift
//  CSErrors
//
//  Created by Charles Srstka on 12/27/15.
//

import System

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
           let errno = self as? System.Errno, errno == .noSuchFileOrDirectory {
            return true
        }

        if let err = self.toErrno(), err == ENOENT {
            return true
        }

#if canImport(Darwin)
        if let osStatus = self.toOSStatus(), OSStatusError.Codes.fileNotFoundErrors.contains(osStatus) {
            return true
        }
#endif

        if let err = self as? any CSErrorProtocol, err.isFileNotFoundError {
            return true
        }

#if Foundation
        if let err = (self as NSError).toCSErrorProtocol(), err.isFileNotFoundError {
            return true
        }
#endif

        return false
    }

    /// True if the error represents a permission or access error, regardless of domain.
    public var isPermissionError: Bool {
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *), versionCheck(11),
            let errno = self as? System.Errno, [.permissionDenied, .notPermitted].contains(errno)
        {
            return true
        }

        if let err = self.toErrno(), [EACCES, EPERM].contains(err) {
            return true
        }

#if canImport(Darwin)
        if let osStatus = self.toOSStatus(), OSStatusError.Codes.permissionErrors.contains(osStatus) {
            return true
        }
#endif

        if let err = self as? any CSErrorProtocol, err.isPermissionError {
            return true
        }

#if Foundation
        if let err = (self as NSError).toCSErrorProtocol(), err.isPermissionError {
            return true
        }
#endif

        return false
    }

    /// True if the error results from a user cancellation, regardless of domain.
    public var isCancelledError: Bool {
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *), versionCheck(11),
            let errno = self as? System.Errno, errno == .canceled
        {
            return true
        }

        if let err = self.toErrno(), err == ECANCELED {
            return true
        }
        
#if canImport(Darwin)
        if let err = self.toOSStatus(), OSStatusError.Codes.cancelErrors.contains(err) {
            return true
        }
#endif

        if let err = self as? any CSErrorProtocol, err.isCancelledError {
            return true
        }

#if Foundation
        if let err = (self as NSError).toCSErrorProtocol(), err.isCancelledError {
            return true
        }
#endif

        return false
    }
}
