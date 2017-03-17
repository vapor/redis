import Transport

/// Redis client for executing commands
public final class Client<StreamType: DuplexStream> {
    public let stream: StreamType
    let serializer: Serializer<StreamType>
    let parser: Parser<StreamType>

    /// Create a new redis client
    init(_ stream: StreamType, password: String? = nil) throws {
        self.stream = stream

        serializer = Serializer(stream)
        parser = Parser(stream)
        
        if let password = password {
            try self.command(.authorize, [password])
        }
    }

    /// Execute a command on the Redis client
    @discardableResult
    public func command(_ command: Command, _ params: [Bytes] = []) throws -> Data {
        var parts: [Data] = [.bulk(command.raw)]
        params.forEach { param in
            parts.append(.bulk(param))
        }
        let query = Data.array(parts)
        try serializer.serialize(query)
        let res = try parser.parse()
        return res
    }
    
    public func pipeline() -> Pipeline<StreamType> {
        return Pipeline(self)
    }
}

extension Client {
    /// Execute a command using Bytes Reprsentable parameters.
    @discardableResult
    public func command(_ command: Command, _ params: [BytesRepresentable]) throws -> Data {
        let params = try params.map { try $0.makeBytes() }
        return try self.command(command, params)
    }
}
