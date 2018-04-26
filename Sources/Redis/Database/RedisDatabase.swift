public final class RedisDatabase: Database {
    /// This client's configuration.
    public let config: RedisClientConfig

    /// Creates a new `RedisDatabase`.
    public init(config: RedisClientConfig) throws {
        self.config = config
    }

    public init(url: URL) throws {
        self.config = RedisClientConfig(url: url)
    }

    /// See `Database`.
    public func newConnection(on worker: Worker) -> EventLoopFuture<RedisClient> {
        return RedisClient.connect(
            hostname: config.hostname,
            port: config.port,
            password: config.password,
            on: worker
        ) { error in
            print("[Redis] \(error)")
        }
    }
}

extension DatabaseIdentifier {
    /// Default identifier for `RedisClient`.
    public static var redis: DatabaseIdentifier<RedisDatabase> {
        return .init("redis")
    }
}
