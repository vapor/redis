import Async
import Bits
import NIO

extension RedisClient {
    /// Publishes data to a Redis channel.
    public func publish(_ message: RedisData, to channel: String) -> Future<RedisData> {
        return command("PUBLISH", [.bulkString(channel), message])
    }
}

extension RedisClient {
    /// Subscribes to the channels and call the subscription handler on message from server
    /// Should be closed when subscription not needed.
    /// Makes the redis client subscription only.
    public func subscribe(
        _ channels: Set<String>,
        subscriptionHandler: @escaping (RedisChannelData) -> Void
    ) throws -> Future<Void> {
       let messages: [RedisData] = [.array([.bulkString("SUBSCRIBE")] + channels.map {.bulkString($0)})]
        return queue.enqueue(messages) { [weak self] channelMessage in
            if let redisChannelData = try self?.convert(channelMessage: channelMessage) {
                subscriptionHandler(redisChannelData)
            }
            return false
        }
    }

    /// Maps RedisData.array to RedisChannelData, throws if map fails
    private func convert(channelMessage: RedisData) throws -> RedisChannelData? {
        guard let array = channelMessage.array,
            array.first?.string == "message" // must contain ["message", <channel>, <redisData>]
             else {
            return nil
        }
        guard let channel = array[1].string else {
            throw RedisError(identifier: "channel data",
                             reason: "channel data did not contain identifier",
                             source: .capture())
        }
        return RedisChannelData(channel: channel, data: array[2])
    }
}
