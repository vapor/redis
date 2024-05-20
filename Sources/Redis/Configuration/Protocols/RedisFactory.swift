//
//  RedisProvider.swift
//
//
//  Created by Alessandro Di Maio on 12/05/24.
//

import Logging
import RediStack
import Vapor

/// A protocol which indicates the ability to create a ``RedisClient``
public protocol RedisFactory {
    /// A method that generates a ``RedisClient``
    /// - Parameters:
    ///   - eventLoop: indicates the ``eventLoop`` on which the client will execute their commands.
    ///   - logger: indicates a specific logger associated with the client
    /// - Returns: a ``RedisClient``
    func make(for eventLoop: EventLoop, logger: Logger) -> RedisClient
}
