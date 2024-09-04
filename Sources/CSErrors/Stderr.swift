//
//  Stderr.swift
//  
//
//  Created by Charles Srstka on 3/12/23.
//

import System

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

public struct StandardErrorStream: TextOutputStream {
    public func write(_ string: String) {
        do {
            guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *), versionCheck(12) else {
                try string.withCString {
                    let len = self.lengthOfString($0)
                    try UnsafeBufferPointer(start: $0, count: len).withMemoryRebound(to: UInt8.self) { buf in
                        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *),
                              versionCheck(11) else {
                            fwrite(buf.baseAddress, 1, buf.count, stderr)
                            return
                        }

                        _ = try FileDescriptor.standardError.writeAll(buf)
                    }
                }

                return
            }

            try string.withPlatformString {
                try UnsafeBufferPointer(start: $0, count: self.lengthOfString($0)).withMemoryRebound(to: UInt8.self) {
                    _ = try FileDescriptor.standardError.writeAll($0)
                }
            }
        } catch {}
    }

    private func lengthOfString(_ string: UnsafePointer<some BinaryInteger>) -> Int {
        (0..<Int.max).first { string[$0] == 0 }!
    }
}

public func printToStderr(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    var stream = StandardErrorStream()

    print(items, separator: separator, terminator: terminator, to: &stream)
}
