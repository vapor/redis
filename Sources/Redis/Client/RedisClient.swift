import Async
import Bits
import NIO

/// A Redis client.
public final class RedisClient {
    public var eventLoop: EventLoop {
        return channel.eventLoop
    }

    /// Handles enqueued redis commands and responses.
    private let queue: QueueHandler<RedisData, RedisData>

    /// The channel
    private let channel: Channel

    /// If non-nil, will log queries.
    // Future Feature public var logger: RedisLogger?

    /// Creates a new Redis client on the provided data source and sink.
    init(queue: QueueHandler<RedisData, RedisData>, channel: Channel) {
        self.queue = queue
        self.channel = channel
    }

    private func send(_ messages: [RedisData],
                      onResponse: @escaping (RedisData) throws -> Void) -> Future<Void> {
        return queue.enqueue(messages) { message in
            try onResponse(message)
            return true // redis is kind of one piece of redis data at time
        }
    }

    /// Sends `RedisData` to the server.
    public func send(_ data: RedisData) -> Future<RedisData> {
        var dataArr = [RedisData]()
        return send([data]) { dataArr.append($0) }
            .map(to: RedisData.self) { dataArr.first!}
    }

    /// Runs a Value as a command
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/redis/custom-commands/#usage)
    public func command(_ command: String, _ arguments: [RedisData] = []) -> Future<RedisData> {
        return send(.array([.bulkString(command)] + arguments)).map(to: RedisData.self) { res in
            // convert redis errors to a Future error
            switch res.storage {
            case .error(let error): throw error
            default: return res
            }
        }
    }

    /// Closes this client.
    public func close() {
        channel.close(promise: nil)
    }
}

/// MARK: Config

/// Config options for a `RedisClient.
public struct RedisClientConfig: Codable {
    /// Default `RedisClientConfig`
    public static func `default`() -> RedisClientConfig {
        return .init(hostname: "127.0.0.1", port: 6379)
    }

    /// The Redis server's hostname.
    public var hostname: String

    /// The Redis server's port.
    public var port: Int

    /// Create a new `RedisClientConfig`
    public init(hostname: String, port: Int) {
        self.hostname = hostname
        self.port = port
    }
}
