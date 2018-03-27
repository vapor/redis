import Async
import DatabaseKit
import Service

/// Provides base `Redis` services such as database and connection.
public final class RedisProvider: Provider {
    /// See `Provider.repositoryName`
    public static let repositoryName = "redis"

    /// Creates a new `PostgreSQLProvider`.
    public init() {}

    /// See `Provider.register`
    public func register(_ services: inout Services) throws {
        try services.register(DatabaseKitProvider())
        services.register(RedisClientConfig.self)
        services.register(RedisDatabase.self)
        var databases = DatabaseConfig()
        databases.add(database: RedisDatabase.self, as: .redis)
        services.register(databases)
    }

    /// See `Provider.boot`
    public func didBoot(_ worker: Container) throws -> Future<Void> {
        return .done(on: worker)
    }
}

/// MARK: Services
extension RedisClientConfig: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> RedisClientConfig {
        return .init()
    }
}
extension RedisDatabase: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> RedisDatabase {
        return try .init(config: worker.make())
    }
}
