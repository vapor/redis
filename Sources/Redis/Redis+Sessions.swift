import Foundation
import Vapor
import RediStack
import NIOCore

/// A delegate object that controls key behavior of an `Application.Redis.Sessions` driver.
public protocol RedisSessionsDelegate: Sendable {
    /// Makes a new session ID token.
    /// - Note: This method is optional to implement.
    ///
    ///  The default implementation creates 32 bytes of random data and base64 encodes it.
    func makeNewID() -> SessionID
    /// Makes a key to identify the given session ID in Redis.
    /// - Note: This method is optional to implement.
    ///
    /// The default implementation prefixes the `sessionID` with `vrs-`.
    /// - Parameter sessionID: The session ID that needs to be transformed into a `RediStack.RedisKey` for storage in Redis.
    /// - Returns: A Redis key for the given `sessionID` to be used to identify associated `SessionData` in Redis.
    func makeRedisKey(for sessionID: SessionID) -> RedisKey
    /// Instructs your delegate object to handle the responsibility of storing the provided session data to Redis.
    /// - Parameters:
    ///     - client: The Redis client to use for the operation.
    ///     - data: The session data to store in Redis.
    ///     - key: The Redis key to identify the data being stored.
    /// - Returns: A notification `NIO.EventLoopFuture` that resolves when the operation has completed.
    @inlinable
    func redis<Client: RedisClient>(_ client: Client, store data: SessionData, with key: RedisKey) -> EventLoopFuture<Void>
    /// Asks the delegate object to fetch session data for a given Redis key.
    /// - Parameters:
    ///     - client: The Redis client to use for the operation.
    ///     - key: The Redis key that identifies the data to be fetched.
    /// - Returns: A `NIO.EventLoopFuture` that possibly resolves the available session data for the given Redis key.
    @inlinable
    func redis<Client: RedisClient>(_ client: Client, fetchDataFor key: RedisKey) -> EventLoopFuture<SessionData?>
}

extension RedisSessionsDelegate {
    public func makeNewID() -> SessionID {
        var bytes = Data()
        for _ in 0..<32 {
            bytes.append(.random(in: .min ..< .max))
        }
        return .init(string: bytes.base64EncodedString())
    }
    
    public func makeRedisKey(for session: SessionID) -> RedisKey {
        return "vrs-\(session.string)"
    }
}

// MARK: Session definition
extension Application.Redis {
    public var sessions: Sessions { .init() }
    
    public struct Sessions {
        /// Factory method that creates a new Redis Sessions driver with the provided delegate.
        ///
        /// See `RedisSessionsDelegate`.
        /// - Parameter delegate: The delegate object to use instead of the default.
        @inlinable
        public func makeDriver<Delegate: RedisSessionsDelegate>(delegate: Delegate) -> some SessionDriver {
            return RedisSessionsDriver(delegate: delegate)
        }

        /// Factory method that creates a new Redis Session driver with the default delegate.
        ///
        /// See `RedisSessionsDelegate`.
        public func makeDriver() -> some SessionDriver {
            return RedisSessionsDriver(delegate: DefaultSessionsDriverDelegate())
        }
    }
}

// MARK: Sessions Provider definition
extension Application.Sessions.Provider {
    /// Provides a Redis sessions driver with the default delegate.
    public static var redis: Self { self.redis(delegate: DefaultSessionsDriverDelegate()) }

    /// Provides a Redis sessions driver using the provided delegate.
    /// - Parameter delegate: The delegate to use in the Redis sessions driver.
    @inlinable
    public static func redis<Delegate: RedisSessionsDelegate>(delegate: Delegate) -> Self {
        return .init {
            $0.sessions.use { $0.redis.sessions.makeDriver(delegate: delegate) }
        }
    }
}

// MARK: SessionDriver
@usableFromInline
internal struct RedisSessionsDriver<Delegate: RedisSessionsDelegate>: SessionDriver {
    private let delegate: Delegate

    @usableFromInline
    internal init(delegate: Delegate) { self.delegate = delegate }

    public func createSession(_ data: SessionData, for request: Request) -> EventLoopFuture<SessionID> {
        let id = self.delegate.makeNewID()
        let key = self.delegate.makeRedisKey(for: id)
        return self.delegate
            .redis(request.redis, store: data, with: key)
            .map { id }
    }
    
    public func readSession(_ sessionID: SessionID, for request: Request) -> EventLoopFuture<SessionData?> {
        let key = self.delegate.makeRedisKey(for: sessionID)
        return self.delegate.redis(request.redis, fetchDataFor: key)
    }
    
    public func updateSession(_ sessionID: SessionID, to data: SessionData, for request: Request) -> EventLoopFuture<SessionID> {
        let key = self.delegate.makeRedisKey(for: sessionID)
        return self.delegate
            .redis(request.redis, store: data, with: key)
            .map { sessionID }
    }
    
    public func deleteSession(_ sessionID: SessionID, for request: Request) -> EventLoopFuture<Void> {
        let key = self.delegate.makeRedisKey(for: sessionID)
        return request.redis.delete(key).map { _ in () }
    }
}

// MARK: Default SessionsDriverDelegate
private struct DefaultSessionsDriverDelegate: RedisSessionsDelegate {
    @inlinable
    func redis<Client: RedisClient>(_ client: Client, store data: SessionData, with key: RedisKey) -> EventLoopFuture<Void> {
        return client.set(key, toJSON: data)
    }

    @inlinable
    func redis<Client: RedisClient>(_ client: Client, fetchDataFor key: RedisKey) -> EventLoopFuture<SessionData?> {
        return client.get(key, asJSON: SessionData.self)
    }
}
