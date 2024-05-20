import NIOConcurrencyHelpers
import NIOCore
import NIOPosix
import NIOSSL
import RediStack
import Vapor

extension Application {
    private struct RedisStorageKey: StorageKey {
        typealias Value = RedisStorage
    }

    var redisStorage: RedisStorage {
        if let existing = storage[RedisStorageKey.self] {
            return existing
        }

        let redisStorage = RedisStorage()
        storage[RedisStorageKey.self] = redisStorage
        lifecycle.use(RedisStorage.Lifecycle(redisStorage: redisStorage))
        return redisStorage
    }
}

final class RedisStorage {
    private let lock: NIOLock

    private var configurations: [RedisID: RedisFactory]
    private var pools: [PoolKey: RedisClient] {
        willSet {
            guard pools.isEmpty else {
                fatalError("Modifying connection pools after application has booted is not supported")
            }
        }
    }

    init() {
        configurations = [:]
        pools = [:]
        lock = .init()
    }

    func use(_ configuration: RedisFactory, as id: RedisID) {
        configurations[id] = configuration
    }

    func pool(for eventLoop: EventLoop, id redisID: RedisID) -> RedisClient {
        let key = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)
        guard let pool = pools[key] else {
            fatalError("No redis found for id \(redisID), or the app may not have finished booting. Also, the eventLoop must be from Application's EventLoopGroup.")
        }
        return pool
    }
}

extension RedisStorage {
    func bootstrap(application: Application) {
        lock.lock()
        defer { lock.unlock() }
        pools = configurations.reduce(into: [PoolKey: RedisClient]()) { pools, instance in
            let (id, configuration) = instance

            application
                .eventLoopGroup
                .makeIterator()
                .forEach { eventLoop in
                    let newKey: PoolKey = .init(eventLoopKey: eventLoop.key, redisID: id)
                    let newPool: RedisClient = configuration.make(for: eventLoop, logger: application.logger)

                    pools[newKey] = newPool
                }
        }
    }

    func shutdown(application: Application) {
        lock.lock()
        defer { lock.unlock() }

        let shutdownFuture: EventLoopFuture<Void> = pools.values.compactMap { pool in
            guard let pool = pool as? RedisConnectionPool else { return nil }

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

extension RedisStorage {
    /// Lifecyle Handler for Redis Storage. On boot, it creates a RedisConnectionPool for each
    /// configurated `RedisID` on each `EventLoop`.
    final class Lifecycle: LifecycleHandler {
        unowned let redisStorage: RedisStorage
        init(redisStorage: RedisStorage) {
            self.redisStorage = redisStorage
        }

        /// Prepare each instance on each connection pool
        func didBoot(_ application: Application) throws {
            redisStorage.bootstrap(application: application)
        }

        /// Close each connection pool
        func shutdown(_ application: Application) {
            redisStorage.shutdown(application: application)
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
