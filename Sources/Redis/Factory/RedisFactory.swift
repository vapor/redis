//
//  RedisProvider.swift
//
//
//  Created by Alessandro Di Maio on 12/05/24.
//

import RediStack
import Vapor

public protocol RedisFactory {
    init(configuration: RedisConfiguration)
    func makeClient(for eventLoop: EventLoop, logger: Logger) -> RedisClient
}
