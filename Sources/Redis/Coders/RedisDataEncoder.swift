import Async
import Bits
import NIO

final class RedisDataEncoder: MessageToByteEncoder {
    typealias OutboundIn = RedisData

    /// Called once there is data to encode. The used `ByteBuffer` is allocated by `allocateOutBuffer`.
    ///
    /// - parameters:
    ///     - ctx: The `ChannelHandlerContext` which this `ByteToMessageDecoder` belongs to.
    ///     - data: The data to encode into a `ByteBuffer`.
    ///     - out: The `ByteBuffer` into which we want to encode.
    func encode(
        ctx: ChannelHandlerContext,
        data: RedisDataEncoder.OutboundIn,
        out: inout ByteBuffer
    ) throws {
        out.write(string: encode(data: data))
    }

    /// Base encoding method
    private func encode(data: RedisData) -> String {
        switch data.storage {
        case let .basicString(basicString):
            return "+\(basicString)\r\n"
        case let .error(err):
            return "-\(err.reason)\r\n"
        case let .integer(integer):
            return ":\(integer)\r\n"
        case let .bulkString(bulkString):
            let bytes = [UInt8](bulkString)
            // This is kind of primitive considering bulk strings can be 512mb... should this be chunked?
            let string = String(bytes: bytes, encoding: .utf8) ?? ""
            return "$\(bytes.count)\r\n\(string)\r\n"
        case .null:
            return "$-1\r\n"
        case let .array(array):
            let stringEncodedArray = array.map { encode(data: $0) }.joined()
            return "*\(array.count)\r\n\(stringEncodedArray)"
        }
    }
}
