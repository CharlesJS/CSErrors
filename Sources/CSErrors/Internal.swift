//
//  Internal.swift
//  
//
//  Created by Charles Srstka on 1/11/23.
//

#if DEBUG
// All of these functions are to be used during testing only!
func emulateMacOSVersion(_ vers: Int, closure: () throws -> ()) rethrows {
    try emulatedVersion.withValue(vers) {
        try closure()
    }
}

private let emulatedVersion = TaskLocal(wrappedValue: Int.max)
internal func versionCheck(_ vers: Int) -> Bool { emulatedVersion.get() >= vers }
#else
@inline(__always) internal func versionCheck(_ vers: Int) -> Bool { true }
#endif

internal let cocoaErrorDomain = "NSCocoaErrorDomain"

internal struct GenericError: Error {
    static func unknownError(isWrite: Bool) -> GenericError {
        GenericError(_domain: cocoaErrorDomain, _code: isWrite ? 512 : 256)
    }

    let _domain: String
    let _code: Int

    var domain: String { self._domain }
    var code: Int { self._code }
}
