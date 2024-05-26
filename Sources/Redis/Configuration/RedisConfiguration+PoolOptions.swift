import Foundation
@preconcurrency import RediStack

extension RedisConfiguration {
    public struct PoolOptions: Sendable {
        public let maximumConnectionCount: RedisConnectionPoolSize
        public let minimumConnectionCount: Int
        public let connectionBackoffFactor: Float32
        public let initialConnectionBackoffDelay: TimeAmount
        public let connectionRetryTimeout: TimeAmount?
        public let onUnexpectedConnectionClose: (@Sendable (RedisConnection) -> Void)?

        public init(
            maximumConnectionCount: RedisConnectionPoolSize = .maximumActiveConnections(2),
            minimumConnectionCount: Int = 0,
            connectionBackoffFactor: Float32 = 2,
            initialConnectionBackoffDelay: TimeAmount = .milliseconds(100),
            connectionRetryTimeout: TimeAmount? = nil,
            onUnexpectedConnectionClose: (@Sendable (RedisConnection) -> Void)? = nil
        ) {
            self.maximumConnectionCount = maximumConnectionCount
            self.minimumConnectionCount = minimumConnectionCount
            self.connectionBackoffFactor = connectionBackoffFactor
            self.initialConnectionBackoffDelay = initialConnectionBackoffDelay
            self.connectionRetryTimeout = connectionRetryTimeout
            self.onUnexpectedConnectionClose = onUnexpectedConnectionClose
        }
    }
}
