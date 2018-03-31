import Foundation
import DatabaseKit
import Async

public final class RedisDatabase: Database {
    /// RedisDatabase has connection to RedisClient because it is more of a dataStructure store and less
    /// of a first class ORM
    public typealias Connection = RedisClient

    /// This client's configuration.
    public let config: RedisClientConfig

    /// Creates a new `RedisDatabase`.
    public init(config: RedisClientConfig) {
        self.config = config
    }

    public func makeConnection(on worker: Worker) -> EventLoopFuture<RedisClient> {
        let client = RedisClient.connect(hostname: config.hostname, port: config.port, on: worker) { error in
            print("[Redis] \(error)")
        }
        let promise = worker.eventLoop.newPromise(RedisClient.self)
        client.do { client in
            if let password = self.config.password {
                client.authorize(with: password).do {
                    promise.succeed(result: client)
                }.catch(promise.fail(error:))
            } else {
                promise.succeed(result: client)
            }
        }.catch(promise.fail(error:))
        return promise.futureResult
    }

}

extension RedisClient: DatabaseConnection, BasicWorker { }

extension DatabaseIdentifier {
    /// Default identifier for `RedisClient`.
    public static var redis: DatabaseIdentifier<RedisDatabase> {
        return .init("redis")
    }
}
