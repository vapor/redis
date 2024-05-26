import Foundation

public struct RedisConfigurationFactory: Sendable {
    typealias ValidationError = RedisConfiguration.ValidationError

    public let make: @Sendable () -> RedisFactory

    public init(make: @escaping @Sendable () -> RedisFactory) {
        self.make = make
    }
}
