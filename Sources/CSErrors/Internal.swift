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

private var emulatedVersion = Int.max
package func versionCheck(_ vers: Int) -> Bool { emulatedVersion >= vers }
#else
@inline(__always) package func versionCheck(_ vers: Int) -> Bool { true }
#endif

internal let cocoaErrorDomain = "NSCocoaErrorDomain"

package protocol CSNSErrorProtocol {
    func toCSErrorProtocol() -> (any CSErrorProtocol)?
}

internal struct GenericError: Error {
    static func unknownError(isWrite: Bool) -> GenericError {
        GenericError(_domain: cocoaErrorDomain, _code: isWrite ? 512 : 256)
    }

    let _domain: String
    let _code: Int

    var domain: String { self._domain }
    var code: Int { self._code }
}
