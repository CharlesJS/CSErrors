//
//  StderrTests.swift
//  
//
//  Created by Charles Srstka on 3/12/23.
//

@testable import CSErrors
import System
import XCTest

@available(macOS 13, *)
class StderrTests: XCTestCase {
    func testPrintToStderr() throws {
        for eachVersion in [10, 11, 12, 13] {
            emulateMacOSVersion(eachVersion) {
                XCTAssertEqual(captureStderr { printToStderr("Hello") }, "Hello\n")
                XCTAssertEqual(captureStderr { printToStderr("Hello", "World") }, "Hello World\n")
                XCTAssertEqual(captureStderr { printToStderr("Hello", terminator: "") }, "Hello")
                XCTAssertEqual(captureStderr { printToStderr("Hello", terminator: "!") }, "Hello!")
                XCTAssertEqual(
                    captureStderr { printToStderr("Hello", "World", separator: "+", terminator: "!") },
                    "Hello+World!"
                )
            }
        }
    }

    func testDoesNotCrashWhenWriteFails() throws {
        for eachVersion in [10, 11, 12, 13] {
            emulateMacOSVersion(eachVersion) {
                XCTAssertEqual(
                    captureStderr {
                        close(STDERR_FILENO)
                        printToStderr("Hello")
                    },
                    ""
                )
            }
        }
    }

    private func captureStderr(closure: () -> Void) -> String {
        let pipe = Pipe()
        let readHandle = pipe.fileHandleForReading
        let writeHandle = pipe.fileHandleForWriting

        let originalStderr = dup(STDERR_FILENO)

        dup2(writeHandle.fileDescriptor, STDERR_FILENO)

        defer {
            dup2(originalStderr, STDERR_FILENO)
            _ = try? readHandle.close()
            _ = try? writeHandle.close()
        }

        closure()

        let flags = fcntl(readHandle.fileDescriptor, F_GETFL, 0)
        _ = fcntl(readHandle.fileDescriptor, F_SETFL, flags | O_NONBLOCK)

        var data = Data(count: 1000)
        let len = data.withUnsafeMutableBytes {
            read(readHandle.fileDescriptor, $0.baseAddress, $0.count)
        }
        data.count = max(len, 0)

        return String(data: data, encoding: .utf8)!
    }
}
