import Async
import TCP

extension RedisClient {
    /// Connects to a Redis server using a TCP socket.
    public static func connect(
        hostname: String = "localhost",
        port: UInt16 = 6379,
        on worker: Worker
    ) throws -> RedisClient {
        let socket = try TCPSocket(isNonBlocking: true)
        let client = try TCPClient(socket: socket)
        try client.connect(hostname: hostname, port: port)
        return RedisClient(stream: socket.stream(on: worker), on: worker)
    }

    /// Subscribes to a Redis channel using a TCP socket.
    public static func subscribe(
        to channels: Set<String>,
        hostname: String = "localhost",
        port: UInt16 = 6379,
        on worker: Worker
    ) throws -> Future<RedisChannelStream> {
        let socket = try TCPSocket(isNonBlocking: true)
        let client = try TCPClient(socket: socket)
        try client.connect(hostname: hostname, port: port)
        return RedisClient.subscribe(to: channels, stream: socket.stream(on: worker), on: worker)
    }
}
