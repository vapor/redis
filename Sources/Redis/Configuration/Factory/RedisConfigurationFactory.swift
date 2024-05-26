import Foundation

public struct RedisConfigurationFactory {
    typealias ValidationError = RedisConfiguration.ValidationError

    public let make: () -> RedisFactory

    public init(make: @escaping () -> RedisFactory) {
        self.make = make
    }
}
