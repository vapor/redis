//
//  BulkString.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

struct BulkString: RespObject {
    static var signature: String = "$"
    let respType: RespType = .BulkString
    
    let content: String
}

//equatable
extension BulkString: Equatable {}
func ==(lhs: BulkString, rhs: BulkString) -> Bool {
    return lhs.content == rhs.content
}
