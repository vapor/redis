//
//  File.swift
//  
//
//  Created by Daniel Ramteke on 12/30/20.
//

import Foundation
import Vapor

public struct RedisID: Hashable, Codable, CustomStringConvertible {
    public typealias Value = RedisClient

    public let string: String
    public init(string: String) {
        self.string = string
    }

    public var description: String { string }

    public static let `default` = RedisID(string: "default")
}

extension Application {
    public var redis: Redis {
        redis(.default)
    }

    public func redis(_ id: RedisID) -> Redis {
        .init(application: self, redisID: id)
    }
}
