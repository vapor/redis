import Vapor
import RediStack
import NIOCore
import Logging

extension Application {
    public struct Redis {
        public let id: RedisID

        @usableFromInline
        internal let application: Application

        internal init(application: Application, redisID: RedisID) {
            self.application = application
            self.id = redisID
        }

        @usableFromInline
        internal func pool(for eventLoop: EventLoop) -> RedisClient {
            self.application.redisStorage.pool(for: eventLoop, id: self.id)
        }
        
        public func use(_ factory: RedisFactory) {
            self.application.redisStorage.use(factory, as: id)
        }
    }
}

// MARK: RedisClient
extension Application.Redis: RedisClient {
    public var eventLoop: EventLoop {
        self.application.eventLoopGroup.next()
    }

    public func logging(to logger: Logger) -> RedisClient {
        self.application.redis(self.id)
            .pool(for: self.eventLoop)
            .logging(to: logger)
    }

    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.application.redis(self.id)
            .pool(for: self.eventLoop)
            .logging(to: self.application.logger)
            .send(command: command, with: arguments)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        self.application.redis(self.id)
            .pubsubClient
            .logging(to: self.application.logger)
            .subscribe(to: channels, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        self.application.redis(self.id)
            .pubsubClient
            .logging(to: self.application.logger)
            .unsubscribe(from: channels)
    }
    
    public func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        self.application.redis(self.id)
            .pubsubClient
            .logging(to: self.application.logger)
            .psubscribe(to: patterns, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        self.application.redis(self.id)
            .pubsubClient
            .logging(to: self.application.logger)
            .punsubscribe(from: patterns)
    }
}

// MARK: Connection Leasing
extension Application.Redis {
    /// Provides temporary exclusive access to a single Redis client.
    ///
    /// See `RedisConnectionPool.leaseConnection(_:)` for more details.
    @inlinable
    public func withBorrowedConnection<Result>(
        _ operation: @escaping (RedisClient) -> EventLoopFuture<Result>
    ) -> EventLoopFuture<Result> {
        let client = self.application.redis(self.id)
            .pool(for: self.eventLoop)
        
        guard let pool = client as? RedisConnectionPool else {
            return self.eventLoop.makeFailedFuture(Application.Redis.Errors.unsupportedOperation)
        }
        
        return pool.leaseConnection {
            return operation($0.logging(to: self.application.logger))
        }
    }
}
