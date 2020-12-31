import Vapor

extension Application {
    public struct Redis {
        internal func pool(for eventLoop: EventLoop) -> RedisConnectionPool {

            guard let pools = self.application.redises.allPools[eventLoop.key] else {
                fatalError("The app may not have finished booting: EventLoop must be from Application's EventLoopGroup.")
            }
            guard let p = pools[self.redisID] else {
                fatalError("No pool found for key \(self.redisID)")
            }
            return p
        }

        struct PubSubKey: StorageKey, LockKey {
            typealias Value = [RedisID: RedisClient]
        }
        
        var pubsubClient: RedisClient {
            if let existing = self.application.storage[PubSubKey.self]?[self.redisID] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: PubSubKey.self)
                lock.lock()
                defer { lock.unlock() }

                let pool = self.pool(for: self.eventLoop.next())

                if let existing = self.application.storage[PubSubKey.self] {
                    var copy = existing
                    copy[self.redisID] = pool
                    self.application.storage.set(PubSubKey.self, to: copy)
                } else {
                    self.application.storage.set(PubSubKey.self, to: [self.redisID: pool])
                }
                return pool
            }
        }

        let redisID: RedisID
        let application: Application
        public init(application: Application, redisID: RedisID = .default) {
            self.application = application
            self.redisID = redisID
        }
    }
}

extension EventLoop {
    typealias Key = ObjectIdentifier
    var key: Key {
        ObjectIdentifier(self)
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
