import Async
import Bits
import NIO

/// A Redis client.
public final class RedisClient {
    public var eventLoop: EventLoop {
        return channel.eventLoop
    }

    /// Handles enqueued redis commands and responses.
    internal let queue: QueueHandler<RedisData, RedisData>

    /// The channel
    private let channel: Channel

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
    /// The Redis server's hostname.
    public var hostname: String

    /// The Redis server's port.
    public var port: Int

    /// The Redis server's optional password.
    public var password: String?

    /// Create a new `RedisClientConfig`
    public init(hostname: String = "localhost", port: Int = 6379, password: String? = nil) {
        self.hostname = hostname
        self.port = port
        self.password = password
    }
}
