//
//  RedisConfiguration+PoolOptions.swift
//
//
//  Created by Alessandro Di Maio on 12/05/24.
//

import Foundation

extension RedisConfiguration {
    public struct PoolOptions {
        public let maximumConnectionCount: RedisConnectionPoolSize
        public let minimumConnectionCount: Int
        public let connectionBackoffFactor: Float32
        public let initialConnectionBackoffDelay: TimeAmount
        public let connectionRetryTimeout: TimeAmount?
        public let onUnexpectedConnectionClose: ((RedisConnection) -> Void)?

        public init(
            maximumConnectionCount: RedisConnectionPoolSize = .maximumActiveConnections(2),
            minimumConnectionCount: Int = 0,
            connectionBackoffFactor: Float32 = 2,
            initialConnectionBackoffDelay: TimeAmount = .milliseconds(100),
            connectionRetryTimeout: TimeAmount? = nil,
            onUnexpectedConnectionClose: ((RedisConnection) -> Void)? = nil
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
