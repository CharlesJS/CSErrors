//
//  NSErrorTests.swift
//
//
//  Created by Charles Srstka on 11/7/23.
//

import XCTest

final class NSErrorTests: XCTestCase {
    func testFileNotFound() {
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError).isFileNotFoundError)
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError).isFileNotFoundError)
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSUbiquitousFileUnavailableError).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: NSURLErrorNoPermissionsToReadFile).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: fnfErr).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: ioErr).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kENOENTErr).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: kEINVALErr).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorENOENT).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorEINVAL).isFileNotFoundError)

        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)).isFileNotFoundError)
        XCTAssertFalse(NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).isFileNotFoundError)
    }

    func testPermissionError() {
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError).isPermissionError)
        XCTAssertTrue(NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError).isPermissionError)
        XCTAssertFalse(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError).isPermissionError)

        XCTAssertTrue(NSError(domain: NSURLErrorDomain, code: NSURLErrorNoPermissionsToReadFile).isPermissionError)
        XCTAssertFalse(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: afpAccessDenied).isPermissionError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: fnfErr).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorEACCES).isPermissionError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorEPERM).isPermissionError)

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kEACCESErr).isPermissionError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kEPERMErr).isPermissionError)

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

        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: userCanceledErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: errAEWaitCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kernelCanceledErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kOTCanceledErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kECANCELErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: errIACanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kRAConnectionCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kTXNUserCanceledOperationErr).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kFBCindexingCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kFBCaccessCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kFBCsummarizationCanceled).isCancelledError)
        XCTAssertTrue(NSError(domain: NSOSStatusErrorDomain, code: kPOSIXErrorECANCELED).isCancelledError)
        XCTAssertFalse(NSError(domain: NSOSStatusErrorDomain, code: badFolderDescErr).isCancelledError)

        XCTAssertTrue(NSError(domain: NSPOSIXErrorDomain, code: Int(ECANCELED)).isCancelledError)
        XCTAssertFalse(NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).isCancelledError)
    }
}
