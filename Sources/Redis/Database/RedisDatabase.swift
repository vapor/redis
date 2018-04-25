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
        return RedisClient.connect(hostname: config.hostname, port: config.port, on: worker) { error in
            print("[Redis] \(error)")
        }.then { client in
            if let password = self.config.password {
                return client.command("AUTH", [.basicString(password)]).transform(to: client)
            } else {
                return worker.eventLoop.newSucceededFuture(result: client)
            }
        }
    }
}

extension DatabaseIdentifier {
    /// Default identifier for `RedisClient`.
    public static var redis: DatabaseIdentifier<RedisDatabase> {
        return .init("redis")
    }
}
