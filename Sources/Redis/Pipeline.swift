import Transport

public class Pipeline<StreamType: DuplexStream> {
    public let client: Client<StreamType>
    private var queuedCommands = 0

    public init(_ client: Client<StreamType>) {
        self.client = client
    }

    @discardableResult
    public func enqueue(_ command: Command, params: [Bytes] = []) throws -> Pipeline {
        let query = client.format(command, params)
        try client.serializer.serialize(query)
        queuedCommands += 1
        return self
    }

    @discardableResult
    public func execute() throws -> [Data?] {
        guard queuedCommands > 0 else {
            throw RedisError.pipelineCommandsRequired
        }

        try client.serializer.flush()

        var responses: [Data?] = []
        for _ in 0..<queuedCommands {
            let data = try client.parser.parse()
            responses.append(data)
        }

        queuedCommands = 0

        return responses
    }
}

extension Pipeline {
    @discardableResult
    public func enqueue(_ command: Command, _ params: [BytesRepresentable]) throws -> Pipeline {
        let params = try params.map { try $0.makeBytes() }
        return try self.enqueue(command, params: params)
    }
}
