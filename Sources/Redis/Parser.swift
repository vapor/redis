import Transport

/// Parses Redis Data from a Stream
public final class Parser<StreamType: DuplexStream> {
    public let stream: StreamType
    public init(_ stream: StreamType) {
        self.stream = stream
    }

    /// Parse a Redis Data from the stream
    public func parse() throws -> Data? {
        let type = try stream.readByte() ?? 0
        switch type {
        case Byte.plus:
            let string = try simple()
            return .string(string)
        case Byte.hyphen:
            let string = try simple()
            return .error(RedisError.general(string))
        case Byte.colon:
            guard let int = Int(try simple()) else {
                throw RedisError.invalidInteger
            }
            return .integer(int)
        case Byte.dollar:
            guard let bytes = try bulk() else {
                return nil
            }
            return .bulk(bytes)
        case Byte.asterisk:
            var items: [Data?] = []
            guard let length = Int(try simple()) else {
                throw RedisError.invalidInteger
            }

            guard length >= 0 else {
                return nil
            }

            for _ in 0..<length {
                items.append(try parse())
            }

            return .array(items)
        default:
            throw RedisError.unknownResponseType
        }
    }

    // MARK: Private

    /// Parse a simple redis data
    func simple() throws -> String {
        var lastByte: Byte? = nil
        var bytes: Bytes = []

        loop: while true {
            guard let byte = try stream.readByte() else {
                break loop
            }

            switch byte {
            case Byte.carriageReturn:
                break
            case Byte.newLine:
                if lastByte == .carriageReturn {
                    break loop
                }
            default:
                bytes.append(byte)
            }

            lastByte = byte
        }

        return bytes.makeString()
    }

    /// Parse bulk redis data
    func bulk() throws -> Bytes? {
        let lengthString = try simple()
        guard let length = Int(lengthString) else {
            throw RedisError.invalidInteger
        }

        guard length >= 0 else {
            return nil
        }

        let fullLength = length + 2 // including crlf

        var bytes: Bytes = []
        bytes.reserveCapacity(fullLength)

        while bytes.count < fullLength {
            bytes += try stream.read(max: fullLength)
        }

        return Array(bytes[0..<bytes.count - 2])
    }
}
