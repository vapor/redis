import Foundation
import Logging
import NIOCore
import NIOSSL

/// Configuration for connecting to a Redis instance
public struct RedisConfiguration: Sendable {
    public typealias ValidationError = RedisConnection.Configuration.ValidationError

    public let serverAddresses: [SocketAddress]
    public let password: String?
    public let database: Int?
    public let pool: PoolOptions
    public let tlsConfiguration: TLSConfiguration?
    public let tlsHostname: String?
    public let logger: Logger?

    init(serverAddresses: [SocketAddress], password: String?, database: Int?, pool: PoolOptions, tlsConfiguration: TLSConfiguration?, tlsHostname: String?, logger: Logger?) {
        self.serverAddresses = serverAddresses
        self.password = password
        self.database = database
        self.pool = pool
        self.tlsConfiguration = tlsConfiguration
        self.tlsHostname = tlsHostname
        self.logger = logger
    }
}
