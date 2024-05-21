import Foundation
import Logging
import NIOCore
import NIOSSL

/// A protocol which indicates the ability to create a ``RedisClient``
public protocol RedisFactory {
    /// Configuration on which ``RedisFactory/makeClient(for:logger:)`` is based
    var configuration: RedisConfiguration { get }

    /// A method that generates a ``RediStack/RedisClient``
    /// - Parameters:
    ///   - eventLoop: indicates the eventLoop on which the client will execute their commands.
    ///   - logger: indicates a specific logger associated with the client
    /// - Returns: a ``RediStack/RedisClient``
    func makeClient(for eventLoop: EventLoop, logger: Logger) -> RedisClient
}
