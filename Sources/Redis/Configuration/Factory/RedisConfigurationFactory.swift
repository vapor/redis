import Foundation
import NIOCore
import NIOSSL

public struct RedisConfigurationFactory {
    typealias ValidationError = RedisConfiguration.ValidationError

    public let make: () -> RedisFactory

    public init(make: @escaping () -> RedisFactory) {
        self.make = make
    }
}

extension RedisConfigurationFactory {
    public static func standalone(
        url string: String,
        tlsConfiguration: TLSConfiguration? = nil,
        pool: RedisConfiguration.PoolOptions = .init(),
        logger: Logger? = nil
    ) throws -> Self {
        guard let url = URL(string: string) else { throw ValidationError.invalidURLString }
        return try standalone(url: url, tlsConfiguration: tlsConfiguration, pool: pool, logger: logger)
    }

    public static func standalone(
        url: URL,
        tlsConfiguration: TLSConfiguration? = nil,
        pool: RedisConfiguration.PoolOptions = .init(),
        logger: Logger? = nil
    ) throws -> Self {
        guard
            let scheme = url.scheme,
            !scheme.isEmpty
        else { throw ValidationError.missingURLScheme }

        guard scheme == "redis" || scheme == "rediss" else { throw ValidationError.invalidURLScheme }
        guard let host = url.host, !host.isEmpty else { throw ValidationError.missingURLHost }

        let defaultTLSConfig: TLSConfiguration?
        if scheme == "rediss" {
            // If we're given a 'rediss' URL, make sure we have at least a default TLS config.
            defaultTLSConfig = tlsConfiguration ?? .makeClientConfiguration()
        } else {
            defaultTLSConfig = tlsConfiguration
        }

        return try standalone(
            hostname: host,
            port: url.port ?? RedisConnection.Configuration.defaultPort,
            password: url.password,
            tlsConfiguration: defaultTLSConfig,
            database: Int(url.lastPathComponent),
            pool: pool,
            logger: logger
        )
    }

    public static func standalone(
        hostname: String,
        port: Int = RedisConnection.Configuration.defaultPort,
        password: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        database: Int? = nil,
        pool: RedisConfiguration.PoolOptions = .init(),
        logger: Logger? = nil
    ) throws -> Self {
        if let database, database < 0 {
            throw ValidationError.outOfBoundsDatabaseID
        }

        return try standalone(
            serverAddresses: [.makeAddressResolvingHost(hostname, port: port)],
            password: password,
            tlsConfiguration: tlsConfiguration,
            tlsHostname: hostname,
            database: database,
            pool: pool,
            logger: logger
        )
    }

    public static func standalone(
        serverAddresses: [SocketAddress],
        password: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        tlsHostname: String? = nil,
        database: Int? = nil,
        pool: RedisConfiguration.PoolOptions = .init(),
        logger: Logger? = nil
    ) throws -> Self {
        .init {
            RedisConfiguration(
                serverAddresses: serverAddresses,
                password: password,
                database: database,
                pool: pool,
                tlsConfiguration: tlsConfiguration,
                tlsHostname: tlsHostname,
                logger: logger
            )
        }
    }
}
