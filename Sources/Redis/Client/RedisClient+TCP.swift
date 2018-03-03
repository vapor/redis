import Async
import TCP

extension RedisClient {
    /// Connects to a Redis server using a TCP socket.
    public static func connect(
        hostname: String = "localhost",
        port: UInt16 = 6379,
        on worker: Worker,
        onError: @escaping TCPSocketSink.ErrorHandler
    ) throws -> RedisClient {
        let socket = try TCPSocket(isNonBlocking: true)
        let client = try TCPClient(socket: socket)
        try client.connect(hostname: hostname, port: port)
        let stream = socket.stream(on: worker, onError: onError)
        return RedisClient(stream: stream, on: worker)
    }

    /// Subscribes to a Redis channel using a TCP socket.
    public static func subscribe(
        to channels: Set<String>,
        hostname: String = "localhost",
        port: UInt16 = 6379,
        on worker: Worker,
        onError: @escaping TCPSocketSink.ErrorHandler
    ) throws -> Future<RedisChannelStream> {
        let socket = try TCPSocket(isNonBlocking: true)
        let client = try TCPClient(socket: socket)
        try client.connect(hostname: hostname, port: port)
        let stream = socket.stream(on: worker, onError: onError)
        return RedisClient.subscribe(to: channels, stream: stream, on: worker)
    }
}
