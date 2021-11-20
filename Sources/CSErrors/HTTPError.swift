import Foundation

public struct HTTPError: LocalizedError {
    public let statusCode: Int

    public init(statusCode: Int) {
        self.statusCode = statusCode
    }

    public var failureReason: String? {
        HTTPURLResponse.localizedString(forStatusCode: self.statusCode)
    }

    public var errorDescription: String? { self.failureReason }

    public var _code: Int { self.statusCode }
}
