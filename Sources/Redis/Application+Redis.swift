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
                        initialConnectionBackoffDelay: configuration.pool.initialConnectionBackoffDelay
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
    public var isConnected: Bool { true }

    public var logger: Logger {
        self.application.logger
    }
    
    public var eventLoop: EventLoop {
        self.application.eventLoopGroup.next()
    }

    public func setLogging(to logger: Logger) {
        // cannot set logger
    }

    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.application.redis
            .pool(for: self.eventLoop.next())
            .logging(to: self.logger)
            .send(command: command, with: arguments)
    }
}
