//
//  NSError+CSErrors.swift
//
//
//  Created by Charles Srstka on 11/11/23.
//

#if Foundation && !canImport(FoundationEssentials)
import Foundation

extension NSError {
    internal func nserrorToCSErrorProtocol() -> (any CSErrorProtocol)? {
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
