//
//  Null.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct NullBulkString: RespObject {
    static var signature: String = "$-1\r\n"
    public var respType: RespType = .NullBulkString
}

public struct NullArray: RespObject {
    static var signature: String = "*-1\r\n"
    public var respType: RespType = .NullArray
}

//equatable
extension NullBulkString: Equatable {}
public func ==(lhs: NullBulkString, rhs: NullBulkString) -> Bool { return true }

//equatable
extension NullArray: Equatable {}
public func ==(lhs: NullArray, rhs: NullArray) -> Bool { return true }






