//
//  Parsers.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

protocol Parser {
    func parse(alreadyRead: [CChar], reader: SocketReader) throws -> RespObject
}

extension Parser {
    
    func ensureReadElements(min: Int, alreadyRead: [CChar], reader: SocketReader) throws -> [CChar] {
        
        precondition(min > 0)
        
        if alreadyRead.count >= min {
            return alreadyRead
        }
        
        let leftToRead = min - alreadyRead.count
        let readChars = try reader.read(leftToRead)
        guard readChars.count == leftToRead else {
            throw RedbirdError.NotEnoughCharactersToReadFromSocket(leftToRead, alreadyRead)
        }
        return alreadyRead + readChars
    }
}

/// Does the initial "proxy" parsing to recognize type and then hands off
/// to the specific parser.
struct InitialParser: Parser {

    func parse(alreadyParsed: [CChar], reader: SocketReader) throws -> RespObject {
        
        let read = try self.ensureReadElements(1, alreadyRead: [], reader: reader)
        let signature = try read.stringView()
        
        let parser: Parser
        switch signature {
        case Error.signature: parser = ErrorParser()
        case SimpleString.signature: parser = SimpleStringParser()
        case Integer.signature: parser = IntegerParser()
        case BulkString.signature: parser = BulkStringParser()
        default:
            throw RedbirdError.ParsingStringNotThisType(try alreadyParsed.stringView(), nil)
        }
        return try parser.parse(read, reader: reader)
    }
}

/// Parses the Error type
struct ErrorParser: Parser {
    
    func parse(alreadyRead: [CChar], reader: SocketReader) throws -> RespObject {
        
        let head = try reader.readUntilDelimiter(RespTerminator)
        let read = alreadyRead + head.0
        let readString = try read.stringView()
        let inner = readString.strippedInitialSignatureAndTrailingTerminator()
        return Error(content: inner)
    }
}

/// Parses the SimpleString type
struct SimpleStringParser: Parser {
    
    func parse(alreadyRead: [CChar], reader: SocketReader) throws -> RespObject {
        
        let read = alreadyRead + (try reader.readUntilDelimiter(RespTerminator)).0
        let readString = try read.stringView()
        let inner = readString.strippedInitialSignatureAndTrailingTerminator()
        return try SimpleString(content: inner)
    }
}

/// Parses the Integer type
struct IntegerParser: Parser {
    
    func parse(alreadyRead: [CChar], reader: SocketReader) throws -> RespObject {
        
        let read = alreadyRead + (try reader.readUntilDelimiter(RespTerminator)).0
        let readString = try read.stringView()
        let inner = readString.strippedInitialSignatureAndTrailingTerminator()
        return try Integer(content: inner)
    }
}

/// Parses the BulkString type
struct BulkStringParser: Parser {
    
    func parse(alreadyRead: [CChar], reader: SocketReader) throws -> RespObject {

        //first parse the number of string bytes
        let (head, maybeTail) = try reader.readUntilDelimiter(RespTerminator)
        guard let tail = maybeTail else {
            let readSoFar = try head.stringView()
            throw RedbirdError.ReceivedStringNotTerminatedByRespTerminator(readSoFar)
        }
        let allHead = alreadyRead + head
        let rawByteCountString = try allHead.stringView()
        let byteCountString = rawByteCountString.strippedInitialSignatureAndTrailingTerminator()
        guard let byteCount = Int(byteCountString) else {
            throw RedbirdError.BulkStringProvidedUnparseableByteCount(byteCountString)
        }
        
        //if byte count is -1, then return a null string
        if byteCount == -1 {
            return NullBulkString()
        }
        
        //now read the exact number of bytes + 2 for the terminator string
        //but subtract what we've already read, which is in tail
        let bytesToRead = byteCount + 2 - tail.count
        let newChars = try reader.read(bytesToRead)
        let allChars = tail + newChars
        let allString = try allChars.stringView()
        
        let parsedBulk = allString.strippedTrailingTerminator()
        return BulkString(content: parsedBulk)
    }
}





