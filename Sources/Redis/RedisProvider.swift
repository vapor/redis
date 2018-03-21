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
        services.register(RedisClient.self)
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
        return .default()
    }
}
extension RedisClient: ServiceType {
    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> RedisClient {
        let config = try worker.make(RedisClientConfig.self)
        return try RedisClient.connect(
            hostname: config.hostname,
            port: config.port,
            on: worker
        ) { error in
            print("[Redis] \(error)")
        }.wait()
    }
}
