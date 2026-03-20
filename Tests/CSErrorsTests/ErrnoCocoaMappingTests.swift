//
//  ErrnoCocoaMappingTests.swift
//  
//
//  Created by Charles Srstka on 1/12/23.
//

#if Foundation

@testable import CSErrors
import Foundation
import System
import Testing

@Suite("Map errno to CocoaError")
struct ErrnoCocoaMappingTests {
    private func checkMapping(code: Int32, cocoaCode: CocoaError.Code, isWrite: Bool = false) throws {
        func checkTypeAndCode(_ e: some Error) throws {
            let cocoaError = try #require(e as? CocoaError)
            let errnoError = try #require(cocoaError.userInfo[NSUnderlyingErrorKey] as? Errno)

            #expect(cocoaError.code == cocoaCode)
            #expect(errnoError.rawValue == code)
        }

        try checkTypeAndCode(errno(code, isWrite: isWrite))

        let stringErr = errno(code, path: "/yellow/brick/road", isWrite: isWrite)
        try checkTypeAndCode(stringErr)
        #expect((stringErr as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String == "/yellow/brick/road")
        #expect((stringErr as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == URL(filePath: "/yellow/brick/road"))

        let filePathErr = errno(code, path: FilePath("/the/psycho/path"), isWrite: isWrite)
        #expect((filePathErr as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String == "/the/psycho/path")
        #expect((filePathErr as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == URL(filePath: "/the/psycho/path"))
    }

    @Test("Mappable errno values become CocoaError")
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

    @Test("Unmappable errno values are still Errno")
    func testUnmappableError() {
        #expect(errno(EINVAL) is Errno)
        #expect(errno(EBADF) is Errno)
        #expect(errno(EINTR) is Errno)
    }

    @Test("Map zero errno to unknown error, since a zero shouldn't have been raised")
    func testMappingZeroError() {
        #expect(errno(0, isWrite: false) as? CocoaError == CocoaError(.fileReadUnknown))
        #expect(errno(0, isWrite: true) as? CocoaError == CocoaError(.fileWriteUnknown))
    }

    @Test("URL propagation on old macOS versions")
    func testURLPropagationOnOldMacOS() {
        func check() {
            let err = errno(ENOENT, path: FilePath("/omg/wtf/bbq"))

            #expect(err is CocoaError)
            #expect((err as? CocoaError)?.code == .fileReadNoSuchFile)
            #expect((err as? CocoaError)?.userInfo[NSFilePathErrorKey] as? String == "/omg/wtf/bbq")
            #expect((err as? CocoaError)?.userInfo[NSURLErrorKey] as? URL == URL(filePath: "/omg/wtf/bbq"))
        }

        emulateMacOSVersion(12, closure: check)
        emulateMacOSVersion(11, closure: check)
    }

    @Test("Return POSIXError on macOS 10.x")
    func testReturnPOSIXErrorOnMacOS10() {
        emulateMacOSVersion(10) {
            for eachCode in [EINVAL, EBADF, EINTR] {
                let err = errno(eachCode)

                #expect(!(err is Errno))
                #expect(err is POSIXError)
                #expect((err as? POSIXError) == POSIXError(.init(rawValue: eachCode)!))
            }
        }
    }
}

#endif
