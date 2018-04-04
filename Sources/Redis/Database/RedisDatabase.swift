import Foundation
import DatabaseKit
import Async

public final class RedisDatabase: Database {
    /// ReidsDatabase has connection to RedisClient because it is more of a dataStructure store and less
    /// of a first class ORM
    public typealias Connection = RedisClient

    /// This client's configuration.
    public let url: URL

    /// Creates a new `RedisDatabase`.
    public init(config: RedisClientConfig) throws {
        url = try config.toURL()
    }

    public init(url: URL) throws {
        self.url = url
    }

    public func makeConnection(on worker: Worker) -> EventLoopFuture<RedisClient> {
        return RedisClient.connect(hostname: url.host ?? "localhost", port: url.port ?? 6379, on: worker) { error in
            print("[Redis] \(error)")
        }.map(to: RedisClient.self, { client in
            if let password = self.url.password {
                _ = client.command("AUTH", [.basicString(password)])
            }
            return client
        })
    }
}

extension RedisClient: DatabaseConnection, BasicWorker { }

extension DatabaseIdentifier {
    /// Default identifier for `RedisClient`.
    public static var redis: DatabaseIdentifier<RedisDatabase> {
        return .init("redis")
    }
}
