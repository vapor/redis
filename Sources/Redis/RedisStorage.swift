import Vapor

extension Application {
    private struct RedisesStorageKey: StorageKey {
        typealias Value = RedisStorage
    }
    var redisStorage: RedisStorage {
        if self.storage[RedisesStorageKey.self] == nil {
            let redisStorage = RedisStorage()
            self.storage[RedisesStorageKey.self] = redisStorage
            self.lifecycle.use(RedisStorage.Lifecycle(redisStorage: redisStorage))
        }
        return self.storage[RedisesStorageKey.self]!
    }
}

class RedisStorage {
    private var lock: Lock
    private var configurations: [RedisID: RedisConfiguration]
    fileprivate var pools: [PoolKey: RedisConnectionPool] {
        willSet {
            if didBoot {
                fatalError("editing pools after application has booted is not supported")
            } else {
                didBoot = true
            }
        }
    }
    private var didBoot: Bool = false

    init() {
        self.configurations = [:]
        self.pools = [:]
        self.lock = .init()
    }

    func use(_ redisConfiguration: RedisConfiguration, as id: RedisID = .default) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.configurations[id] = redisConfiguration
    }

    func pool(for eventLoop: EventLoop, id redisID: RedisID) -> RedisConnectionPool {
        let key = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)
        guard let pool = pools[key] else {
            fatalError("No redis found for id \(redisID), or the app may not have finished booting. Also, the eventLoop must be from Application's EventLoopGroup.")
        }
        return pool
    }

    func configuration(for id: RedisID = .default) -> RedisConfiguration? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.configurations[id]
    }

    func ids() -> Set<RedisID> {
        return self.lock.withLock { Set(self.configurations.keys) }
    }
}

extension RedisStorage {
    /// Lifecyle Handler for Redis Storage. On boot, it creates a RedisConnectionPool for each
    /// configurated `RedisID` on each `EventLoop`.
    class Lifecycle: LifecycleHandler {
        unowned let redisStorage: RedisStorage
        init(redisStorage: RedisStorage) {
            self.redisStorage = redisStorage
        }

        func willBoot(_ application: Application) throws {
            self.redisStorage.lock.lock()
            defer {
                self.redisStorage.lock.unlock()
            }
            var newPools = [PoolKey: RedisConnectionPool]()
            for eventLoop in application.eventLoopGroup.makeIterator() {
                for (redisID, configuration) in redisStorage.configurations {
                    let newPool = RedisConnectionPool(
                        configuration: .init(configuration, defaultLogger: application.logger),
                        boundEventLoop: eventLoop)

                    let newKey: PoolKey = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)
                    newPools[newKey] = newPool
                }
            }

            self.redisStorage.pools = newPools
        }

        /// Close each connection pool
        func shutdown(_ application: Application) {
            self.redisStorage.lock.lock()
            defer {
                self.redisStorage.lock.unlock()
            }
            let shutdownFuture: EventLoopFuture<Void> = redisStorage.pools.values.map { pool in
                let promise = pool.eventLoop.makePromise(of: Void.self)
                pool.close(promise: promise)
                return promise.futureResult
            }.flatten(on: application.eventLoopGroup.next())

            do {
                try shutdownFuture.wait()
            } catch {
                application.logger.error("Error shutting down redis connection pools, possibly because the pool never connected to the Redis server: \(error)")
            }
        }
    }
}

private extension RedisStorage {
    /// Since a `RedisConnectionPool` is created for each `RedisID` on each `EventLoop`, combining
    /// the `RedisID` and the `EventLoop` into one key simplifies the storage dictionary
    struct PoolKey: Hashable, StorageKey {
        typealias Value = RedisConnectionPool

        let eventLoopKey: EventLoop.Key
        let redisID: RedisID
    }
}

private extension EventLoop {
    typealias Key = ObjectIdentifier
    var key: Key {
        ObjectIdentifier(self)
    }
}
