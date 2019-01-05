import Foundation

extension RedisClient {
    /// Creates a `RedisPipeline` for executing a batch of commands.
    public func makePipeline() -> RedisPipeline {
        return .init(client: self)
    }
}

/// An object that provides a mechanism to "pipeline" multiple Redis commands in sequence providing an aggregate response
/// of all the responses of each individual command.
///
///     let results = connection.makePipeline()
///         .enqueue(command: "SET", arguments: ["my_key", 3])
///         .enqueue(command: "INCR", arguments: ["my_key"])
///         .execute()
///     // results == Future<[RedisData]>
///     // results[0].string == "OK"
///     // results[1].int == 4
///
public final class RedisPipeline {
    /// The client to execute the commands on.
    private let client: RedisClient

    /// The queue of complete encoded commands to execute.
    private var queue: [RedisData]

    internal init(client: RedisClient) {
        self.client = client
        self.queue = []
    }

    /// Queues the provided command and arguments to be executed.
    /// - Parameters:
    ///     - command: The command to execute. See https://redis.io/commands
    ///     - arguments: The arguments, if any, to send with the command.
    /// - Returns: A self-reference to this `RedisPipeline` instance for chaining commands.
    public func enqueue(command: String, arguments: [RedisDataConvertible] = []) throws -> RedisPipeline {
        let args = try arguments.map { try $0.convertToRedisData() }

        queue.append(.array([.bulkString(command)] + args))

        return self
    }

    /// Drains the queue, executing each command in sequence.
    /// - Important: If any of the commands fail, the entire future will fail.
    /// - Returns: A `Future` that resolves the `RedisData` responses, in the same order as the command queue.
    public func execute() -> Future<[RedisData]> {
        let promise = client.eventLoop.newPromise([RedisData].self)

        var results = [RedisData]()
        var iterator = queue.makeIterator()

        func handle(_ command: RedisData) {
            let future = client.send(command)
            future.whenSuccess { response in
                switch response.storage {
                case let .error(error): promise.fail(error: error)
                default:
                    results.append(response)

                    if let next = iterator.next() {
                        handle(next)
                    } else {
                        promise.succeed(result: results)
                    }
                }
            }
            future.whenFailure { promise.fail(error: $0) }
        }

        if let first = iterator.next() {
            handle(first)
        } else {
            promise.succeed(result: [])
        }

        return promise.futureResult
            .always { self.queue = [] }
    }
}
