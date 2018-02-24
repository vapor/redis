import DatabaseKit
import Service

/// Registers Redis services to your container.
public final class RedisProvider: Provider {
    /// See `Provider.repositoryName`
    public static let repositoryName = "redis"

    /// Creates a new `RedisProvider`
    public init() { }

    /// See `Provider.register`
    public func register(_ services: inout Services) throws {
        services.register(RedisClient.self)
        services.register(RedisClientConfig.self)
    }

    /// See `Provider.boot`
    public func boot(_ worker: Container) throws { }
}

extension RedisClient: ServiceType {
    /// See `ServiceType.serviceSupports`
    public static var serviceSupports: [Any.Type] { return [KeyedCache.self] }

    /// See `ServiceType.makeService(for:)`
    public static func makeService(for worker: Container) throws -> RedisClient {
        let config = try worker.make(RedisClientConfig.self, for: RedisClient.self)
        return try RedisClient.connect(
            hostname: config.hostname,
            port: config.port,
            on: worker
        ) { _, error in
            print("[Redis] \(error)")
        }
    }
}

extension RedisClientConfig: ServiceType {
    /// See `ServiceType.makeService(for:)`
    static func makeService(for worker: Container) throws -> RedisClientConfig {
        return .default()
    }
}
