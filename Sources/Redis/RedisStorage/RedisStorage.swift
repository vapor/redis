import NIOConcurrencyHelpers
import Vapor

final class RedisStorage {
    private let lock: NIOLock

    private var configurations: [RedisID: RedisConfigurationFactory]
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

    func use(_ configuration: RedisConfigurationFactory, as id: RedisID) {
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
                    let newPool: RedisClient = configuration
                        .make()
                        .makeClient(for: eventLoop, logger: application.logger)

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
