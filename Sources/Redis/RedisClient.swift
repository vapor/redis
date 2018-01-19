import Async
import Bits
import TCP

/// A Redis client.
public final class RedisClient {
    /// Handles enqueued redis commands and responses.
    private let queueStream: QueueStream<RedisData, RedisData>

    /// Creates a new Redis client on the provided data source and sink.
    public init<Stream>(stream: Stream) where Stream: ByteStream {
        let queueStream = QueueStream<RedisData, RedisData>()

        let serializerStream = RedisDataSerializer()
        let parserStream = RedisDataParser()

        stream.stream(to: parserStream)
            .stream(to: queueStream)
            .stream(to: serializerStream)
            .output(to: stream)

        self.queueStream = queueStream
    }

    /// Sends `RedisData` to the server.
    public func send(_ data: RedisData) -> Future<RedisData> {
        return queueStream.enqueue(data)
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
}
