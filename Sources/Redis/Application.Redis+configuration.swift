import Vapor

extension Application.Redis {
    /// The Redis configuration to use to communicate with a Redis instance.
    ///
    /// See `Application.Redis.id`
    public var configuration: RedisConfiguration? {
        get {
            self.application.redisStorage.configuration(for: self.id)
        }
        nonmutating set {
            guard let newConfig = newValue else {
                fatalError("Modifying configuration is not supported")
            }
            self.application.redisStorage.use(newConfig, as: self.id)
        }
    }
}
