import Async
import Bits
import NIO

final class RedisDataEncoder: MessageToByteEncoder {
    typealias OutboundIn = RedisData

    func encode(ctx: ChannelHandlerContext,
                data: RedisDataEncoder.OutboundIn,
                out: inout ByteBuffer) throws {
 //       <#code#>
    }
}
