//
//  NSErrorTests.swift
//
//
//  Created by Charles Srstka on 11/7/23.
//

#if Foundation

import XCTest

final class NSErrorTests: XCTestCase {
    func testFileNotFound() {
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError).isFileNotFoundError)
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError).isFileNotFoundError)
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSUbiquitousFileUnavailableError).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: NSURLErrorNoPermissionsToReadFile).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -43 /* fnfErr */).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: -36 /* ioErr */).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -3201 /* kENOENTErr */).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: -3221 /* kEINVALErr */).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: 100002 /* kPOSIXErrorENOENT */).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: 100022 /* kPOSIXErrorEINVAL */).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).isFileNotFoundError)
    }

    func testPermissionError() {
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError).isPermissionError)
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError).isPermissionError)
        XCTAssertFalse(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError).isPermissionError)

        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: NSURLErrorNoPermissionsToReadFile).isPermissionError)
        XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -5000 /* afpAccessDenied */).isPermissionError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: -43 /* fnfErr */).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: 100013 /* kPOSIXErrorEACCES */).isPermissionError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: 100001 /* kPOSIXErrorEPERM */).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -3212 /* kEACCESErr */).isPermissionError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -3200 /* kEPERMErr */).isPermissionError)

        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES)).isPermissionError)
        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM)).isPermissionError)
        XCTAssertFalse(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)).isPermissionError)
    }

    func testCancelledError() {
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError).isCancelledError)
        XCTAssertFalse(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError).isCancelledError)

        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: NSURLErrorUserCancelledAuthentication).isCancelledError)
        XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut).isCancelledError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -128 /* userCanceledErr */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -1711 /* errAEWaitCanceled */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -2402 /* kernelCanceledErr */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -3180 /* kOTCanceledErr */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -3273 /* kECANCELErr */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -5385 /* errIACanceled */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -7109 /* kRAConnectionCanceled */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -22004 /* kTXNUserCanceledOperationErr */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -30520 /* kFBCindexingCanceled */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -30521 /* kFBCaccessCanceled */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: -30529 /* kFBCsummarizationCanceled */).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: 100089 /* kPOSIXErrorECANCELED */).isCancelledError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: -4270 /* badFolderDescErr */).isCancelledError)

        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(ECANCELED)).isCancelledError)
        XCTAssertFalse(NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).isCancelledError)
    }
}

#endif
