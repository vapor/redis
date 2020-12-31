import Vapor

extension Application {

    public var redisConfigurations: [RedisID: RedisConfiguration]? {
        get {
            self.storage[Redis.ConfigurationKey.self]
        }
        set {
            if self.storage.contains(Redis.PoolKey.self) {
                fatalError("Cannot modify your Redis configuration after redis has been used")
            }
            self.storage[Redis.ConfigurationKey.self] = newValue
        }
    }

    public struct Redis {
        struct ConfigurationKey: StorageKey {
            typealias Value = [RedisID: RedisConfiguration]
        }

        public var configuration: RedisConfiguration? {
            get {
                self.application.storage[ConfigurationKey.self]?[self.redisID]
            }
            nonmutating set {
                if self.application.storage.contains(PoolKey.self) {
                    fatalError("Cannot modify your Redis configuration after redis has been used")
                }
                self.application.storage[ConfigurationKey.self] = [self.redisID: newValue!]
            }
        }

        fileprivate struct PoolKey: StorageKey, LockKey {
            typealias Value = [EventLoop.Key: [RedisID: RedisConnectionPool]]
        }

        // must be event loop from this app's elg
        internal func pool(for eventLoop: EventLoop) -> RedisConnectionPool {
            guard let pool = self.pools[eventLoop.key] else {
                fatalError("EventLoop must be from Application's EventLoopGroup.")
            }
            guard let p = pool[self.redisID] else {
                fatalError("No pool found for key \(self.redisID)")
            }
            return p
        }

        private var pools: [EventLoop.Key: [RedisID: RedisConnectionPool]] {
            if let existing = self.application.storage[PoolKey.self] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: PoolKey.self)
                lock.lock()
                defer { lock.unlock() }
                guard let configurations = self.application.redisConfigurations else {
                    fatalError("Redis not configured. Use app.redis.configuration = ...")
                }
                var allPools = [EventLoop.Key: [RedisID: RedisConnectionPool]]()
                for eventLoop in self.application.eventLoopGroup.makeIterator() {

                    var eventLoopPools = [RedisID: RedisConnectionPool]()
                    for configuration in configurations {
                        eventLoopPools[configuration.key] = RedisConnectionPool(
                            configuration: .init(configuration.value, defaultLogger: self.application.logger),
                            boundEventLoop: eventLoop
                        )
                    }
                    allPools[eventLoop.key] = eventLoopPools

                }
                self.application.storage.set(PoolKey.self, to: allPools) { allPools in
                    try allPools.values.compactMap { pools in
                        guard let pool = pools[self.redisID] else {
                            return nil
                        }

                        let promise = pool.eventLoop.makePromise(of: Void.self)
                        pool.close(promise: promise)
                        return promise.futureResult
                    }.flatten(on: self.application.eventLoopGroup.next()).wait()
                }
                return allPools
            }
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

private extension EventLoop {
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
