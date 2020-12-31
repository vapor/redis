import Foundation
import Vapor


extension Application {
    private struct RedisesStorageKey: StorageKey {
        typealias Value = Redises
    }
    public var redises: Redises {
        if self.storage[RedisesStorageKey.self] == nil {
            let new = Redises()
            self.storage[RedisesStorageKey.self] = new
            self.lifecycle.use(Redises.Lifecycle(redises: new))
        }
        return self.storage[RedisesStorageKey.self]!
    }
}

extension Redises {
    class Lifecycle: LifecycleHandler {
        let redises: Redises
        init(redises: Redises) {
            self.redises = redises
        }
        func willBoot(_ application: Application) throws {
            self.redises.lock.lock()
            defer {
                self.redises.lock.unlock()
            }
            var allPools = [EventLoop.Key: [RedisID: RedisConnectionPool]]()
            for eventLoop in application.eventLoopGroup.makeIterator() {
                var eventLoopPools = [RedisID: RedisConnectionPool]()
                for configuration in redises.configurations {
                    eventLoopPools[configuration.key] = RedisConnectionPool(
                        configuration: .init(configuration.value, defaultLogger: application.logger),
                        boundEventLoop: eventLoop
                    )
                }
                allPools[eventLoop.key] = eventLoopPools
            }
            self.redises.allPools = allPools
        }

        func shutdown(_ application: Application) {
            let shutdownFuture = redises.allPools.values.map { pools in
                return pools.values.map { pool in
                    let promise = pool.eventLoop.makePromise(of: Void.self)
                    pool.close(promise: promise)
                    return promise.futureResult
                }.flatten(on: application.eventLoopGroup.next())
            }.flatten(on: application.eventLoopGroup.next())

            do {
                try shutdownFuture.wait()
            } catch {
                application.logger.error("Error shutting down redis connection pools: \(error)")
            }
        }
    }
}

public class Redises {
    private var lock: Lock
    private var configurations: [RedisID: RedisConfiguration]
    private var defaultID: RedisID?
    internal fileprivate(set) var allPools: [EventLoop.Key: [RedisID: RedisConnectionPool]] = [:]

    public init() {
        self.configurations = [:]
        self.lock = .init()
    }

    public func use(_ redisConfiguration: RedisConfiguration, as id: RedisID = .default) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.configurations[id] = redisConfiguration
    }

    public func `default`(to id: RedisID) {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.defaultID = id
    }

    public func configuration(for id: RedisID? = nil) -> RedisConfiguration? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.configurations[id ?? self._requireDefaultID()]
    }

    public func ids() -> Set<RedisID> {
        return self.lock.withLock { Set(self.configurations.keys) }
    }

    private func _requireConfiguration(for id: RedisID) -> RedisConfiguration {
        guard let configuration = self.configurations[id] else {
            fatalError("No redis configuration registered for \(id).")
        }
        return configuration
    }

    private func _requireDefaultID() -> RedisID {
        guard let id = self.defaultID else {
            fatalError("No default redis configured.")
        }
        return id
    }
}
