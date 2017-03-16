/// Parses Redis Data from a Stream
public final class Parser {
    public let stream: ReadableStream
    public init(_ stream: ReadableStream) {
        self.stream = stream
    }

    /// Parse a Redis Data from the stream
    public func parse() throws -> Data {
        let type = try stream.read(maxBytes: 1).first ?? 0
        switch type {
        case Byte.plus:
            let string = try simple()
            return .string(string)
        case Byte.hyphen:
            let string = try simple()
            return .error(string)
        case Byte.colon:
            guard let int = Int(try simple()) else {
                throw "int was not an int"
            }
            return .integer(int)
        case Byte.dollar:
            let bytes = try bulk()
            return .bulk(bytes)
        case Byte.asterisk:
            var items: [Data] = []
            guard let int = Int(try simple()) else {
                throw "int was not an int"
            }

            for _ in 0..<int {
                items.append(try parse())
            }

            return .array(items)
        default:
            throw "unknown type"
        }
    }

    // MARK: Private

    /// Parse a simple redis data
    func simple() throws -> String {
        var lastByte: Byte? = nil
        var bytes: Bytes = []

        loop: while true {
            guard let byte = try stream.read(maxBytes: 1).first else {
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
    func bulk() throws -> Bytes {
        let lengthString = try simple()
        guard let length = Int(lengthString) else {
            throw "length was not a string"
        }
        let fullLength = length + 2 // including crlf

        var bytes: Bytes = []
        bytes.reserveCapacity(fullLength)

        while bytes.count < fullLength {
            bytes += try stream.read(maxBytes: fullLength)
        }

        return Array(bytes[0..<bytes.count - 2])
    }
}

extension String: Error {}
