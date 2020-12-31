import Vapor

extension Application.Redis {
    /// Configure Redis connection information.
    /// In `configure.swift`, write `app.redis.configuration = RedisConfiguration(...)`
    /// Or for alternate Redis IDs, `app.redis(.myRedisId).configuration = RedisConfiguration(...)`
    /// when `extension RedisID { static let myRedisID = RedisID(...) }` has been defined.
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
