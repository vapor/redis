import Foundation
import NIOSSL
import NIOPosix
import Logging
import NIOCore
@preconcurrency import RediStack

/// Configuration for connecting to a Redis instance
public struct RedisConfiguration: Sendable {
    public typealias ValidationError = RedisConnection.Configuration.ValidationError

    public var serverAddresses: [SocketAddress]
    public var password: String?
    public var database: Int?
    public var pool: PoolOptions
    public var tlsConfiguration: TLSConfiguration?
    public var tlsHostname: String?

    internal var deferredHostname: String?
    internal var deferredPort: Int?

    public var hasUnresolvedHostname: Bool {
        return deferredHostname != nil
    }

    public struct PoolOptions: Sendable {
        public var maximumConnectionCount: RedisConnectionPoolSize
        public var minimumConnectionCount: Int
        public var connectionBackoffFactor: Float32
        public var initialConnectionBackoffDelay: TimeAmount
        public var connectionRetryTimeout: TimeAmount?
        public var onUnexpectedConnectionClose: (@Sendable (RedisConnection) -> Void)?

        @preconcurrency
        public init(
            maximumConnectionCount: RedisConnectionPoolSize = .maximumActiveConnections(2),
            minimumConnectionCount: Int = 0,
            connectionBackoffFactor: Float32 = 2,
            initialConnectionBackoffDelay: TimeAmount = .milliseconds(100),
            connectionRetryTimeout: TimeAmount? = nil,
            onUnexpectedConnectionClose: (@Sendable (RedisConnection) -> Void)? = nil
        ) {
            self.maximumConnectionCount = maximumConnectionCount
            self.minimumConnectionCount = minimumConnectionCount
            self.connectionBackoffFactor = connectionBackoffFactor
            self.initialConnectionBackoffDelay = initialConnectionBackoffDelay
            self.connectionRetryTimeout = connectionRetryTimeout
            self.onUnexpectedConnectionClose = onUnexpectedConnectionClose
        }
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
        if database != nil && database! < 0 { throw ValidationError.outOfBoundsDatabaseID }

        do {
            let resolvedAdress = try SocketAddress.makeAddressResolvingHost(hostname, port: port)
            self.serverAddresses = [resolvedAdress]
            self.deferredHostname = nil
            self.deferredPort = nil
        } catch {
            self.serverAddresses = []
            self.deferredHostname = hostname
            self.deferredPort = port
        }

        self.password = password
        self.tlsConfiguration = tlsConfiguration
        self.tlsHostname = hostname
        self.database = database
        self.pool = pool
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
        self.deferredHostname = nil
        self.deferredPort = nil
        self.password = password
        self.tlsConfiguration = tlsConfiguration
        self.tlsHostname = tlsHostname
        self.database = database
        self.pool = pool
    }

    /// Attempts to resolve any pending hostname resolution
    ///  - Returns: new configuration with resolved addresses, or throws if resolution fails
    public func resolveServerAddresses() throws -> RedisConfiguration {
        guard let hostname = deferredHostname, let port = deferredPort else {
            return self
        }

        var resolved = self
        let resolvedAddress = try SocketAddress.makeAddressResolvingHost(hostname, port: port)
        resolved.serverAddresses = [resolvedAddress]
        resolved.deferredHostname = nil
        resolved.deferredPort = nil
        return resolved
    }
}

extension RedisConnectionPool.Configuration {
    internal init(_ config: RedisConfiguration, defaultLogger: Logger, customClient: ClientBootstrap?) {
        // Handle deferred hostname resolution at pool creation time
        var addresses = config.serverAddresses

        if let hostname = config.deferredHostname, let port = config.deferredPort {
            do {
                let resolvedAddress = try SocketAddress.makeAddressResolvingHost(hostname, port: port)
                addresses = [resolvedAddress]
            } catch {
                defaultLogger.notice("Hostname '\(hostname)' could not be resolved at pool creation time: \(error). Redis connections will fail until hostname becomes resolvable.")
                // Placeholder address so Redis operations fail gracefully
                addresses = [try! SocketAddress.makeAddressResolvingHost("0.0.0.0", port: 1)]
            }
        }
        self.init(
            initialServerConnectionAddresses: addresses,
            maximumConnectionCount: config.pool.maximumConnectionCount,
            connectionFactoryConfiguration: .init(
                connectionInitialDatabase: config.database,
                connectionPassword: config.password,
                connectionDefaultLogger: defaultLogger,
                tcpClient: customClient
            ),
            minimumConnectionCount: config.pool.minimumConnectionCount,
            connectionBackoffFactor: config.pool.connectionBackoffFactor,
            initialConnectionBackoffDelay: config.pool.initialConnectionBackoffDelay,
            connectionRetryTimeout: config.pool.connectionRetryTimeout,
            onUnexpectedConnectionClose: config.pool.onUnexpectedConnectionClose,
            poolDefaultLogger: defaultLogger
        )
    }
}
