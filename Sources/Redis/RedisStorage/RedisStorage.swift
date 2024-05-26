import NIOConcurrencyHelpers
@preconcurrency import RediStack
import Vapor

final class RedisStorage: Sendable {
    fileprivate struct StorageBox: Sendable {
        var configurations: [RedisID: RedisConfigurationFactory]
        var pools: [PoolKey: RedisClient] {
            willSet {
                guard pools.isEmpty else {
                    fatalError("Modifying connection pools after application has booted is not supported")
                }
            }
        }
    }

    private let box: NIOLockedValueBox<StorageBox>

    init() {
        box = .init(.init(configurations: [:], pools: [:]))
    }

    func use(_ configuration: RedisConfigurationFactory, as id: RedisID) {
        box.withLockedValue { $0.configurations[id] = configuration }
    }

    func pool(for eventLoop: EventLoop, id redisID: RedisID) -> RedisClient {
        let key = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)
        guard let pool = box.withLockedValue({ $0.pools[key] }) else {
            fatalError("No redis found for id \(redisID), or the app may not have finished booting. Also, the eventLoop must be from Application's EventLoopGroup.")
        }
        return pool
    }
}

extension RedisStorage {
    func bootstrap(application: Application) {
        box.withLockedValue {
            $0.pools = $0.configurations.reduce(into: [PoolKey: RedisClient]()) { pools, instance in
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
    }

    func shutdown(application: Application) -> EventLoopFuture<Void> {
        box.withLockedValue {
            let shutdownFuture: EventLoopFuture<Void> = $0.pools.values.compactMap { pool in
                guard let pool = pool as? RedisConnectionPool else { return nil }
                
                let promise = pool.eventLoop.makePromise(of: Void.self)
                pool.close(promise: promise)
                return promise.futureResult
            }.flatten(on: application.eventLoopGroup.next())
            
            return shutdownFuture
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
