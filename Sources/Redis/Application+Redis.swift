import Vapor

extension Application {
    public struct Redis {
        func pool(for eventLoop: EventLoop) -> RedisConnectionPool {
            self.application.redisStorage.pool(for: self.eventLoop.next(), id: self.redisID)
        }

        let redisID: RedisID
        let application: Application
        init(application: Application, redisID: RedisID) {
            self.application = application
            self.redisID = redisID
        }
    }
}

extension Application.Redis: RedisClient {
    public var eventLoop: EventLoop {
        self.application.eventLoopGroup.next()
    }

    public func logging(to logger: Logger) -> RedisClient {
        self.application.redis(self.redisID)
            .pool(for: self.eventLoop)
            .logging(to: logger)
    }

    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.application.redis(self.redisID)
            .pool(for: self.eventLoop.next())
            .logging(to: self.application.logger)
            .send(command: command, with: arguments)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        return self.application.redis(self.redisID)
            .pubsubClient
            .logging(to: self.application.logger)
            .subscribe(to: channels, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        return self.application.redis(self.redisID)
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
        return self.application.redis(self.redisID)
            .pubsubClient
            .logging(to: self.application.logger)
            .psubscribe(to: patterns, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        return self.application.redis(self.redisID)
            .pubsubClient
            .logging(to: self.application.logger)
            .punsubscribe(from: patterns)
    }
}
