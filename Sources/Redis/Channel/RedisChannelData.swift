/// Subscription response. Contains channel name and redis data.
public struct RedisChannelData {
    /// The name of the channel posting a message.
    public var channel: String

    /// The data.
    public var data: RedisData
}
