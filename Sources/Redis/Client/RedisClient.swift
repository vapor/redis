import Async
import Bits
import NIO

/// A Redis client.
public final class RedisClient {
    /// Handles enqueued redis commands and responses.
    //private let queueHandler: QueueHandler<RedisData, RedisData>

    /// Creates a new Redis client on the provided data source and sink.

    /// Sends `RedisData` to the server.
    // public func send(_ data: RedisData) -> Future<RedisData>

    /// Runs a Value as a command
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/redis/custom-commands/#usage)
    /*public func command(_ command: String, _ arguments: [RedisData] = []) -> Future<RedisData> {
        return send(.array([.bulkString(command)] + arguments)).map(to: RedisData.self) { res in
            // convert redis errors to a Future error
            switch res.storage {
            case .error(let error): throw error
            default: return res
            }
        }
    }*/
}

/// MARK: Config

/// Config options for a `RedisClient.
public struct RedisClientConfig: Codable {
    /// Default `RedisClientConfig`
    public static func `default`() -> RedisClientConfig {
        return .init(hostname: "localhost", port: 6379)
    }

    /// The Redis server's hostname.
    public var hostname: String

    /// The Redis server's port.
    public var port: UInt16

    /// Create a new `RedisClientConfig`
    public init(hostname: String, port: UInt16) {
        self.hostname = hostname
        self.port = port
    }
}
