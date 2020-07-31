@_exported import struct Foundation.URL
@_exported import struct Logging.Logger
import enum NIO.SocketAddress

/// A configuration for making connections to a specific Redis server.
public struct RedisConfiguration {
    let serverAddress: SocketAddress
    let password: String?
    let database: Int?

    public init(
        hostname: String = "localhost",
        port: Int = RedisConnection.defaultPort,
        password: String? = nil,
        database: Int? = nil
    ) throws {
        self.serverAddress = try .makeAddressResolvingHost(hostname, port: port)
        self.password = password
        self.database = database
    }


    public init(url string: String) throws {
        guard let url = URL(string: string) else {
            throw RedisError(reason: "Invalid URL string: \(string)")
        }
        try self.init(url: url)
    }

    public init(url: URL) throws {
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
            database: Int(url.path)
        )
    }
}
