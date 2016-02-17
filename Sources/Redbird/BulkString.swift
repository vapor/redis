//
//  BulkString.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct RespBulkString: RespObject {
    static var signature: String = "$"
    public let respType: RespType = .BulkString
    
    public let content: String
}

//equatable
extension RespBulkString: Equatable {}
public func ==(lhs: RespBulkString, rhs: RespBulkString) -> Bool {
    return lhs.content == rhs.content
}
