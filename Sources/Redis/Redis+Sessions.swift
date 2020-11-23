import Foundation
import Vapor

/// A delegate object that controls key behavior of an `Application.Redis.Sessions` driver.
public protocol RedisSessionsDelegate {
    /// Makes a new session ID token.
    /// - Note: This method is optional to implement.
    ///
    ///  The default implementation creates 32 bytes of random data, base64 encodes it, and prefixes it with `vrs-`.
    func makeNewID() -> SessionID
    /// Instructs your delegate object to handle the responsibility of storing the provided session data to Redis.
    /// - Parameters:
    ///     - client: The Redis client to use for the operation.
    ///     - data: The session data to store in Redis.
    ///     - id: The session ID to use to identify the data.
    /// - Returns: A notification `NIO.EventLoopFuture` that resolves when the operation has completed.
    func redis<Client: RedisClient>(_ client: Client, storeData data: SessionData, forID id: SessionID) -> EventLoopFuture<Void>
    /// Asks the delegate object to fetch session data for a given session id.
    /// - Parameters:
    ///     - client: The Redis client to use for the operation.
    ///     - id: The session ID to fetch data for from Redis.
    /// - Returns: A `NIO.EventLoopFuture` that possibly resolves the available session data for the given session ID.
    func redis<Client: RedisClient>(_ client: Client, fetchDataForID id: SessionID) -> EventLoopFuture<SessionData?>
}

extension RedisSessionsDelegate {
    public func makeNewID() -> SessionID {
        var bytes = Data()
        for _ in 0..<32 {
            bytes.append(.random(in: .min ..< .max))
        }
        return .init(string: "vrs-\(bytes.base64EncodedString())")
    }
}

// MARK: Session definition
extension Application.Redis {
    public var sessions: Sessions { .init() }
    
    public struct Sessions {
        /// Factory method that creates a new Redis Sessions driver.
        /// - Parameter delegate: An optional delegate object to use instead of the default. See `RedisSessionsDelegate`.
        public func makeDriver(delegate: RedisSessionsDelegate? = nil) -> SessionDriver {
            return RedisSessionsDriver(delegate: delegate ?? DefaultSessionsDriverDelegate())
        }
    }
}

// MARK: Sessions Provider definition
extension Application.Sessions.Provider {
    /// Provides a Redis sessions driver with the default delegate.
    public static var redis: Self { self.redis(delegate: DefaultSessionsDriverDelegate()) }

    /// Provides a Redis sessions driver using the provided delegate.
    /// - Parameter delegate: The delegate to use in the Redis sessions driver.
    public static func redis(delegate: RedisSessionsDelegate) -> Self {
        return .init {
            $0.sessions.use { $0.redis.sessions.makeDriver(delegate: delegate) }
        }
    }
}

// MARK: SessionDriver
private struct RedisSessionsDriver: SessionDriver {
    private let delegate: RedisSessionsDelegate

    init(delegate: RedisSessionsDelegate) { self.delegate = delegate }

    func createSession(_ data: SessionData, for request: Request) -> EventLoopFuture<SessionID> {
        let id = self.delegate.makeNewID()
        return self.delegate
            .redis(request.redis, storeData: data, forID: id)
            .map { id }
    }
    
    func readSession(_ sessionID: SessionID, for request: Request) -> EventLoopFuture<SessionData?> {
        return self.delegate.redis(request.redis, fetchDataForID: sessionID)
    }
    
    func updateSession(_ sessionID: SessionID, to data: SessionData, for request: Request) -> EventLoopFuture<SessionID> {
        return self.delegate
            .redis(request.redis, storeData: data, forID: sessionID)
            .map { sessionID }
    }
    
    func deleteSession(_ sessionID: SessionID, for request: Request) -> EventLoopFuture<Void> {
        return request.redis.delete("\(sessionID.string)").map { _ in () }
    }
}

// MARK: Default SessionsDriverDelegate
private struct DefaultSessionsDriverDelegate: RedisSessionsDelegate {
    func redis<Client>(_ client: Client, storeData data: SessionData, forID id: SessionID) -> EventLoopFuture<Void> where Client : RedisClient {
        return client.set("\(id.string)", toJSON: data)
    }
    
    func redis<Client>(_ client: Client, fetchDataForID id: SessionID) -> EventLoopFuture<SessionData?> where Client : RedisClient {
        return client.get("\(id.string)", asJSON: SessionData.self)
    }
}
