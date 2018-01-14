import Async
import Bits

extension RedisClient {
    /// Creates a `RedisSubscriptionStream`.
    public static func subscribe<SourceStream, SinkStream>(
        to channels: Set<String>,
        source: SourceStream,
        sink: SinkStream
    ) -> Future<RedisChannelStream>
        where SourceStream: OutputStream,
            SinkStream: InputStream,
            SinkStream.Input == ByteBuffer,
            SourceStream.Output == ByteBuffer
    {
        let client = RedisClient(source: source, sink: sink)
        let channels = channels.map { name in
            return RedisData(bulk: name)
        }
        return client.command("SUBSCRIBE", channels).map(to: RedisChannelStream.self) { data in
            return .init(source: source)
        }
    }
}

extension RedisClient {
    /// Publishes data to a Redis channel.
    public func publish(_ message: RedisData, to channel: String) -> Future<RedisData> {
        return command("PUBLISH", [.bulkString(channel), message])
    }
}
