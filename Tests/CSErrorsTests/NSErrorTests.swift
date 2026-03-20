//
//  NSErrorTests.swift
//
//
//  Created by Charles Srstka on 11/7/23.
//

#if Foundation

import Foundation
import Testing

@Suite("NSError Tests")
struct NSErrorTests {
    @Test("isFileNotFoundError")
    func testFileNotFound() {
        #expect(NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError).isFileNotFoundError)
        #expect(NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError).isFileNotFoundError)
        #expect(NSError(domain: NSCocoaErrorDomain, code: NSUbiquitousFileUnavailableError).isFileNotFoundError)
        #expect(!NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError).isFileNotFoundError)

        #expect(NSError(domain: NSURLErrorDomain, code: NSURLErrorFileDoesNotExist).isFileNotFoundError)
        #expect(!NSError(domain: NSURLErrorDomain, code: NSURLErrorNoPermissionsToReadFile).isFileNotFoundError)

        #expect(NSError(domain: NSOSStatusErrorDomain, code: -43 /* fnfErr */).isFileNotFoundError)
        #expect(!NSError(domain: NSOSStatusErrorDomain, code: -36 /* ioErr */).isFileNotFoundError)

        #expect(NSError(domain: NSOSStatusErrorDomain, code: -3201 /* kENOENTErr */).isFileNotFoundError)
        #expect(!NSError(domain: NSOSStatusErrorDomain, code: -3221 /* kEINVALErr */).isFileNotFoundError)

        #expect(NSError(domain: NSOSStatusErrorDomain, code: 100002 /* kPOSIXErrorENOENT */).isFileNotFoundError)
        #expect(!NSError(domain: NSOSStatusErrorDomain, code: 100022 /* kPOSIXErrorEINVAL */).isFileNotFoundError)

        #expect(NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)).isFileNotFoundError)
        #expect(!NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).isFileNotFoundError)
    }

    @Test("isPermissionError")
    func testPermissionError() {
        #expect(NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError).isPermissionError)
        #expect(NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError).isPermissionError)
        #expect(!NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError).isPermissionError)

        #expect(NSError(domain: NSURLErrorDomain, code: NSURLErrorNoPermissionsToReadFile).isPermissionError)
        #expect(!NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL).isPermissionError)

        #expect(NSError(domain: NSOSStatusErrorDomain, code: -5000 /* afpAccessDenied */).isPermissionError)
        #expect(!NSError(domain: NSOSStatusErrorDomain, code: -43 /* fnfErr */).isPermissionError)

        #expect(NSError(domain: NSOSStatusErrorDomain, code: 100013 /* kPOSIXErrorEACCES */).isPermissionError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: 100001 /* kPOSIXErrorEPERM */).isPermissionError)

        #expect(NSError(domain: NSOSStatusErrorDomain, code: -3212 /* kEACCESErr */).isPermissionError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -3200 /* kEPERMErr */).isPermissionError)

        #expect(NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES)).isPermissionError)
        #expect(NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM)).isPermissionError)
        #expect(!NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT)).isPermissionError)
    }

    @Test("isCancelledError")
    func testCancelledError() {
        #expect(NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError).isCancelledError)
        #expect(!NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError).isCancelledError)

        #expect(NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled).isCancelledError)
        #expect(NSError(domain: NSURLErrorDomain, code: NSURLErrorUserCancelledAuthentication).isCancelledError)
        #expect(!NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut).isCancelledError)

        #expect(NSError(domain: NSOSStatusErrorDomain, code: -128 /* userCanceledErr */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -1711 /* errAEWaitCanceled */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -2402 /* kernelCanceledErr */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -3180 /* kOTCanceledErr */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -3273 /* kECANCELErr */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -5385 /* errIACanceled */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -7109 /* kRAConnectionCanceled */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -22004 /* kTXNUserCanceledOperationErr */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -30520 /* kFBCindexingCanceled */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -30521 /* kFBCaccessCanceled */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: -30529 /* kFBCsummarizationCanceled */).isCancelledError)
        #expect(NSError(domain: NSOSStatusErrorDomain, code: 100089 /* kPOSIXErrorECANCELED */).isCancelledError)
        #expect(!NSError(domain: NSOSStatusErrorDomain, code: -4270 /* badFolderDescErr */).isCancelledError)

        #expect(NSError(domain: NSPOSIXErrorDomain, code: Int(ECANCELED)).isCancelledError)
        #expect(!NSError(domain: NSPOSIXErrorDomain, code: Int(EINVAL)).isCancelledError)
    }
}

#endif

