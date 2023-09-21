public struct HTTPError: CSErrorProtocol {
    public let statusCode: Int

    public init(statusCode: Int) {
        self.statusCode = statusCode
    }

    public var failureReason: String? {
        var reason = "HTTP \(self.statusCode)"

        if let i = self as? any _CSErrorsHTTPErrorInternal {
            reason += " (\(i.statusCodeString))"
        }

        return reason
    }

    public var errorDescription: String? { self.failureReason }

    public var isFileNotFoundError: Bool { self.statusCode == 404 }
    public var isPermissionError: Bool { [401, 403, 407].contains(self.statusCode) }
    public var isCancelledError: Bool { false }

    public var _code: Int { self.statusCode }
}

package protocol _CSErrorsHTTPErrorInternal {
    var statusCodeString: String { get }
}
