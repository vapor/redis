//
//  Parsers.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

protocol Parser {
    func parse(string: String) throws -> RespObject
}

let RespTerminator = "\r\n"

/// Tries parsing with all available parsers before one successfully parses the string, otherwise fails
struct DefaultParser: Parser {

    let parsers: [Parser] = [
        NullParser(),
        ErrorParser()
    ]

    func parse(string: String) throws -> RespObject {
        
        for p in self.parsers {
            if let object = try? p.parse(string) {
                return object
            }
        }
        throw RedbirdError.ParsingStringNotThisType(string, nil)
    }
}

/// Parses the Null type
struct NullParser: Parser {
    
    func parse(string: String) throws -> RespObject {
        guard string.hasPrefix(Null.signature) else {
            throw RedbirdError.ParsingStringNotThisType(string, RespType.Null)
        }
        return Null()
    }
}

/// Parses the Error type
struct ErrorParser: Parser {
    
    func parse(string: String) throws -> RespObject {
        guard string.hasPrefix(Error.signature) else {
            throw RedbirdError.ParsingStringNotThisType(string, RespType.Error)
        }
        
        //it is an error, strip leading signature and trailing terminator
        let inner = string.strippedInitialSignatureAndTrailingTerminator()
        return Error(content: inner)
    }
}

/// Parses the SimpleString type
struct SimpleStringParser: Parser {
    
    func parse(string: String) throws -> RespObject {
        guard string.hasPrefix(SimpleString.signature) else {
            throw RedbirdError.ParsingStringNotThisType(string, RespType.SimpleString)
        }
        
        //it is a simple string, strip leading signature and trailing terminator
        let inner = string.strippedInitialSignatureAndTrailingTerminator()
        return try SimpleString(content: inner)
    }
}





