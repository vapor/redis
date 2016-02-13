//
//  BulkString.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct BulkString: RespObject {
    static var signature: String = "$"
    public let respType: RespType = .BulkString
    
    public let content: String
}

//equatable
extension BulkString: Equatable {}
public func ==(lhs: BulkString, rhs: BulkString) -> Bool {
    return lhs.content == rhs.content
}
