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

struct NullFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        guard object.respType == .Null else {
            throw RedbirdError.FormatterNotForThisType(object, .Null)
        }
        
        return Null.signature
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



