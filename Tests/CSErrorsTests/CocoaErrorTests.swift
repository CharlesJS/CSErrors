//
//  CocoaErrorTests.swift
//  
//
//  Created by Charles Srstka on 1/16/23.
//

#if Foundation

@testable import CSErrors
import Testing

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


@Suite("CocoaError Tests")
struct CocoaErrorTests {

    @Test("CocoaError with path works correctly")
    func testCocoaErrorWithPath() {
        let err = CocoaError(
            .fileNoSuchFile,
            description: "no can do",
            failureReason: "i don't wanna",
            stringEncoding: .macOSRoman,
            path: FilePath("/path/to/file")
        )

        #expect(err.code == .fileNoSuchFile)
#if canImport(Darwin)
        #expect(err.errorCode == CocoaError.Code.fileNoSuchFile.rawValue)
        #expect(err.localizedDescription == "no can do")
#endif
        #expect((err.userInfo[NSLocalizedDescriptionKey] as? String) == "no can do")
        #expect(err.stringEncoding == .macOSRoman)
        #expect((err.userInfo[NSLocalizedFailureReasonErrorKey] as? String) == "i don't wanna")
        #expect(err.url == URL(filePath: "/path/to/file"))
    }

    @Test("CocoaError with URL works correctly")
    func testCocoaErrorWithURL() {
        let err = CocoaError(
            .fileNoSuchFile,
            description: "no can do",
            failureReason: "i don't wanna",
            stringEncoding: .macOSRoman,
            url: URL(filePath: "/path/to/file")
        )

        #expect(err.code == .fileNoSuchFile)
#if canImport(Darwin)
        #expect(err.errorCode == CocoaError.Code.fileNoSuchFile.rawValue)
        #expect(err.localizedDescription == "no can do")
#endif
        #expect((err.userInfo[NSLocalizedDescriptionKey] as? String) == "no can do")
        #expect((err.userInfo[NSLocalizedFailureReasonErrorKey] as? String) == "i don't wanna")
        #expect(err.stringEncoding == .macOSRoman)
        #expect(err.url == URL(filePath: "/path/to/file"))
    }

    @Test("CocoaError identifies file not found errors")
    func testFileNotFound() {
        #expect(CocoaError(.fileNoSuchFile).isFileNotFoundError)
        #expect(CocoaError(.fileReadNoSuchFile).isFileNotFoundError)
#if canImport(Darwin)
        #expect(CocoaError(.ubiquitousFileUnavailable).isFileNotFoundError)
#endif
        #expect(!CocoaError(.fileWriteNoPermission).isFileNotFoundError)
    }

    @Test("CocoaError identifies permission errors")
    func testPermissionError() {
        #expect(CocoaError(.fileReadNoPermission).isPermissionError)
        #expect(CocoaError(.fileWriteNoPermission).isPermissionError)
        #expect(!CocoaError(.fileNoSuchFile).isPermissionError)
    }

    @Test("CocoaError identifies cancelled errors")
    func testCancelledError() {
        #expect(CocoaError(.userCancelled).isCancelledError)
        #expect(!CocoaError(.fileNoSuchFile).isCancelledError)
    }
}

#endif
