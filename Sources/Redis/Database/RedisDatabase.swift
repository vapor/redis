/// Creates instances of `RedisClient`.
public final class RedisDatabase: Database {
    /// This client's configuration.
    public let config: RedisClientConfig

    /// Creates a new `RedisDatabase`.
    public init(config: RedisClientConfig) throws {
        self.config = config
    }

    /// Creates a new `RedisDatabase` from a Redis configuration URL.
    public init(url: URL) throws {
        self.config = RedisClientConfig(url: url)
    }

    /// See `Database`.
    public func newConnection(on worker: Worker) -> EventLoopFuture<RedisClient> {
        let connect = RedisClient.connect(
            hostname: config.hostname,
            port: config.port,
            password: config.password,
            on: worker
        ) { error in
            print("[Redis] \(error)")
        }

        guard let database = config.database else {
            return connect
        }

        return connect.flatMap { client in
            client.select(database)
                .transform(to: client)
        }
    }
}

extension DatabaseIdentifier {
    /// Default identifier for `RedisClient`.
    public static var redis: DatabaseIdentifier<RedisDatabase> {
        return .init("redis")
    }
}
