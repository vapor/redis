import Async
import DatabaseKit
import Service

/// Provides base `Redis` services such as database and connection.
public final class RedisProvider: Provider {
    /// Creates a new `RedisProvider`.
    public init() {}

    /// See `Provider`.
    public func register(_ services: inout Services) throws {
        try services.register(DatabaseKitProvider())
        services.register(RedisClientConfig.self)
        services.register(RedisDatabase.self)
        var databases = DatabasesConfig()
        databases.add(database: RedisDatabase.self, as: .redis)
        services.register(databases)
        
        services.register(KeyedCache.self) { container -> RedisCache in
            let pool = try container.connectionPool(to: .redis)
            return .init(pool: pool)
        }
    }

    /// See `Provider`.
    public func didBoot(_ worker: Container) throws -> Future<Void> {
        return .done(on: worker)
    }
}

/// MARK: Services
extension RedisClientConfig: ServiceType {
    /// See `ServiceType`.
    public static func makeService(for worker: Container) throws -> RedisClientConfig {
        return .init()
    }
}
extension RedisDatabase: ServiceType {
    /// See `ServiceType`.
    public static func makeService(for worker: Container) throws -> RedisDatabase {
        return try .init(config: worker.make())
    }
}

/// Convenience type-alias for a Redis-based cache.
public typealias RedisCache = DatabaseKeyedCache<ConfiguredDatabase<RedisDatabase>>
