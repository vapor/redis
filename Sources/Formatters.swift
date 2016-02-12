//
//  Formatters.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

protocol Formatter {
    func format(object: RespObject) throws -> String
}

let formatters: [Formatter] = [
]

struct NullBulkStringFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        guard object.respType == .NullBulkString else {
            throw RedbirdError.FormatterNotForThisType(object, .NullBulkString)
        }
        
        return NullBulkString.signature
    }
}

struct NullArrayFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        guard object.respType == .NullArray else {
            throw RedbirdError.FormatterNotForThisType(object, .NullArray)
        }
        
        return NullArray.signature
    }
}

struct ErrorFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        guard object.respType == .Error else {
            throw RedbirdError.FormatterNotForThisType(object, .Error)
        }
        
        let str = (object as! Error)
            .content
            .wrappedInitialSignatureAndTrailingTerminator(Error.signature)
        return str
    }
}

struct SimpleStringFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        guard object.respType == .SimpleString else {
            throw RedbirdError.FormatterNotForThisType(object, .SimpleString)
        }
        
        let str = (object as! SimpleString)
            .content
            .wrappedInitialSignatureAndTrailingTerminator(SimpleString.signature)
        return str
    }
}

struct IntegerFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        guard object.respType == .Integer else {
            throw RedbirdError.FormatterNotForThisType(object, .Integer)
        }
        
        let str = String((object as! Integer).intContent)
            .wrappedInitialSignatureAndTrailingTerminator(Integer.signature)
        return str
    }
}



