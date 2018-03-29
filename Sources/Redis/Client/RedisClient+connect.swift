import Async
import NIO

extension RedisClient {
    /// Connects to a Redis server using a TCP socket.
    public static func connect(
        hostname: String = "127.0.0.1",
        port: Int = 6379,
        on worker: Worker,
        onError: @escaping (Error) -> Void
    ) -> Future<RedisClient> {
        let handler = QueueHandler<RedisData, RedisData>(on: worker, onError: onError)
        let bootstrap = ClientBootstrap(group: worker.eventLoop)
            // Enable SO_REUSEADDR.
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addRedisHandlers().then {
                    channel.pipeline.add(handler: handler)
                }
            }

        return bootstrap.connect(host: hostname, port: port).map(to: RedisClient.self) { channel in
            return .init(queue: handler, channel: channel)
        }
    }
}

extension ChannelPipeline {
    func addRedisHandlers(first: Bool = false) -> EventLoopFuture<Void> {
        return addHandlers(RedisDataEncoder(), RedisDataDecoder(), first: first)
    }

    /// Adds the provided channel handlers to the pipeline in the order given, taking account
    /// of the behaviour of `ChannelHandler.add(first:)`.
    private func addHandlers(_ handlers: ChannelHandler..., first: Bool) -> EventLoopFuture<Void> {
        var handlers = handlers
        if first {
            handlers = handlers.reversed()
        }

        return EventLoopFuture<Void>.andAll(handlers.map { add(handler: $0) }, eventLoop: eventLoop)
    }
}
