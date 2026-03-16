//
//  NSError+CSErrors.swift
//
//
//  Created by Charles Srstka on 11/11/23.
//

#if Foundation && canImport(Darwin)

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import System

extension NSError {
    internal func toCSErrorProtocol() -> (any CSErrorProtocol)? {
        switch self.domain {
        case NSCocoaErrorDomain:
            return self as? CocoaError
        case NSURLErrorDomain:
            return self as? URLError
        default:
            return nil
        }
    }
}

#endif
