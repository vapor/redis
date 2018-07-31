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
        out.write(bytes: encode(data: data))
    }

    /// Base encoding method
    private func encode(data: RedisData) -> Data {
        switch data.storage {
        case let .basicString(basicString):
            return "+\(basicString)\r\n".convertToData()
        case let .error(err):
            return "-\(err.reason)\r\n".convertToData()
        case let .integer(integer):
            return ":\(integer)\r\n".convertToData()
        case let .bulkString(bulkData):
            return "$\(bulkData.count)\r\n".convertToData() + bulkData + "\r\n".convertToData()
        case .null:
            return "$-1\r\n".convertToData()
        case let .array(array):
            let dataEncodedArray = array.map { encode(data: $0) }.joined()
            return "*\(array.count)\r\n".convertToData() + dataEncodedArray
        }
    }
}
