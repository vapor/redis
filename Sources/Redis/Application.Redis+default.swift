import Vapor

extension Application.Redis {
    public var configuration: RedisConfiguration? {
        get {
            self.application.redisStorage.configuration(for: self.redisID)
        }
        nonmutating set {
            guard let newConfig = newValue else {
                return
            }
            self.application.redisStorage.use(newConfig, as: self.redisID)
        }
    }
}
