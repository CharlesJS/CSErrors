#if Foundation
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
#endif

public struct HTTPError: CSErrorProtocol {
    public let statusCode: Int

    public init(statusCode: Int) {
        self.statusCode = statusCode
    }

    public var failureReason: String? {
        var reason = "HTTP \(self.statusCode)"

#if Foundation
        reason += " (\(HTTPURLResponse.localizedString(forStatusCode: self.statusCode)))"
#endif

        return reason
    }

    public var errorDescription: String? { self.failureReason }

    public var isFileNotFoundError: Bool { self.statusCode == 404 }
    public var isPermissionError: Bool { [401, 403, 407].contains(self.statusCode) }
    public var isCancelledError: Bool { false }

    public var _code: Int { self.statusCode }
}
