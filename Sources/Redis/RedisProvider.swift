import Vapor

public struct RedisProvider: Provider {
    public init() { }

    public func register(_ app: Application) {
        app.register(RedisConnectionSource.self) { app in
            return RedisConnectionSource(configuration: app.make())
        }

        app.register(singleton: ConnectionPool<RedisConnectionSource>.self, boot: { app in
            return ConnectionPool(configuration: app.make(), source: app.make(), logger: app.make(Logger.self), on: app.make())
        }) { pool in
            return pool.shutdown()
        }

        app.register(RedisClient.self) { app in
            return app.make(ConnectionPool<RedisConnectionSource>.self)
        }

        app.register(RedisConfiguration.self) { app in
            return RedisConfiguration(logger: app.make(Logger.self))
        }
    }
}
