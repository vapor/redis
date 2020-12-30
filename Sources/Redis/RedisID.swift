//
//  File.swift
//  
//
//  Created by Daniel Ramteke on 12/30/20.
//

import Foundation
import Vapor

public struct RedisID: Hashable, Codable {
  public typealias Value = RedisClient

  public let string: String
  public init(string: String) {
    self.string = string
  }

  public static let `default` = RedisID(string: "default")
}

extension Application {
  public var redis: Redis {
    redis(nil)
  }

  public func redis(_ id: RedisID?) -> Redis {
    .init(application: self, redisID: id ?? .default)
  }
}
