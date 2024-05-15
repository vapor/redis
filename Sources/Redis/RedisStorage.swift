import Vapor
import NIOConcurrencyHelpers
import NIOCore
import NIOPosix
import NIOSSL
@preconcurrency import RediStack

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

final class RedisStorage: Sendable {
    fileprivate struct StorageBox: Sendable {
        var configurations: [RedisID: RedisConfiguration]
        var pools: [PoolKey: RedisConnectionPool] {
            willSet {
                guard self.pools.isEmpty else {
                    fatalError("Modifying connection pools after application has booted is not supported")
                }
            }
        }
    }
    private let box: NIOLockedValueBox<StorageBox>

    init() {
        self.box = .init(.init(configurations: [:], pools: [:]))
    }

    func use(_ redisConfiguration: RedisConfiguration, as id: RedisID = .default) {
        self.box.withLockedValue { $0.configurations[id] = redisConfiguration }
    }

    func configuration(for id: RedisID = .default) -> RedisConfiguration? {
        self.box.withLockedValue { $0.configurations[id] }
    }

    func ids() -> Set<RedisID> {
        Set(self.box.withLockedValue { $0.configurations.keys })
    }

    func pool(for eventLoop: EventLoop, id redisID: RedisID) -> RedisConnectionPool {
        let key = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)
        guard let pool = self.box.withLockedValue({ $0.pools[key] }) else {
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
            var newPools: [PoolKey: RedisConnectionPool] = [:]
            for eventLoop in application.eventLoopGroup.makeIterator() {
                redisStorage.box.withLockedValue { storageBox in
                    for (redisID, configuration) in storageBox.configurations {

                        let newKey: PoolKey = PoolKey(eventLoopKey: eventLoop.key, redisID: redisID)

                        let redisTLSClient: ClientBootstrap? = {
                            guard let tlsConfig = configuration.tlsConfiguration,
                                    let tlsHost = configuration.tlsHostname else { return nil }

                            return ClientBootstrap(group: eventLoop)
                                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                                .channelInitializer { channel in
                                    do {
                                        let sslContext = try NIOSSLContext(configuration: tlsConfig)
                                        return EventLoopFuture.andAllSucceed([
                                            channel.pipeline.addHandler(try NIOSSLClientHandler(context: sslContext,
                                                                                                serverHostname: tlsHost)),
                                            channel.pipeline.addBaseRedisHandlers()
                                        ], on: channel.eventLoop)
                                    } catch {
                                        return channel.eventLoop.makeFailedFuture(error)
                                    }
                                }
                        }()

                        let newPool = RedisConnectionPool(
                            configuration: .init(configuration, defaultLogger: application.logger, customClient: redisTLSClient),
                            boundEventLoop: eventLoop)

                        newPools[newKey] = newPool
                    }
                }
            }

            self.redisStorage.box.withLockedValue { $0.pools = newPools }
        }

        /// Close each connection pool
        func shutdown(_ application: Application) {
            let shutdownFuture: EventLoopFuture<Void> = redisStorage.box.withLockedValue { $0.pools.values }.map { pool in
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
        
        func shutdownAsync(_ application: Application) async {
            let shutdownFuture: EventLoopFuture<Void> = redisStorage.box.withLockedValue { $0.pools.values }.map { pool in
                let promise = pool.eventLoop.makePromise(of: Void.self)
                pool.close(promise: promise)
                return promise.futureResult
            }.flatten(on: application.eventLoopGroup.next())

            do {
                try await shutdownFuture.get()
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
