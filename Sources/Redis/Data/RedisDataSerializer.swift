import Async
import Bits
import Foundation

/// A streaming Redis value serializer
internal final class RedisDataSerializer: ByteSerializer {
    var state: ByteSerializerState<RedisDataSerializer>
    
    typealias SerializationState = Void
    
    /// See InputStream.Input
    typealias Input = RedisData
    
    /// See OutputStream.Output
    typealias Output = ByteBuffer

    private var lastMessage: MutableByteBuffer?

    /// Creates a new ValueSerializer
    init() {
        self.state = .init()
    }
    
    func serialize(_ input: RedisData, state: Void?) throws -> ByteSerializerResult<RedisDataSerializer> {
        let data = input.serialize()
        self.lastMessage = data
        
        return .complete(ByteBuffer(start: data.baseAddress, count: data.count))
    }
    
    deinit {
        if let lastMessage = self.lastMessage {
            lastMessage.baseAddress?.deinitialize(count: lastMessage.count)
            lastMessage.baseAddress?.deallocate()
        }
    }
}

/// Static "fast" route for serializing `null` values
fileprivate let nullData = Data("$-1\r\n".utf8)

extension RedisData {
    /// Serializes a single value
    func serializeData() -> Data {
        switch self.storage {
        case .null:
            return nullData
        case .basicString(let string):
            return Data(("+" + string).utf8)
        case .error(let error):
            return Data(("-" + error.reason).utf8)
        case .integer(let int):
            return Data(":\(int)\r\n".utf8)
        case .bulkString(let data):
            return Data("$\(data.count)\r\n".utf8) + data + Data("\r\n".utf8)
        case .array(let values):
            var buffer = Data("*\(values.count)\r\n".utf8)
            for value in values {
                buffer.append(contentsOf: value.serialize())
            }
            buffer.append(contentsOf: Data("\r\n".utf8))
            return buffer
        }
    }
    
    func serialize() -> MutableByteBuffer {
        let data = serializeData()
        
        let pointer = MutableBytesPointer.allocate(capacity: data.count)
        
        data.withByteBuffer { buffer in
            _ = memcpy(pointer, buffer.baseAddress!, buffer.count)
        }
        
        return MutableByteBuffer(start: pointer, count: data.count)
    }
}
