import Vapor

extension Application {
    public var redis: Redis {
        .init(application: self)
    }

    public class Redis: Extendable {
        public var extend: Extend
        
        struct ConfigurationKey: StorageKey {
            typealias Value = RedisConfiguration
        }

        public var configuration: RedisConfiguration? {
            get {
                self.application.storage[ConfigurationKey.self]
            }
            set {
                if self.application.storage.contains(PoolKey.self) {
                    fatalError("Cannot modify your Redis configuration after redis has been used")
                }
                self.application.storage[ConfigurationKey.self] = newValue
            }
        }

        struct PoolKey: StorageKey, LockKey {
            typealias Value = EventLoopGroupConnectionPool<RedisConnectionSource>
        }

        internal var pool: EventLoopGroupConnectionPool<RedisConnectionSource> {
            if let existing = self.application.storage[PoolKey.self] {
                return existing
            } else {
                let lock = self.application.locks.lock(for: PoolKey.self)
                lock.lock()
                defer { lock.unlock() }
                guard let configuration = self.configuration else {
                    fatalError("Redis not configured. Use app.redis.configuration = ...")
                }
                let new = EventLoopGroupConnectionPool(
                    source: RedisConnectionSource(configuration: configuration, logger: self.application.logger),
                    maxConnectionsPerEventLoop: 1,
                    logger: self.application.logger,
                    on: self.application.eventLoopGroup
                )
                self.application.storage.set(PoolKey.self, to: new) {
                    $0.shutdown()
                }
                return new
            }
        }

        let application: Application
        
        internal init(application: Application) {
            self.application = application
            self.extend = .init()
        }
    }
}

extension Application.Redis: RedisClient {
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
        self.application.redis.pool.withConnection(
            logger: logger,
            on: nil
        ) {
            $0.setLogging(to: self.logger)
            return $0.send(command: command, with: arguments)
        }
    }
}
