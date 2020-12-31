import Foundation
import Vapor

public struct RedisID: Hashable, Codable {

    public let string: String
    public init(string: String) {
        self.string = string
    }

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

extension Request {
    public var redis: Redis {
        redis(.default)
    }

    public func redis(_ id: RedisID) -> Redis {
        .init(request: self, redisID: id)
    }
}
