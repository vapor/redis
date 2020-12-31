import Vapor

extension Request {
    public struct Redis {
        let redisID: RedisID
        let request: Request

        init(request: Request, redisID: RedisID) {
            self.request = request
            self.redisID = redisID
        }
    }
}

extension Request.Redis: RedisClient {
    public var eventLoop: EventLoop {
        self.request.eventLoop
    }

    public func logging(to logger: Logger) -> RedisClient {
        self.request.application.redis(self.redisID)
            .pool(for: self.eventLoop)
            .logging(to: logger)
    }

    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.request.application.redis(self.redisID)
            .pool(for: self.eventLoop)
            .logging(to: self.request.logger)
            .send(command: command, with: arguments)
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        return self.request.application.redis(self.redisID)
            .pubsubClient
            .logging(to: self.request.logger)
            .subscribe(to: channels, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        return self.request.application.redis(self.redisID)
            .pubsubClient
            .logging(to: self.request.logger)
            .unsubscribe(from: channels)
    }
    
    public func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        return self.request.application.redis(self.redisID)
            .pubsubClient
            .logging(to: self.request.logger)
            .psubscribe(to: patterns, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        return self.request.application.redis(self.redisID)
            .pubsubClient
            .logging(to: self.request.logger)
            .punsubscribe(from: patterns)
    }
}
