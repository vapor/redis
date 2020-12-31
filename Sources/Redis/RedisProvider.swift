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
            var allPools = [AllPoolsKey: RedisConnectionPool]()
            for eventLoop in application.eventLoopGroup.makeIterator() {

                for configuration in redises.configurations {
                    let newPool = RedisConnectionPool(
                        configuration: .init(configuration.value, defaultLogger: application.logger),
                        boundEventLoop: eventLoop
                    )
                    let newKey: AllPoolsKey = AllPoolsKey(eventLoopKey: eventLoop.key, redisID: configuration.key)
                    allPools[newKey] = newPool
                }
            }
            self.redises.allPools = allPools
        }

        func shutdown(_ application: Application) {
            let shutdownFuture = redises.allPools.values.map { pool in
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

struct AllPoolsKey: Hashable {
    let eventLoopKey: EventLoop.Key
    let redisID: RedisID
}

public class Redises {
    private var lock: Lock
    private var configurations: [RedisID: RedisConfiguration]
    private var defaultID: RedisID?
    internal fileprivate(set) var allPools: [AllPoolsKey: RedisConnectionPool] = [:]

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

    public func configuration(for id: RedisID = .default) -> RedisConfiguration? {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.configurations[id]
    }

    public func ids() -> Set<RedisID> {
        return self.lock.withLock { Set(self.configurations.keys) }
    }
}
