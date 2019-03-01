import Vapor

/// Provides base `Redis` services such as database and connection.
public final class RedisProvider: Provider {
    /// Creates a new `RedisProvider`.
    public init() {}

    /// See `Provider`.
    public func register(_ s: inout Services) throws {
        s.register(RedisConfiguration.self) { c in
            if let urlString = Environment.get("REDIS_URL") {
                guard let url = URL(string: urlString) else {
                    fatalError("REDIS_URL is not a valid URL")
                }
                guard let config = RedisConfiguration(url: url) else {
                    fatalError("REDIS_URL is not a valid Redis connection URL")
                }
                return config
            } else {
                return RedisConfiguration()
            }
        }
        
        s.register(RedisConnectionSource.self) { c in
            return try .init(config: c.make(), on: c.eventLoop)
        }
        
        s.register(RedisDatabase.self) { c in
            let redis = try c.make(RedisConnectionSource.self)
            return try ConnectionPool(config: c.make(), source: redis)
        }
    }
}
