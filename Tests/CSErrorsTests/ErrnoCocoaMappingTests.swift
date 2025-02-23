//
//  ErrnoCocoaMappingTests.swift
//  
//
//  Created by Charles Srstka on 1/12/23.
//

#if Foundation

@testable import CSErrors
import System
import XCTest

@available(macOS 13.0, *)
class ErrnoCocoaMappingTests: XCTestCase {
    private func checkMapping(code: Int32, cocoaCode: CocoaError.Code, isWrite: Bool = false) throws {
        func checkTypeAndCode(_ e: some Error) throws {
            let cocoaError = try XCTUnwrap(e as? CocoaError)
            let errnoError = try XCTUnwrap(cocoaError.userInfo[NSUnderlyingErrorKey] as? Errno)

            XCTAssertEqual(cocoaError.code, cocoaCode)
            XCTAssertEqual(errnoError.rawValue, code)
        }

        try checkTypeAndCode(errno(code, isWrite: isWrite))

        let stringErr = errno(code, path: "/yellow/brick/road", isWrite: isWrite)
        try checkTypeAndCode(stringErr)
        XCTAssertEqual((stringErr as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String, "/yellow/brick/road")
        XCTAssertEqual((stringErr as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, URL(filePath: "/yellow/brick/road"))

        let filePathErr = errno(code, path: FilePath("/the/psycho/path"), isWrite: isWrite)
        XCTAssertEqual((filePathErr as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String, "/the/psycho/path")
        XCTAssertEqual((filePathErr as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, URL(filePath: "/the/psycho/path"))
    }

    func testCocoaErrorTranslation() throws {
        try self.checkMapping(code: EPERM, cocoaCode: .fileReadNoPermission, isWrite: false)
        try self.checkMapping(code: EPERM, cocoaCode: .fileWriteNoPermission, isWrite: true)
        try self.checkMapping(code: ENOENT, cocoaCode: .fileReadNoSuchFile, isWrite: false)
        try self.checkMapping(code: ENOENT, cocoaCode: .fileNoSuchFile, isWrite: true)
        try self.checkMapping(code: EEXIST, cocoaCode: .fileWriteFileExists)
        try self.checkMapping(code: EFBIG, cocoaCode: .fileReadTooLarge)
        try self.checkMapping(code: ENOSPC, cocoaCode: .fileWriteOutOfSpace)
        try self.checkMapping(code: EROFS, cocoaCode: .fileWriteVolumeReadOnly)
        try self.checkMapping(code: EFTYPE, cocoaCode: .fileReadCorruptFile)
        try self.checkMapping(code: ECANCELED, cocoaCode: .userCancelled)
    }

    func testUnmappableError() {
        XCTAssertTrue(errno(EINVAL) is Errno)
        XCTAssertTrue(errno(EBADF) is Errno)
        XCTAssertTrue(errno(EINTR) is Errno)
    }

    func testMappingZeroError() {
        XCTAssertEqual(errno(0, isWrite: false) as? CocoaError, CocoaError(.fileReadUnknown))
        XCTAssertEqual(errno(0, isWrite: true) as? CocoaError, CocoaError(.fileWriteUnknown))
    }

    func testURLPropagationOnOldMacOS() {
        func check() {
            let err = errno(ENOENT, path: FilePath("/omg/wtf/bbq"))

            XCTAssert(err is CocoaError)
            XCTAssertEqual((err as? CocoaError)?.code, .fileReadNoSuchFile)
            XCTAssertEqual((err as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String, "/omg/wtf/bbq")
            XCTAssertEqual((err as? CocoaError)?.userInfo[NSURLErrorKey] as? URL, URL(filePath: "/omg/wtf/bbq"))
        }

        emulateMacOSVersion(12, closure: check)
        emulateMacOSVersion(11, closure: check)
    }

    func testReturnPOSIXErrorOnMacOS10() {
        emulateMacOSVersion(10) {
            for eachCode in [EINVAL, EBADF, EINTR] {
                let err = errno(eachCode)

                XCTAssertFalse(err is Errno)
                XCTAssertTrue(err is POSIXError)
                XCTAssertEqual(err as? POSIXError, POSIXError(.init(rawValue: eachCode)!))
            }
        }
    }
}

#endif
