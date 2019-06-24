import Vapor

public struct RedisProvider: Provider {
    public init() { }

    public func register(_ s: inout Services) {
        s.register(RedisConnectionSource.self) { c in
            return try RedisConnectionSource(config: c.make(), eventLoop: c.eventLoop)
        }

        s.register(ConnectionPoolConfig.self) { c in
            return .init()
        }

        s.singleton(ConnectionPool<RedisConnectionSource>.self, boot: { c in
            return try ConnectionPool(config: c.make(), source: c.make())
        }, shutdown: { pool in
            try pool.close().wait()
        })

        s.register(RedisClient.self) { c in
            return try c.make(ConnectionPool<RedisConnectionSource>.self)
        }

        s.register(RedisConfiguration.self) { c in
            return try RedisConfiguration(logger: c.make(Logger.self))
        }
    }
}
