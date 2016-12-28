//
//  Parsers.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

protocol Parser {
    
    /// takes already read chars and the reader, returns the parsed response
    /// object and the read, but unused trailing characters
    func parse(_ alreadyRead: [Byte], reader: SocketReader) throws -> (RespObject, [Byte])
}

extension Parser {
    
    func ensureReadElements(min: Int, alreadyRead: [Byte], reader: SocketReader) throws -> [Byte] {
        
        precondition(min > 0)
        
        if alreadyRead.count >= min {
            return alreadyRead
        }
        
        let leftToRead = min - alreadyRead.count
        let readChars = try reader.read(bytes: leftToRead)
        guard readChars.count > 0 else {
            throw RedbirdError.noDataFromSocket
        }
        guard readChars.count == leftToRead else {
            throw RedbirdError.notEnoughCharactersToReadFromSocket(leftToRead, alreadyRead)
        }
        return alreadyRead + readChars
    }
}

/// Does the initial "proxy" parsing to recognize type and then hands off
/// to the specific parser.
struct InitialParser: Parser {

    func parse(_ alreadyRead: [Byte], reader: SocketReader) throws -> (RespObject, [Byte]) {
        
        let read = try self.ensureReadElements(min: 1, alreadyRead: alreadyRead, reader: reader)

        //just take the first char of read, can be more than 1
        let signature = try read.prefix(1).stringView()
        
        let parser: Parser
        switch signature {
            case RespError.signature: parser = ErrorParser()
            case RespSimpleString.signature: parser = SimpleStringParser()
            case RespInteger.signature: parser = IntegerParser()
            case RespBulkString.signature: parser = BulkStringParser()
            case RespArray.signature: parser = ArrayParser()
            default:
                throw RedbirdError.parsingStringNotThisType(try alreadyRead.stringView(), nil)
        }
        
        return try parser.parse(read, reader: reader)
    }
}

/// Parses the Error type
struct ErrorParser: Parser {
    
    func parse(_ alreadyRead: [Byte], reader: SocketReader) throws -> (RespObject, [Byte]) {
        
        let (head, tail) = try reader.readUntilDelimiter(alreadyRead: alreadyRead, delimiter: RespTerminator)
        let readString = try head.stringView()
        let inner = readString.strippedInitialSignatureAndTrailingTerminator()
        let parsed = RespError(content: inner)
        return (parsed, tail ?? [])
    }
}

/// Parses the SimpleString type
struct SimpleStringParser: Parser {
    
    func parse(_ alreadyRead: [Byte], reader: SocketReader) throws -> (RespObject, [Byte]) {
        
        let (head, tail) = try reader.readUntilDelimiter(alreadyRead: alreadyRead, delimiter: RespTerminator)
        let readString = try head.stringView()
        let inner = readString.strippedInitialSignatureAndTrailingTerminator()
        let parsed = try RespSimpleString(content: inner)
        return (parsed, tail ?? [])
    }
}

/// Parses the Integer type
struct IntegerParser: Parser {
    
    func parse(_ alreadyRead: [Byte], reader: SocketReader) throws -> (RespObject, [Byte]) {
        
        let (head, tail) = try reader.readUntilDelimiter(alreadyRead: alreadyRead, delimiter: RespTerminator)
        let readString = try head.stringView()
        let inner = readString.strippedInitialSignatureAndTrailingTerminator()
        let parsed = try RespInteger(content: inner)
        return (parsed, tail ?? [])
    }
}

/// Parses the BulkString type
struct BulkStringParser: Parser {
    
    func parse(_ alreadyRead: [Byte], reader: SocketReader) throws -> (RespObject, [Byte]) {

        //first parse the number of string bytes
        let (head, maybeTail) = try reader.readUntilDelimiter(alreadyRead: alreadyRead, delimiter: RespTerminator)
        guard let tail = maybeTail else {
            let readSoFar = try head.stringView()
            throw RedbirdError.receivedStringNotTerminatedByRespTerminator(readSoFar)
        }
        let rawByteCountString = try head.stringView()
        let byteCountString = rawByteCountString.strippedInitialSignatureAndTrailingTerminator()
        guard let byteCount = Int(byteCountString) else {
            throw RedbirdError.bulkStringProvidedUnparseableByteCount(byteCountString)
        }
        
        //if byte count is -1, then return a null string
        if byteCount == -1 {
            return (RespNullBulkString(), tail)
        }
        
        //now read the exact number of bytes + 2 for the terminator string
        //but subtract what we've already read, which is in tail
        let requiredCount = byteCount + 2
        let bytesToRead = requiredCount - tail.count
        
        //if we have exactly or more than needed bytes in tail
        //bytesToRead will be 0 or negative
        //in such case, split the tail into prefixTail, which we'll use
        //and suffixTail that we'll pass along
        
        var neededChars: [Byte] = []
        var suffixTail: [Byte] = []
        
        if bytesToRead <= 0 {
            //we've read enough/more than needed
            neededChars = Array(tail.prefix(requiredCount))
            suffixTail = Array(tail.suffix(tail.count - requiredCount))
        } else {
            
            //we need to read further chars
            //but the read fn might give us less than we need, so we need
            //to call it repeatedly until we read everything
            neededChars.append(contentsOf: tail)
            
            while neededChars.count < requiredCount {
                let chunkSize = requiredCount - neededChars.count
                let newlyRead = try reader.read(bytes: chunkSize)
                neededChars.append(contentsOf: newlyRead)
            }
            
            //sanity check
            precondition(neededChars.count == requiredCount, "Read incorrect number of bytes")
            suffixTail = []
        }
        
        
        let allString = try neededChars.stringView()
        let parsedBulk = allString.strippedTrailingTerminator()
        return (RespBulkString(content: parsedBulk), suffixTail)
    }
}

// Parses the Array type
struct ArrayParser: Parser {
    
    func parse(_ alreadyRead: [Byte], reader: SocketReader) throws -> (RespObject, [Byte]) {
        
        //first parse the number of string bytes
        let (head, maybeTail) = try reader.readUntilDelimiter(alreadyRead: alreadyRead, delimiter: RespTerminator)
        guard let tail = maybeTail else {
            let readSoFar = try head.stringView()
            throw RedbirdError.receivedStringNotTerminatedByRespTerminator(readSoFar)
        }
        let rawCountString = try head.stringView()
        let countString = rawCountString.strippedInitialSignatureAndTrailingTerminator()
        let count = Int(countString) ?? 3 // Default to 3 if not specified
        
        //if byte count is -1, then return a null array
        if count == -1 {
            return (RespNullArray(), tail)
        }
        
        //now read in a for loop that many elements,
        //each time using the initial parser and collecting the leftovers
        var elements = [RespObject]()
        var elTail = tail
        while elements.count < count {
            let (parsed, leftovers) = try InitialParser().parse(elTail, reader: reader)
            elTail = leftovers
            elements.append(parsed)
        }
        
        let array = RespArray(content: elements)
        return (array, elTail)
    }
}






