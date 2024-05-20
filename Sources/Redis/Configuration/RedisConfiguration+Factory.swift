import NIOCore
import NIOPosix
import NIOSSL
import RediStack
import Vapor

extension RedisConfiguration: RedisFactory {
    public func make(for eventLoop: EventLoop, logger: Logger) -> RedisClient {
        let redisTLSClient: ClientBootstrap? = {
            guard let tlsConfig = self.tlsConfiguration,
                  let tlsHost = self.tlsHostname else { return nil }

            return ClientBootstrap(group: eventLoop)
                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .channelInitializer { channel in
                    do {
                        let sslContext = try NIOSSLContext(configuration: tlsConfig)
                        return EventLoopFuture.andAllSucceed([
                            channel.pipeline.addHandler(
                                try NIOSSLClientHandler(
                                    context: sslContext,
                                    serverHostname: tlsHost
                                )
                            ),
                            channel.pipeline.addBaseRedisHandlers(),
                        ], on: channel.eventLoop)
                    } catch {
                        return channel.eventLoop.makeFailedFuture(error)
                    }
                }
        }()

        return RedisConnectionPool(
            configuration: .init(self, defaultLogger: self.logger ?? logger, customClient: redisTLSClient),
            boundEventLoop: eventLoop
        )
    }
}
