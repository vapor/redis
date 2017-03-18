import Transport

/// Serializes Redis Data to a Stream
public final class Serializer<StreamType: DuplexStream> {
    public let stream: StreamBuffer<StreamType>
    public init(_ stream: StreamType) {
        self.stream = StreamBuffer(stream)
    }

    /// Serialize the Redis Data into
    /// the Serializer's stream
    public func serialize(_ r: Data) throws {
        let bytes = makeBytes(from: r)
        try stream.write(bytes)
    }

    public func flush() throws {
        try stream.flush()
    }

    /// Convert the Redis Data into bytes
    public func makeBytes(from resp: Data?) -> Bytes {
        guard let resp = resp else {
            return null()
        }

        switch resp {
        case .string(let s):
            return simple(s)
        case .array(let a):
            return array(a)
        case .bulk(let bytes):
            return bulk(bytes)
        case .error(let e):
            return simple("\(e)", type: .hyphen)
        case .integer(let i):
            return simple(i.description, type: .colon)
        }
    }

    // MARK: Private

    /// Serialize an array of Data
    func array(_ items: [Data?]) -> Bytes {
        var array: Bytes = []
        let serializedItems = items.map(makeBytes)
        let count = serializedItems.decimalCount

        var serializedCount = 0
        serializedItems.forEach { item in
            serializedCount += item.count
        }

        array.reserveCapacity(
            1                   // * (type)
            + count.count       // array length in decimal
            + 2                 // crlf
            + serializedCount   // items
        )

        array.append(.asterisk)
        array += count
        array += Byte.crlf
        serializedItems.forEach { item in
            array += item
        }
        
        return array
    }

    /// serialize a string
    func simple(_ string: String, type: Byte = .plus) -> Bytes {
        var simple: Bytes = []
        let bytes = string.makeBytes()

        simple.reserveCapacity(
            1               // + (type)
            + bytes.count   // data
            + 2             // crlf
        )

        simple.append(.plus)
        simple += bytes
        simple += Byte.crlf
        
        return simple
    }

    /// serialize bytes
    func bulk(_ bytes: Bytes) -> Bytes {
        var bulk: Bytes = []
        let count = bytes.decimalCount

        bulk.reserveCapacity(
            1               // $ (type)
            + count.count   // data length in decimal
            + 2             // crlf
            + bytes.count   // data
            + 2             // crlf
        )

        bulk.append(.dollar)
        bulk += count
        bulk += Byte.crlf
        bulk += bytes
        bulk += Byte.crlf

        return bulk
    }

    func null() -> Bytes {
        // $-1\r\n
        return [
            .dollar,
            .hyphen,
            .one,
            .carriageReturn,
            .newLine
        ]
    }
}

extension Array {
    var decimalCount: Bytes {
        return self
            .count
            .description
            .makeBytes()
    }
}
