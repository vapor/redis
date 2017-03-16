public protocol Stream {
    func close() throws
}

public protocol ReadableStream: Stream {
    func read(maxBytes: Int) throws -> Bytes
}

public protocol WriteableStream: Stream {
    func write(_ bytes: Bytes) throws
}

public typealias DuplexStream = ReadableStream & WriteableStream

extension TCPInternetSocket: DuplexStream {
    public func read(maxBytes: Int) throws -> Bytes {
        let bytes = try recv(maxBytes: maxBytes)
        guard bytes.count > 0 else {
            throw SocksError(.readFailed)
        }
        return bytes
    }

    public func write(_ bytes: Bytes) throws {
        try send(data: bytes)
    }
}

import Socks

public var defaultHostname = "127.0.0.1"
public var defaultPort: UInt16 = 6379

extension Client {
    public convenience init(
        hostname: String = defaultHostname,
        port: UInt16 = defaultPort,
        password: String? = nil
    ) throws {
        let addr = InternetAddress(hostname: hostname, port: port)
        let socket = try TCPInternetSocket(address: addr)
        try socket.connect()
        try self.init(socket, password: password)
    }
}
