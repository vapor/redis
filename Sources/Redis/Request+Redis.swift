import Vapor

extension Request {
    public struct Redis {
        public let id: RedisID

        @usableFromInline
        internal let request: Request

        internal init(request: Request, id: RedisID) {
            self.request = request
            self.id = id
        }
    }
}

// MARK: RedisClient
extension Request.Redis: RedisClient {
    public var eventLoop: EventLoop { self.request.eventLoop }
    public var defaultLogger: Logger? { self.request.logger }

    public func logging(to logger: Logger) -> RedisClient {
        self.request.application.redis(self.id)
            .pool(for: self.eventLoop)
            .logging(to: logger)
    }

    public func send<CommandResult>(
        _ command: RedisCommand<CommandResult>,
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil
    ) -> EventLoopFuture<CommandResult> {
        self.request.application.redis(self.id)
            .pool(for: self.eventLoop)
            .logging(to: self.request.logger)
            .send(command, eventLoop: eventLoop, logger: logger)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil,
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscribeHandler?,
        onUnsubscribe unsubscribeHandler: RedisUnsubscribeHandler?
    ) -> EventLoopFuture<Void> {
        self.request.application.redis(self.id)
            .pubsubClient
            .logging(to: self.request.logger)
            .subscribe(to: channels, eventLoop: eventLoop, logger: logger, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func unsubscribe(from channels: [RedisChannelName], eventLoop: EventLoop? = nil, logger: Logger? = nil) -> EventLoopFuture<Void> {
        self.request.application.redis(self.id)
            .pubsubClient
            .logging(to: self.request.logger)
            .unsubscribe(from: channels, eventLoop: eventLoop, logger: logger)
    }
    
    public func psubscribe(
        to patterns: [String],
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil,
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscribeHandler?,
        onUnsubscribe unsubscribeHandler: RedisUnsubscribeHandler?
    ) -> EventLoopFuture<Void> {
        self.request.application.redis(self.id)
            .pubsubClient
            .logging(to: self.request.logger)
            .psubscribe(to: patterns, eventLoop: eventLoop, logger: logger, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func punsubscribe(from patterns: [String], eventLoop: EventLoop? = nil, logger: Logger? = nil) -> EventLoopFuture<Void> {
        self.request.application.redis(self.id)
            .pubsubClient
            .logging(to: self.request.logger)
            .punsubscribe(from: patterns, eventLoop: eventLoop, logger: logger)
    }
}

// MARK: Connection Leasing
extension Request.Redis {
    /// Provides temporary exclusive access to a single Redis client.
    ///
    /// See `RedisConnectionPool.leaseConnection(_:)` for more details.
    @inlinable
    public func withBorrowedClient<Result>(
        _ operation: @escaping (RedisClient) -> EventLoopFuture<Result>
    ) -> EventLoopFuture<Result> {
        return self.request.application.redis(self.id)
            .pool(for: self.eventLoop)
            .leaseConnection {
                return operation($0.logging(to: self.request.logger))
            }
    }
}
