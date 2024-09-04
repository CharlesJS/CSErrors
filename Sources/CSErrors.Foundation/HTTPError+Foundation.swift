//
//  HTTPError+Foundation.swift
//  
//
//  Created by Charles Srstka on 1/10/23.
//

import Foundation
import CSErrors

extension HTTPError {
    package var statusCodeString: String {
        HTTPURLResponse.localizedString(forStatusCode: self.statusCode)
    }
}

#if compiler(>=6)
extension HTTPError: @retroactive LocalizedError {}
extension HTTPError: @retroactive _CSErrorsHTTPErrorInternal {}
#else
extension HTTPError: LocalizedError {}
extension HTTPError: _CSErrorsHTTPErrorInternal {}
#endif
