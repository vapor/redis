import Foundation
import NIO

// Candidate to move to Vapor/Core/Bits

/// Peek Buffers Readable Bytes
extension ByteBuffer {
    internal func peekBytes(at skipping: Int = 0, length: Int) -> [UInt8]? {
        guard let bytes = getBytes(at: skipping + readerIndex, length: length) else { return nil }
        return bytes
    }
}
