//
//  NSError+CSErrors.swift
//
//
//  Created by Charles Srstka on 11/11/23.
//

import CSErrors
import Foundation
import System

extension NSError {
    package func toCSErrorProtocol() -> (CSErrorProtocol)? {
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

#if compiler(>=6)
extension NSError: @retroactive CSNSErrorProtocol {}
#else
extension NSError: CSNSErrorProtocol {}
#endif
