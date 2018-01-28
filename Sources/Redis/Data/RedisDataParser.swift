import Async
import Bits
import Foundation

/// A streaming Redis data parser
internal final class RedisDataParser: ByteParser {
    var state: ByteParserState<RedisDataParser>
    
    /// See InputStream.Input
    typealias Input = ByteBuffer
    
    /// See OutputStream.RedisData
    typealias Output = RedisData
    
    /// The in-progress parsing value
    typealias Partial = PartialRedisData
    
    /// Creates a new RedisDataParser
    init() {
        state = .init()
    }
    
    func parseBytes(from buffer: ByteBuffer, partial: RedisDataParser.Partial?) throws -> Future<ByteParserResult<RedisDataParser>> {
        var value = partial ?? .notYetParsed
        var offset = 0
        
        if try continueParsing(partial: &value, from: buffer, at: &offset) {
            guard case .parsed(let value) = value else {
                throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
            }
            
            return Future(.completed(consuming: offset, result: value))
        } else {
            return Future(.uncompleted(value))
        }
    }
    
    /// Parses a basic String (no \r\n's) `String` starting at the current position
    fileprivate func simpleString(from input: ByteBuffer, at offset: inout Int) -> String? {
        var carriageReturnFound = false
        var base = offset
        
        // Loops until the carriagereturn
        detectionLoop: while offset < input.count {
            offset += 1
            
            if input[offset] == .carriageReturn {
                carriageReturnFound = true
                break detectionLoop
            }
        }
        
        // Expects a carriage return
        guard carriageReturnFound else {
            return nil
        }
        
        // newline
        guard offset < input.count, input[offset + 1] == .newLine else {
            return nil
        }
        
        // past clrf
        defer { offset += 2 }
        
        // Returns a String initialized with this data
        return String(bytes: input[base..<offset], encoding: .utf8)
    }
    
    /// Parses an integer associated with the token at the provided position
    fileprivate func integer(from input: ByteBuffer, at offset: inout Int) throws -> Int? {
        // Parses a string
        guard let string = simpleString(from: input, at: &offset) else {
            return nil
        }
        
        // Instantiate the integer
        guard let number = Int(string) else {
            throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
        }
        
        return number
    }
    
    /// Parses the value for the provided Token at the current position
    ///
    /// - throws: On an unexpected result
    /// - returns: The value (and if it's completely parsed) as a tuple, or `nil` if more data is needed to continue
    fileprivate func parseToken(_ token: UInt8, from input: ByteBuffer, at position: inout Int) throws -> PartialRedisData {
        switch token {
        case .plus:
            // Simple string
            guard let string = simpleString(from: input, at: &position) else {
                throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
            }
            
            return .parsed(.basicString(string))
        case .hyphen:
            // Error
            guard let string = simpleString(from: input, at: &position) else {
                throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
            }

            let error = RedisError(identifier: "serverSide", reason: string)
            return .parsed(.error(error))
        case .colon:
            // Integer
            guard let number = try integer(from: input, at: &position) else {
                throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
            }
            
            return .parsed(.integer(number))
        case .dollar:
            // Bulk strings start with their length
            guard let size = try integer(from: input, at: &position) else {
                throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
            }
            
            // Negative bulk strings are `null`
            if size < 0 {
                return .parsed(.null)
            }
            
            // Parse the following length in data
            guard
                size > -1,
                size < input.distance(from: position, to: input.endIndex)
            else {
                throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
            }
            
            let endPosition = input.index(position, offsetBy: size)
            
            defer {
                position = input.index(position, offsetBy: size + 2)
            }
            
            return .parsed(.bulkString(Data(input[position..<endPosition])))
        case .asterisk:
            // Arrays start with their element count
            guard let size = try integer(from: input, at: &position) else {
                throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
            }
            
            guard size >= 0 else {
                throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
            }
            
            var array = [PartialRedisData](repeating: .notYetParsed, count: size)
            
            // Parse all elements
            for index in 0..<size {
                guard input.count - position >= 1 else {
                    return .parsing(array)
                }
                
                let token = input[position]
                position += 1
                
                // Parse the individual nested element
                let result = try parseToken(token, from: input, at: &position)
                
                array[index] = result
            }
            
            let values = try array.map { value -> RedisData in
                guard case .parsed(let value) = value else {
                    throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
                }
                
                return value
            }
            
            // All elements have been parsed, return the complete array
            return .parsed(.array(values))
        default:
            throw RedisError(identifier: "invalidTypeToken", reason: "Unexpected error while parsing RedisData.")
        }
    }
    
    fileprivate func continueParsing(partial value: inout PartialRedisData, from input: ByteBuffer, at offset: inout Int) throws -> Bool {
        // Parses every `notyetParsed`
        switch value {
        case .parsed(_):
            return true
        case .notYetParsed:
            // need 1 byte for the token
            guard input.count - offset >= 1 else {
                return false
            }
            
            let token = input[offset]
            offset += 1
            
            value = try parseToken(token, from: input, at: &offset)
            
            if case .parsed(_) = value {
                return true
            }
        case .parsing(var values):
            for i in 0..<values.count {
                guard try continueParsing(partial: &values[i], from: input, at: &offset) else {
                    value = .parsing(values)
                    return false
                }
            }
            
            let values = try values.map { value -> RedisData in
                guard case .parsed(let value) = value else {
                    throw RedisError(identifier: "parse", reason: "Unexpected error while parsing RedisData.")
                }
                
                return value
            }
            
            value = .parsed(.array(values))
            return true
        }
        
        return false
    }
}

/// A parsing-in-progress Redis value
indirect enum PartialRedisData {
    /// Placeholder for values in arrays
    case notYetParsed
    
    /// An array that's being parsed
    case parsing([PartialRedisData])
    
    /// A correctly parsed value
    case parsed(RedisData)
}
