extension Client {
    public typealias SubscribeCallback = (Data?) -> ()

    public func subscribe(
        channels: [Bytes],
        _ callback: SubscribeCallback
    ) throws -> Never {
        try command(.subscribe, channels)
        while true {
            let data = try parser.parse()
            callback(data)
        }
    }

    @discardableResult
    public func publish(
        channel: Bytes,
        _ message: Bytes
    ) throws -> Data? {
        return try command(.publish, [channel, message])
    }
}

// MARK: Convenience

extension Client {
    public func subscribe(
        channel: BytesRepresentable,
        _ callback: SubscribeCallback
    ) throws -> Never {
        let bytes = try channel.makeBytes()
        try subscribe(channels: [bytes], callback)
    }

    @discardableResult
    public func publish(
        channel: BytesRepresentable,
        _ message: BytesRepresentable
    ) throws -> Data? {
        return try command(
            .publish,
            [channel.makeBytes(), message.makeBytes()]
        )
    }
}
