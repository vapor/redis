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
        
        return NullBulkString.signature
    }
}

struct NullArrayFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {

        return NullArray.signature
    }
}

struct ErrorFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {

        let str = (object as! Error)
            .content
            .wrappedInitialSignatureAndTrailingTerminator(Error.signature)
        return str
    }
}

struct SimpleStringFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {

        let str = (object as! SimpleString)
            .content
            .wrappedInitialSignatureAndTrailingTerminator(SimpleString.signature)
        return str
    }
}

struct IntegerFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
 
        let str = String((object as! Integer).intContent)
            .wrappedInitialSignatureAndTrailingTerminator(Integer.signature)
        return str
    }
}

struct BulkStringFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        
        let content = (object as! BulkString).content
        
        //first count the number of bytes of the string
        let byteCount = content.ccharArrayView().count
        
        //format the outgoing string
        let str = (String(byteCount) + content)
            .wrappedInitialSignatureAndTrailingTerminator(BulkString.signature)
        return str
    }
}

struct ArrayFormatter: Formatter {
    
    func format(object: RespObject) throws -> String {
        
        fatalError("Unimplemented")
    }
}



