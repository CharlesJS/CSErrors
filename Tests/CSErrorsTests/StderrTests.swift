//
//  StderrTests.swift
//
//
//  Created by Charles Srstka on 3/12/23.
//

@testable import CSErrors
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(SystemPackage)
import SystemPackage
#else
import System
#endif

@Suite("Stderr Tests", .serialized) struct StderrTests {
    @Test("Print to Stderr")
    func testPrintToStderr() async {
        let result = await #expect(processExitsWith: .success, observing: [\.standardErrorContent]) {
            for eachVersion in [10, 11, 12, 13] {
                emulateMacOSVersion(eachVersion) {
                    printToStderr("Hello")
                    printToStderr("Hello", "World")
                    printToStderr("Hello", terminator: "")
                    printToStderr("Hello", terminator: "!")
                    printToStderr("Hello", "World", separator: "+", terminator: "!")
                }
            }
        }

        let expectedStderr = [10, 11, 12, 13].flatMap { _ in
            "Hello\nHello World\nHelloHello!Hello+World!".data(using: .utf8)!
        }

        #expect(result?.standardErrorContent == expectedStderr)
    }

    @Test("Does not crash when write fails")
    func testDoesNotCrashWhenWriteFails() async {
        await #expect(processExitsWith: .success) {
            for eachVersion in [10, 11, 12, 13] {
                emulateMacOSVersion(eachVersion) {
                    close(STDERR_FILENO)
                    printToStderr("Hello")
                }
            }
        }
    }
}
