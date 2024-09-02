//
//  ErrorMetadata.swift
//  
//
//  Created by Charles Srstka on 1/11/23.
//

import System

public struct ErrorMetadata: Sendable {
    public let description: String?
    public internal(set) var failureReason: String?
    public let recoverySuggestion: String?
    public let recoveryOptions: [String]?
    public let recoveryAttempter: (any Sendable)?
    public let helpAnchor: String?
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
    public var path: FilePath? { self.pathWrapper?.path }
    public var pathString: String? { self.pathWrapper?.string }
    public let underlying: (any Error)?
    public let custom: [String : any Sendable]?

    private enum PathWrapper: Sendable {
        case path(any Sendable)
        case string(String)

        @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
        var path: FilePath {
            switch self {
            case .path(let path):
                return path as! FilePath
            case .string(let string):
                return FilePath(string)
            }
        }

        var string: String {
            switch self {
            case .path(let path):
                guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *), versionCheck(11) else {
                    preconditionFailure("Should not be reached")
                }

                guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, macCatalyst 15.0, *), versionCheck(12) else {
                    return String(decoding: path as! FilePath)
                }

                return (path as! FilePath).string
            case .string(let string):
                return string
            }
        }
    }
    private let pathWrapper: PathWrapper?

    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, macCatalyst 14.0, *)
    public init(
        description: String? = nil,
        failureReason: String? = nil,
        recoverySuggestion: String? = nil,
        recoveryOptions: [String]? = nil,
        recoveryAttempter: (any Sendable)? = nil,
        helpAnchor: String? = nil,
        path: FilePath,
        underlying: (any Error)? = nil,
        custom: [String: any Sendable]? = nil
    ) {
        self.description = description
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.recoveryOptions = recoveryOptions
        self.recoveryAttempter = recoveryAttempter
        self.helpAnchor = helpAnchor
        self.pathWrapper = .path(path)
        self.underlying = underlying
        self.custom = custom
    }

    public init(
        description: String? = nil,
        failureReason: String? = nil,
        recoverySuggestion: String? = nil,
        recoveryOptions: [String]? = nil,
        recoveryAttempter: (any Sendable)? = nil,
        helpAnchor: String? = nil,
        path: String? = nil,
        underlying: (any Error)? = nil,
        custom: [String: any Sendable]? = nil
    ) {
        self.description = description
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.recoveryOptions = recoveryOptions
        self.recoveryAttempter = recoveryAttempter
        self.helpAnchor = helpAnchor
        self.pathWrapper = path.map { .string($0) }
        self.underlying = underlying
        self.custom = custom
    }
}
