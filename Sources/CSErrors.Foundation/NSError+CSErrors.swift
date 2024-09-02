//
//  NSError+CSErrors.swift
//
//
//  Created by Charles Srstka on 11/11/23.
//

import CSErrors
import Foundation
import System

extension NSError: @retroactive CSNSErrorProtocol {
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
