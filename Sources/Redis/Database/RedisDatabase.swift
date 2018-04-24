import Foundation
import Async

public final class RedisDatabase: Database {
    /// ReidsDatabase has connection to RedisClient because it is more of a dataStructure store and less
    /// of a first class ORM
    public typealias Connection = RedisClient

    /// This client's configuration.
    public let config: RedisClientConfig

    /// Creates a new `RedisDatabase`.
    public init(config: RedisClientConfig) throws {
        self.config = config
    }

    public init(url: URL) throws {
        self.config = RedisClientConfig(url: url)
    }

    public func newConnection(on worker: Worker) -> EventLoopFuture<RedisClient> {
        return RedisClient.connect(hostname: config.hostname, port: config.port, on: worker) { error in
            print("[Redis] \(error)")
        }.map(to: RedisClient.self, { client in
            if let password = self.config.password {
                _ = client.command("AUTH", [.basicString(password)])
            }
            return client
        })
    }
}

extension DatabaseIdentifier {
    /// Default identifier for `RedisClient`.
    public static var redis: DatabaseIdentifier<RedisDatabase> {
        return .init("redis")
    }
}
