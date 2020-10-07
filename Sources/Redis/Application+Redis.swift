import Vapor

extension Application {
    public var redis: Redis {
        .init(application: self)
    }

    public struct Redis {
        struct ConfigurationKey: StorageKey {
            typealias Value = RedisConfiguration
        }

        public var configuration: RedisConfiguration? {
            get {
                self.application.storage[ConfigurationKey.self]
            }
            nonmutating set {
                if self.application.storage.contains(PoolKey.self) {
                    fatalError("Cannot modify your Redis configuration after redis has been used")
                }
                self.application.storage[ConfigurationKey.self] = newValue
            }
        }

        private struct PoolKey: StorageKey, LockKey {
            typealias Value = [EventLoop.Key: RedisConnectionPool]
        }

        // must be event loop from this app's elg
        internal func pool(for eventLoop: EventLoop) -> RedisConnectionPool {
            guard let pool = self.pools[eventLoop.key] else {
                fatalError("EventLoop must be from Application's EventLoopGroup.")
            }
            return pool
        }

        private var pools: [EventLoop.Key: RedisConnectionPool] {
            if let existing = self.application.storage[PoolKey.self] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: PoolKey.self)
                lock.lock()
                defer { lock.unlock() }
                guard let configuration = self.configuration else {
                    fatalError("Redis not configured. Use app.redis.configuration = ...")
                }
                var pools = [EventLoop.Key: RedisConnectionPool]()
                for eventLoop in self.application.eventLoopGroup.makeIterator() {
                    pools[eventLoop.key] = RedisConnectionPool(
                        serverConnectionAddresses: configuration.serverAddresses,
                        loop: eventLoop,
                        maximumConnectionCount: configuration.pool.maximumConnectionCount,
                        minimumConnectionCount: configuration.pool.minimumConnectionCount,
                        connectionPassword: configuration.password,
                        connectionLogger: self.application.logger,
                        connectionTCPClient: nil,
                        poolLogger: self.application.logger,
                        connectionBackoffFactor: configuration.pool.connectionBackoffFactor,
                        initialConnectionBackoffDelay: configuration.pool.initialConnectionBackoffDelay,
                        connectionRetryTimeout: configuration.pool.connectionRetryTimeout
                    )
                }
                self.application.storage.set(PoolKey.self, to: pools) { pools in
                    try pools.values.map { pool in
                        let promise = pool.eventLoop.makePromise(of: Void.self)
                        pool.close(promise: promise)
                        return promise.futureResult
                    }.flatten(on: self.application.eventLoopGroup.next()).wait()
                }
                return pools
            }
        }
        struct PubSubKey: StorageKey, LockKey {
            typealias Value = RedisClient
        }
        
        var pubsubClient: RedisClient {
            if let existing = self.application.storage[PubSubKey.self] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: PubSubKey.self)
                lock.lock()
                defer { lock.unlock() }
                let pool = self.pool(for: self.eventLoop.next())
                self.application.storage.set(PubSubKey.self, to: pool)
                return pool
            }
        }

        let application: Application
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
        self.application.redis
            .pool(for: self.eventLoop)
            .logging(to: logger)
    }

    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.application.redis
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
        return self.application.redis
            .pubsubClient
            .logging(to: self.application.logger)
            .subscribe(to: channels, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        return self.application.redis
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
        return self.application.redis
            .pubsubClient
            .logging(to: self.application.logger)
            .psubscribe(to: patterns, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
    }
    
    public func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        return self.application.redis
            .pubsubClient
            .logging(to: self.application.logger)
            .punsubscribe(from: patterns)
    }
}
