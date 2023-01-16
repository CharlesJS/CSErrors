//
//  Internal.swift
//  
//
//  Created by Charles Srstka on 1/11/23.
//

internal let cocoaErrorDomain = "NSCocoaErrorDomain"

internal struct GenericError: Error {
    static func unknownError(isWrite: Bool) -> GenericError {
        GenericError(_domain: cocoaErrorDomain, _code: isWrite ? 512 : 256)
    }

    let _domain: String
    let _code: Int
}
