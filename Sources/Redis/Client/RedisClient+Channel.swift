import Async
import Bits

extension RedisClient {
    /// Creates a `RedisChannelStream`.
    public static func subscribe<Stream>(to channels: Set<String>, stream: Stream, on worker: Worker) -> Future<RedisChannelStream>
        where Stream: ByteStream
    {
        let client = RedisClient(stream: stream, on: worker)
        let channels = channels.map { name in
            return RedisData(bulk: name)
        }
        return client.command("SUBSCRIBE", channels).map(to: RedisChannelStream.self) { data in
            return .init(source: stream, worker: worker)
        }
    }
}

extension RedisClient {
    /// Publishes data to a Redis channel.
    public func publish(_ message: RedisData, to channel: String) -> Future<RedisData> {
        return command("PUBLISH", [.bulkString(channel), message])
    }
}
