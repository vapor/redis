@_exported import struct Foundation.URL
@_exported import struct Logging.Logger
@_exported import struct NIO.TimeAmount
import enum NIO.SocketAddress

/// Configuration for connection to one or more Redis instances with Vapor.
public typealias RedisConfiguration = RedisConnectionPool.Configuration

extension RedisConfiguration {
    public typealias ValidationError = RedisConnection.Configuration.ValidationError

    public static var defaultConnectionCountBehavior: RedisConnectionPool.ConnectionCountBehavior {
        return .strict(maximumConnectionCount: 2, minimumConnectionCount: 0)
    }
    public static var defaultRetryStrategy: RedisConnectionPool.PoolConnectionRetryStrategy { .exponentialBackoff() }
}

// MARK: Convenience Initializers

extension RedisConfiguration {
    public init(
        hostname: String,
        port: Int = RedisConnection.Configuration.defaultPort,
        password: String? = nil,
        database: Int? = nil,
        connectionCountBehavior: RedisConnectionPool.ConnectionCountBehavior = Self.defaultConnectionCountBehavior,
        connectionRetryStrategy: RedisConnectionPool.PoolConnectionRetryStrategy = Self.defaultRetryStrategy,
        poolDefaultLogger: Logger? = nil,
        connectionDefaultLogger: Logger? = nil
    ) throws {
        self.init(
            initialServerConnectionAddresses: [try .makeAddressResolvingHost(hostname, port: port)],
            connectionCountBehavior: connectionCountBehavior,
            connectionConfiguration: .init(
                initialDatabase: database,
                password: password,
                defaultLogger: connectionDefaultLogger
            ),
            retryStrategy: connectionRetryStrategy,
            poolDefaultLogger: poolDefaultLogger
        )
    }

    public init(
        url string: String,
        connectionCountBehavior: RedisConnectionPool.ConnectionCountBehavior = Self.defaultConnectionCountBehavior,
        connectionRetryStrategy: RedisConnectionPool.PoolConnectionRetryStrategy = Self.defaultRetryStrategy,
        poolDefaultLogger: Logger? = nil,
        connectionDefaultLogger: Logger? = nil
    ) throws {
        guard let url = URL(string: string) else { throw ValidationError.invalidURLString }
        try self.init(
            url: url,
            connectionCountBehavior: connectionCountBehavior,
            connectionRetryStrategy: connectionRetryStrategy,
            poolDefaultLogger: poolDefaultLogger,
            connectionDefaultLogger: connectionDefaultLogger
        )
    }

    public init(
        url: URL,
        connectionCountBehavior: RedisConnectionPool.ConnectionCountBehavior = Self.defaultConnectionCountBehavior,
        connectionRetryStrategy: RedisConnectionPool.PoolConnectionRetryStrategy = Self.defaultRetryStrategy,
        poolDefaultLogger: Logger? = nil,
        connectionDefaultLogger: Logger? = nil
    ) throws {
        guard
            let scheme = url.scheme,
            !scheme.isEmpty
        else { throw ValidationError.missingURLScheme }
        guard scheme == "redis" else { throw ValidationError.invalidURLScheme }
        guard let host = url.host, !host.isEmpty else { throw ValidationError.missingURLHost }

        try self.init(
            hostname: host,
            port: url.port ?? RedisConnection.Configuration.defaultPort,
            password: url.password,
            database: Int(url.lastPathComponent),
            connectionCountBehavior: connectionCountBehavior,
            connectionRetryStrategy: connectionRetryStrategy,
            poolDefaultLogger: poolDefaultLogger,
            connectionDefaultLogger: connectionDefaultLogger
        )
    }

    public init(
        serverAddresses: [SocketAddress],
        password: String? = nil,
        database: Int? = nil,
        connectionCountBehavior: RedisConnectionPool.ConnectionCountBehavior = Self.defaultConnectionCountBehavior,
        connectionRetryStrategy: RedisConnectionPool.PoolConnectionRetryStrategy = Self.defaultRetryStrategy,
        poolDefaultLogger: Logger? = nil,
        connectionDefaultLogger: Logger? = nil
    ) {
        self.init(
            initialServerConnectionAddresses: serverAddresses,
            connectionCountBehavior: connectionCountBehavior,
            connectionConfiguration: .init(
                initialDatabase: database,
                password: password,
                defaultLogger: connectionDefaultLogger
            ),
            retryStrategy: connectionRetryStrategy,
            poolDefaultLogger: poolDefaultLogger
        )
    }
}

// MARK: Internal Configuration Creation

extension RedisConnectionPool.PoolConnectionConfiguration {
    internal func logging(to newLogger: Logger) -> Self {
        return .init(
            initialDatabase: self.initialDatabase,
            password: self.password,
            defaultLogger: newLogger,
            tcpClient: self.tcpClient
        )
    }
}

extension RedisConnectionPool.Configuration {
    internal func logging(to newLogger: Logger) -> Self {
        return .init(
            initialServerConnectionAddresses: self.initialConnectionAddresses,
            connectionCountBehavior: self.connectionCountBehavior,
            connectionConfiguration: self.connectionConfiguration.logging(to: newLogger),
            retryStrategy: self.retryStrategy,
            poolDefaultLogger: newLogger
        )
    }
}
