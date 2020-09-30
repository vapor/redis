@_exported import struct Foundation.URL
@_exported import struct Logging.Logger
@_exported import struct NIO.TimeAmount
import enum NIO.SocketAddress

public struct RedisConfiguration {
    public var serverAddresses: [SocketAddress]
    public var password: String?
    public var database: Int?
    public var pool: PoolOptions

    public struct PoolOptions {
        public var maximumConnectionCount: RedisConnectionPoolSize
        public var minimumConnectionCount: Int
        public var connectionBackoffFactor: Float32
        public var initialConnectionBackoffDelay: TimeAmount

        public init(
            maximumConnectionCount: RedisConnectionPoolSize = .maximumActiveConnections(2),
            minimumConnectionCount: Int = 0,
            connectionBackoffFactor: Float32 = 2,
            initialConnectionBackoffDelay: TimeAmount = .milliseconds(100)
        ) {
            self.maximumConnectionCount = maximumConnectionCount
            self.minimumConnectionCount = minimumConnectionCount
            self.connectionBackoffFactor = connectionBackoffFactor
            self.initialConnectionBackoffDelay = initialConnectionBackoffDelay
        }
    }

    public init(url string: String, pool: PoolOptions = .init()) throws {
        guard let url = URL(string: string) else {
            throw RedisError(reason: "Invalid URL string: \(string)")
        }
        try self.init(url: url, pool: pool)
    }

    public init(url: URL, pool: PoolOptions = .init()) throws {
        guard let scheme = url.scheme else {
            throw RedisError(reason: "Missing URL scheme")
        }
        guard scheme == "redis" else {
            throw RedisError(reason: "Invalid URL scheme: \(scheme)")
        }
        try self.init(
            hostname: url.host ?? "localhost",
            port: url.port ?? RedisConnection.defaultPort,
            password: url.password,
            database: Int(url.path),
            pool: pool
        )
    }

    public init(
        hostname: String = "localhost",
        port: Int = RedisConnection.defaultPort,
        password: String? = nil,
        database: Int? = nil,
        pool: PoolOptions = .init()
    ) throws {
        try self.init(
            serverAddresses: [.makeAddressResolvingHost(hostname, port: port)],
            password: password,
            database: database,
            pool: pool
        )
    }

    public init(
        serverAddresses: [SocketAddress],
        password: String? = nil,
        database: Int? = nil,
        pool: PoolOptions = .init()
    ) throws {
        self.serverAddresses = serverAddresses
        self.password = password
        self.database = database
        self.pool = pool
    }
}
