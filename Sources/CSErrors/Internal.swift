//
//  Internal.swift
//  
//
//  Created by Charles Srstka on 1/11/23.
//

#if DEBUG
// All of these functions are to be used during testing only!
func emulateMacOSVersion(_ vers: Int, closure: () throws -> ()) rethrows {
    defer { emulatedVersion = Int.max }
    emulatedVersion = vers

    try closure()
}

func allowFailure(closure: () throws -> Void) rethrows -> String? {
    defer { bypassFail = false }
    defer { failMessage = nil }
    bypassFail = true

    try closure()
    return failMessage
}

private var bypassFail = false
private var failMessage: String? = nil

private var emulatedVersion = Int.max
@_spi(CSErrorsInternal) public func versionCheck(_ vers: Int) -> Bool { emulatedVersion >= vers }
internal func fail(_ reason: String) -> String {
    precondition(bypassFail)

    failMessage = reason
    return reason
}
#else
@inline(__always) @_spi(CSErrorsInternal) public func versionCheck(_ vers: Int) -> Bool { true }
internal func fail(_ reason: String) -> String { fatalError(reason) }
#endif

internal let cocoaErrorDomain = "NSCocoaErrorDomain"

internal struct GenericError: Error {
    static func unknownError(isWrite: Bool) -> GenericError {
        GenericError(_domain: cocoaErrorDomain, _code: isWrite ? 512 : 256)
    }

    let _domain: String
    let _code: Int
}
