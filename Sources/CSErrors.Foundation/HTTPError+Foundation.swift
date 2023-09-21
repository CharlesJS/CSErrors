//
//  HTTPError+Foundation.swift
//  
//
//  Created by Charles Srstka on 1/10/23.
//

import Foundation
import CSErrors

extension HTTPError: LocalizedError {}

extension HTTPError: _CSErrorsHTTPErrorInternal {
    package var statusCodeString: String {
        HTTPURLResponse.localizedString(forStatusCode: self.statusCode)
    }
}
