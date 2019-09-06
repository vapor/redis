import NIO

/// A Redis client.
public final class RedisClient: DatabaseConnection, BasicWorker {
    public typealias Database = RedisDatabase
    
    /// See `BasicWorker`.
    public var eventLoop: EventLoop {
        return channel.eventLoop
    }

    /// See `DatabaseConnection`.
    public var isClosed: Bool

    /// See `Extendable`.
    public var extend: Extend
    
    /// Handles queued redis commands and responses
    internal let queue: RedisCommandHandler

    /// The channel
    private let channel: Channel
    
    /// Stores the inflight promises so they can be fulfilled when the channel drops
    var inflightPromises: [String:EventLoopPromise<RedisData>] = [:]

    /// Creates a new Redis client on the provided data source and sink.
    init(queue: RedisCommandHandler, channel: Channel) {
        self.queue = queue
        self.channel = channel
        self.extend = [:]
        self.isClosed = false
        channel.closeFuture.always {
            // send closed error for the promises that have not been fulfilled
            for promise in self.inflightPromises.values {
                promise.fail(error: ChannelError.ioOnClosedChannel)
            }
            self.inflightPromises.removeAll()

            self.isClosed = true
        }
    }

    /// Runs a Value as a command
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/redis/custom-commands/#usage)
    public func command(_ command: String, _ arguments: [RedisData] = []) -> Future<RedisData> {
        return send(.array([.bulkString(command)] + arguments)).map(to: RedisData.self) { res in
            // convert redis errors to a Future error
            switch res.storage {
            case .error(let error): throw error
            default: return res
            }
        }
    }

    /// Sends `RedisData` to the server.
    public func send(_ message: RedisData) -> Future<RedisData> {
        // ensure the connection is not closed
        guard !isClosed else {
            return eventLoop.newFailedFuture(error: closeError)
        }
        
        // create a new promise to fulfill later
        let promise = eventLoop.newPromise(RedisData.self)
        
        // logic to store in-flight requests that can be cancelled when connection drops
        let key = UUID().uuidString
        self.inflightPromises[key] = promise
        promise.futureResult.always {
            self.inflightPromises.removeValue(forKey: key)
        }
        
        // write the message and the promise to the channel, which the `RequestResponseHandler` will capture
        return self.channel.writeAndFlush((message, promise))
            .flatMap { return promise.futureResult }
    }

    /// Closes this client.
    public func close() {
        self.isClosed = true
        channel.close(promise: nil)
    }
}

private let closeError = RedisError(identifier: "closed", reason: "Connection is closed.")

/// MARK: Config

/// Config options for a `RedisClient.
public struct RedisClientConfig: Codable {
    /// The Redis server's hostname.
    public var hostname: String

    /// The Redis server's port.
    public var port: Int

    /// The Redis server's optional password.
    public var password: String?

    /// The database to connect to automatically.
    /// If nil, the connection will use the default 0.
    public var database: Int?

    /// Create a new `RedisClientConfig`
    public init(url: URL) {
        self.hostname = url.host ?? "localhost"
        self.port = url.port ?? 6379
        self.password = url.password
        self.database = Int(url.path)
    }

    /// Creates a new, default `RedisClientConfig`.
    public init() {
        self.hostname = "localhost"
        self.port = 6379
    }

    internal func toURL() throws -> URL {
        let urlString: String
        let databaseSuffix: String

        if let database = database {
            databaseSuffix = "/\(database)"
        } else {
            databaseSuffix = ""
        }

        if let password = password {
            urlString = "redis://:\(password)@\(hostname)\(databaseSuffix):\(port)"
        } else {
            urlString = "redis://\(hostname)\(databaseSuffix):\(port)"
        }

        guard let url = URL(string: urlString) else {
            throw RedisError(
                identifier: "URL creation",
                reason: "Redis client config could not be transformed to url.")
        }

        return url
    }
}
