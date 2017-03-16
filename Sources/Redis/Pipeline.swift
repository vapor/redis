public class Pipeline {
    public let client: Client
    private var commands: [Bytes] = []

    public init(_ client: Client) {
        self.client = client
    }

    public func enqueue(_ command: Command, params: [Bytes] = []) throws -> Pipeline {
        var parts: [Data] = [.bulk(command.raw)]
        params.forEach { param in
            parts.append(.bulk(param))
        }
        let query = Data.array(parts)
        let bytes = client.serializer.makeBytes(from: query)
        commands.append(bytes)
        return self
    }

    @discardableResult
    public func execute() throws -> [Data] {
        guard self.commands.count > 0 else {
            throw RedisError.pipelineCommandsRequired
        }

        let formatted = commands.joined().array
        try client.stream.write(formatted)

        var responses: [Data] = []
        for _ in commands {
            responses.append(try client.parser.parse())
        }

        commands = []

        return responses
    }
}

extension Pipeline {
    public func enqueue(_ command: Command, _ params: [BytesRepresentable]) throws -> Pipeline {
        let params = try params.map { try $0.makeBytes() }
        return try self.enqueue(command, params: params)
    }
}
