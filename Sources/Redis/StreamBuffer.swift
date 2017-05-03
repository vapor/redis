import Core
import Dispatch
import Transport

/// Buffers receive and send calls to a Stream.
///
/// Receive calls are buffered by the size used to initialize
/// the buffer.
///
/// Send calls are buffered until `flush()` is called.
final class StreamBuffer<Stream: DuplexStream>: DuplexStream {
    private let stream: Stream
    private let size: Int
    
    private var readIterator: IndexingIterator<[Byte]>
    private var writeBuffer: Bytes
    
    var isClosed: Bool {
        return stream.isClosed
    }
    
    func setTimeout(_ timeout: Double) throws {
        try stream.setTimeout(timeout)
    }
    
    func close() throws {
        try stream.close()
    }
    
    /// create a buffer steam with a chunk size
    init(_ stream: Stream, size: Int = 2048) {
        self.size = size
        self.stream = stream
        
        readIterator = Bytes().makeIterator()
        writeBuffer = []
    }
    
    /// Reads the next byte from the buffer
    func readByte() throws -> Byte? {
        guard let next = readIterator.next() else {
            readIterator = try stream.read(max: size).makeIterator()
            return readIterator.next()
        }
        return next
    }
    
    /// reads a chunk of bytes from the buffer
    /// less than max
    func read(max: Int, into buffer: inout Bytes) throws -> Int {
        var bytes = readIterator.array
        
        // while the byte count is below max
        // continue fetching, until the stream is empty
        while bytes.count < max {
            let more = max - bytes.count
            let new = try stream.read(max: more < size ? size : more)
            bytes += new
            if new.count == 0 {
                break
            }
        }
        
        // if byte count is below max,
        // set that as the cap
        let cap = bytes.count > max
            ? max
            : bytes.count
        
        // pull out the result array
        let result = bytes[0..<cap].array
        
        if cap >= bytes.count {
            // if returning all bytes,
            // create empty iterator
            readIterator = [].makeIterator()
        } else {
            // if not returning all bytes,
            // create an iterator with remaining
            let remaining = bytes[cap..<bytes.count]
            readIterator = remaining
                .array
                .makeIterator()
        }
        
        // return requested bytes
        buffer = result
        return result.count
    }
    
    /// write bytes to the buffer stream
    func write(max: Int, from buffer: Bytes) throws -> Int {
        writeBuffer += buffer

        return writeBuffer.count
    }
    
    func flush() throws {
        guard !writeBuffer.isEmpty else { return }
        _ = try stream.write(max: writeBuffer.count, from: writeBuffer)
        writeBuffer = []
    }
}
