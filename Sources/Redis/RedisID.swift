import Foundation
import Vapor

/// A type-safe representation of a String representing individual identifiers of separate Redis connections and configurations.
///
/// It is recommended to define static extensions for your definitions to make it easier at call sites to reference them.
///
/// For example:
/// ```swift
/// extension RedisID { static let oceanic = RedisID("oceanic") }
/// app.redis(.oceanic) // Application.Redis instance
/// ```
public struct RedisID: Hashable,
                       Codable,
                       RawRepresentable,
                       ExpressibleByStringLiteral,
                       ExpressibleByStringInterpolation,
                       CustomStringConvertible,
                       Comparable,
                       Sendable {

    public let rawValue: String

    public init(stringLiteral: String) {
        self.rawValue = stringLiteral
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ string: String) {
        self.rawValue = string
    }

    public var description: String { rawValue }
    public static func < (lhs: RedisID, rhs: RedisID) -> Bool { lhs.rawValue < rhs.rawValue }

    public static let `default`: RedisID = "default"
}

extension Application {
    /// The default Redis connection.
    ///
    /// If different Redis configurations are in use, use the `redis(_:)` method to match by `RedisID` instead.
    public var redis: Redis {
        redis(.default)
    }

    /// Returns the Redis connection for the given ID.
    /// - Parameter id: The Redis ID that identifies the specific connection to be used.
    /// - Returns: A Redis connection that is identified by the given `id`.
    public func redis(_ id: RedisID) -> Redis {
        .init(application: self, redisID: id)
    }
}

extension Request {
    /// The default Redis connection.
    ///
    /// If different Redis configurations are in use, use the `redis(_:)` method to match by `RedisID` instead.
    public var redis: Redis {
        redis(.default)
    }

    /// Returns the Redis connection for the given ID.
    /// - Parameter id: The Redis ID that identifies the specific connection to be used.
    /// - Returns: A Redis connection that is identified by the given `id`.
    public func redis(_ id: RedisID) -> Redis {
        .init(request: self, id: id)
    }
}
