//
//  RedisProvider.swift
//
//
//  Created by Alessandro Di Maio on 12/05/24.
//

import NIOCore
import NIOPosix
import NIOSSL
import RediStack
import Vapor

struct RedisProvider: RedisFactory {
    let configuration: RedisConfiguration

    init(configuration: RedisConfiguration) {
        self.configuration = configuration
    }

    func makeClient(for eventLoop: EventLoop, logger: Logger) -> RedisClient {
        let redisTLSClient: ClientBootstrap? = {
            guard let tlsConfig = configuration.tlsConfiguration,
                  let tlsHost = configuration.tlsHostname else { return nil }

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
            configuration: .init(configuration, defaultLogger: logger, customClient: redisTLSClient),
            boundEventLoop: eventLoop
        )
    }
}
