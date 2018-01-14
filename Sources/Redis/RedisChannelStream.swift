import Async
import Bits

/// Represents a Redis client that has been converted to an
/// output-only stream of Redis data.
public final class RedisChannelStream: OutputStream {
    /// See OutputStream.Output
    public typealias Output = RedisChannelData

    /// The internal stream.
    private let stream: MapStream<RedisData, RedisChannelData>

    /// Create a new `RedisSubscriptionStream`.
    /// Use static method on `RedisClient` to create.
    internal init<SourceStream>(source: SourceStream)
        where SourceStream: OutputStream, SourceStream.Output == ByteBuffer
    {
        stream = source.stream(to: RedisDataParser()).map(to: RedisChannelData.self) { data in
            guard let arr = data.array, arr.count == 3 else {
                throw RedisError(.unexpectedResult(data))
            }

            return .init(
                channel: arr[1].string ?? "",
                data: arr[2]
            )
        }
    }

    /// See OutputStream.output
    public func output<S>(to inputStream: S) where S: InputStream, S.Input == RedisChannelData {
        stream.output(to: inputStream)
    }
}

