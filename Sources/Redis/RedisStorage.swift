import Vapor
import NIOConcurrencyHelpers

extension Application {
    private struct RedisStorageKey: StorageKey {
        typealias Value = RedisStorage
    }
    var redisStorage: RedisStorage {
        if let existing = self.storage[RedisStorageKey.self] {
            return existing
        }

        let redisStorage = RedisStorage()
        self.storage[RedisStorageKey.self] = redisStorage
        self.lifecycle.use(RedisStorage.Lifecycle(redisStorage: redisStorage))
        return redisStorage
    }
}

final class RedisStorage {
    private var lock: NIOLock
    private var configurations: [RedisID: RedisConfiguration]
    fileprivate var pools: [PoolKey: RedisConnectionPool] {
        willSet {
            guard pools.isEmpty else {
                fatalError("Modifying connection pools after application has booted is not supported")
            }
        }
    }

    init() {
        self.configurations = [:]
        self.pools = [:]
        self.lock = .init()
    }

    func use(_ redisConfiguration: RedisConfiguration, as id: RedisID = .default) {
        self.configurations[id] = redisConfiguration
    }

    func configuration(for id: RedisID = .default) -> RedisConfiguration? {
        self.configurations[id]
    }

    func ids() -> Set<RedisID> {
        Set(self.configurations.keys)
    }

    func pool(for eventLoop: EventLoop, id redisID: RedisID) -> RedisConnectionPool {
        let key = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)
        guard let pool = pools[key] else {
            fatalError("No redis found for id \(redisID), or the app may not have finished booting. Also, the eventLoop must be from Application's EventLoopGroup.")
        }
        return pool
    }
}

extension RedisStorage {
    /// Lifecyle Handler for Redis Storage. On boot, it creates a RedisConnectionPool for each
    /// configurated `RedisID` on each `EventLoop`.
    final class Lifecycle: LifecycleHandler {
        unowned let redisStorage: RedisStorage
        init(redisStorage: RedisStorage) {
            self.redisStorage = redisStorage
        }

        func didBoot(_ application: Application) throws {
            self.redisStorage.lock.lock()
            defer {
                self.redisStorage.lock.unlock()
            }
            var newPools: [PoolKey: RedisConnectionPool] = [:]
            for eventLoop in application.eventLoopGroup.makeIterator() {
                for (redisID, configuration) in redisStorage.configurations {

                    let newKey: PoolKey = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)

                    let newPool = RedisConnectionPool(
                        configuration: .init(configuration, defaultLogger: application.logger),
                        boundEventLoop: eventLoop)

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
