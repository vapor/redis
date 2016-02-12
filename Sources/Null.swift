//
//  Null.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

struct NullBulkString: RespObject {
    static var signature: String = "$-1\r\n"
    var respType: RespType = .NullBulkString
}

struct NullArray: RespObject {
    static var signature: String = "*-1\r\n"
    var respType: RespType = .NullArray
}

//equatable
extension NullBulkString: Equatable {}
func ==(lhs: NullBulkString, rhs: NullBulkString) -> Bool { return true }

//equatable
extension NullArray: Equatable {}
func ==(lhs: NullArray, rhs: NullArray) -> Bool { return true }






