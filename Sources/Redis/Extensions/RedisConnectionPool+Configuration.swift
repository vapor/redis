import NIOPosix
import RediStack

extension RedisConnectionPool.Configuration {
    internal init(_ config: RedisConfiguration, defaultLogger: Logger, customClient: ClientBootstrap?) {
        self.init(
            initialServerConnectionAddresses: config.serverAddresses,
            maximumConnectionCount: config.pool.maximumConnectionCount,
            connectionFactoryConfiguration: .init(
                connectionInitialDatabase: config.database,
                connectionPassword: config.password,
                connectionDefaultLogger: defaultLogger,
                tcpClient: customClient
            ),
            minimumConnectionCount: config.pool.minimumConnectionCount,
            connectionBackoffFactor: config.pool.connectionBackoffFactor,
            initialConnectionBackoffDelay: config.pool.initialConnectionBackoffDelay,
            connectionRetryTimeout: config.pool.connectionRetryTimeout,
            onUnexpectedConnectionClose: config.pool.onUnexpectedConnectionClose,
            poolDefaultLogger: defaultLogger
        )
    }
}
