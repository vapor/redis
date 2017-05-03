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

    func format(_ command: Command, _ params: [Bytes]) -> Data {
        var parts: [Data] = [.bulk(command.raw)]
        params.forEach { param in
            parts.append(.bulk(param))
        }
        return Data.array(parts)
    }

    /// Execute a command on the Redis client
    @discardableResult
    public func command(_ command: Command, _ params: [Bytes] = []) throws -> Data? {
        let query = format(command, params)
        try serializer.serialize(query)

        let res = try parser.parse()
        if let data = res, case .error(let e) = data {
            throw e
        }
        return res
    }
    
    public func makePipeline() -> Pipeline<StreamType> {
        return Pipeline(self)
    }
    
    deinit {
        try? stream.close()
    }
}

extension Client {
    /// Execute a command using Bytes Reprsentable parameters.
    @discardableResult
    public func command(_ command: Command, _ params: [BytesRepresentable]) throws -> Data? {
        let params = try params.map { try $0.makeBytes() }
        return try self.command(command, params)
    }
}
