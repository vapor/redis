//
//  Array.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

struct RespArray: RespObject {
    static var signature: String = "*"
    let respType: RespType = .Array
    
    let content: [RespObject]
}

//equatable
extension RespArray: Equatable {}
func ==(lhs: RespArray, rhs: RespArray) -> Bool {
    
    //we cannot add Equatable on RespObject, so we'll have to do it manually here
    guard lhs.content.count == rhs.content.count else { return false }
    
    for (l, r) in zip(lhs.content, rhs.content) {
        guard l.respType == r.respType else { return false }
        switch l.respType {
        case .Array: return l as! RespArray == r as! RespArray
        case .BulkString: return l as! BulkString == r as! BulkString
        case .Error: return l as! Error == r as! Error
        case .Integer: return l as! Integer == r as! Integer
        case .NullArray: return l as! NullArray == r as! NullArray
        case .NullBulkString: return l as! NullBulkString == r as! NullBulkString
        case .SimpleString: return l as! SimpleString == r as! SimpleString
        }
    }
    
    return true
}
