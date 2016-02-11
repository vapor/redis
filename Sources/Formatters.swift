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
