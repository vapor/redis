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

let formatters: [RespType: Formatter] = [
    .Array: ArrayFormatter(),
    .BulkString: BulkStringFormatter(),
    .Error: ErrorFormatter(),
    .Integer: IntegerFormatter(),
    .SimpleString: SimpleStringFormatter(),
    .NullBulkString: NullBulkStringFormatter(),
    .NullArray: NullArrayFormatter()
]

struct InitialFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        
        //find the appropriate formatter for this type
        guard let formatter = formatters[object.respType] else {
            throw RedbirdError.NoFormatterFoundForObject(object)
        }
        
        let formatted = try formatter.format(object)
        return formatted
    }
}

struct NullBulkStringFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        
        return RespNullBulkString.signature
    }
}

struct NullArrayFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {

        return RespNullArray.signature
    }
}

struct ErrorFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {

        let str = (object as! RespError)
            .content
            .wrappedInitialSignatureAndTrailingTerminator(RespError.signature)
        return str
    }
}

struct SimpleStringFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {

        let str = (object as! RespSimpleString)
            .content
            .wrappedInitialSignatureAndTrailingTerminator(RespSimpleString.signature)
        return str
    }
}

struct IntegerFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
 
        let str = String((object as! RespInteger).intContent)
            .wrappedInitialSignatureAndTrailingTerminator(RespInteger.signature)
        return str
    }
}

struct BulkStringFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        
        let content = (object as! RespBulkString).content
        
        //first count the number of bytes of the string
        let byteCount = content.ccharArrayView().count
        
        //format the outgoing string
        let prefix = String(byteCount)
            .wrappedInitialSignatureAndTrailingTerminator(RespBulkString.signature)
        let suffix = content.wrappedTrailingTerminator()
        let str = prefix + suffix
        return str
    }
}

struct ArrayFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        
        let content = (object as! RespArray).content
        
        //first count number of elements
        let count = content.count
        
        //format the outgoing string
        let prefix = String(count)
            .wrappedInitialSignatureAndTrailingTerminator(RespArray.signature)
        let suffix = try content
            .map { try InitialFormatter().format($0) }
            .reduce("", combine: +)
        let str = prefix + suffix
        return str
    }
}



