import Vapor

extension Application {
    private struct RedisesStorageKey: StorageKey {
        typealias Value = RedisStorage
    }
    public var redises: RedisStorage {
        if self.storage[RedisesStorageKey.self] == nil {
            let redisStorage = RedisStorage()
            self.storage[RedisesStorageKey.self] = redisStorage
            self.lifecycle.use(RedisStorage.Lifecycle(redisStorage: redisStorage))
        }
        return self.storage[RedisesStorageKey.self]!
    }
}

public class RedisStorage {
    private var lock: Lock
    private var configurations: [RedisID: RedisConfiguration]
    fileprivate var pools: [PoolKey: RedisConnectionPool]

    public init() {
        self.configurations = [:]
        self.pools = [:]
        self.lock = .init()
    }

    public func use(_ redisConfiguration: RedisConfiguration, as id: RedisID = .default) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.configurations[id] = redisConfiguration
    }

    public func pool(for eventLoop: EventLoop, id redisID: RedisID) -> RedisConnectionPool {
        let key = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)
        guard let pool = pools[key] else {
            fatalError("No redis found for id \(redisID), or the app may not have finished booting. Also, the eventLoop must be from Application's EventLoopGroup.")
        }
        return pool
    }

    public func configuration(for id: RedisID = .default) -> RedisConfiguration? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.configurations[id]
    }

    public func ids() -> Set<RedisID> {
        return self.lock.withLock { Set(self.configurations.keys) }
    }
}

extension RedisStorage {
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
                for configuration in redisStorage.configurations {
                    let newPool = RedisConnectionPool(
                        configuration: .init(configuration.value, defaultLogger: application.logger),
                        boundEventLoop: eventLoop
                    )
                    let newKey: PoolKey = PoolKey(eventLoopKey: eventLoop.key, redisID: configuration.key)
                    newPools[newKey] = newPool
                }
            }
            self.redisStorage.pools = newPools
        }

        func shutdown(_ application: Application) {
            let shutdownFuture = redisStorage.pools.values.map { pool in
                let promise = pool.eventLoop.makePromise(of: Void.self)
                pool.close(promise: promise)
                return promise.futureResult
            }.flatten(on: application.eventLoopGroup.next())

            do {
                try shutdownFuture.wait()
            } catch {
                application.logger.error("Error shutting down redis connection pools: \(error)")
            }
        }
    }
}

private extension RedisStorage {
    struct PoolKey: Hashable {
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
