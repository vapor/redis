import Foundation
import Logging
import NIOCore
import NIOSSL
import RediStack

/// Configuration for connecting to a Redis instance
public struct RedisConfiguration {
    public typealias ValidationError = RedisConnection.Configuration.ValidationError

    public let serverAddresses: [SocketAddress]
    public let password: String?
    public let database: Int?
    public let pool: PoolOptions
    public let tlsConfiguration: TLSConfiguration?
    public let tlsHostname: String?

    let factory: RedisFactory.Type
    var provider: RedisFactory {
        factory.init(configuration: self)
    }

    public init(url string: String, tlsConfiguration: TLSConfiguration? = nil, pool: PoolOptions = .init()) throws {
        guard let url = URL(string: string) else { throw ValidationError.invalidURLString }
        try self.init(url: url, tlsConfiguration: tlsConfiguration, pool: pool)
    }

    public init(url: URL, tlsConfiguration: TLSConfiguration? = nil, pool: PoolOptions = .init()) throws {
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

        try self.init(
            hostname: host,
            port: url.port ?? RedisConnection.Configuration.defaultPort,
            password: url.password,
            tlsConfiguration: defaultTLSConfig,
            database: Int(url.lastPathComponent),
            pool: pool
        )
    }

    public init(
        hostname: String,
        port: Int = RedisConnection.Configuration.defaultPort,
        password: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        database: Int? = nil,
        pool: PoolOptions = .init()
    ) throws {
        if let database, database < 0 {
            throw ValidationError.outOfBoundsDatabaseID
        }

        try self.init(
            serverAddresses: [.makeAddressResolvingHost(hostname, port: port)],
            password: password,
            tlsConfiguration: tlsConfiguration,
            tlsHostname: hostname,
            database: database,
            pool: pool
        )
    }

    public init(
        serverAddresses: [SocketAddress],
        password: String? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        tlsHostname: String? = nil,
        database: Int? = nil,
        pool: PoolOptions = .init()
    ) throws {
        self.serverAddresses = serverAddresses
        self.password = password
        self.tlsConfiguration = tlsConfiguration
        self.tlsHostname = tlsHostname
        self.database = database
        self.pool = pool
        factory = RedisProvider.self
    }
}
