//
//  HTTPError+Foundation.swift
//  
//
//  Created by Charles Srstka on 1/10/23.
//

import Foundation
@_spi(CSErrorsInternal) import CSErrors

extension HTTPError: LocalizedError {}

@_spi(CSErrorsInternal) extension HTTPError: _CSErrorsHTTPErrorInternal {
    public var statusCodeString: String {
        HTTPURLResponse.localizedString(forStatusCode: self.statusCode)
    }
}
