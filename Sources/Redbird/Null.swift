//
//  Null.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct RespNullBulkString: RespObject {
    static let signature: String = "$-1\r\n"
    public var respType: RespType = .NullBulkString
}

public struct RespNullArray: RespObject {
    static var signature: String = "*-1\r\n"
    public var respType: RespType = .NullArray
}

//equatable
extension RespNullBulkString: Equatable {}
public func ==(lhs: RespNullBulkString, rhs: RespNullBulkString) -> Bool { return true }

//equatable
extension RespNullArray: Equatable {}
public func ==(lhs: RespNullArray, rhs: RespNullArray) -> Bool { return true }






