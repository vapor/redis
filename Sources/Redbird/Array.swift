//
//  Array.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct RespArray: RespObject {
    static var signature: String = "*"
    public let respType: RespType = .Array
    
    public let content: [RespObject]
}

//equatable
extension RespArray: Equatable {}
public func ==(lhs: RespArray, rhs: RespArray) -> Bool {
    
    //we cannot add Equatable on RespObject, so we'll have to do it manually here
    guard lhs.content.count == rhs.content.count else { return false }
    
    let zipped = zip(lhs.content, rhs.content)
    for (l, r) in zipped {
        guard l.respType == r.respType else { return false }
        switch l.respType {
        case .Array: guard l as! RespArray == r as! RespArray else { return false }
        case .BulkString: guard l as! RespBulkString == r as! RespBulkString else { return false }
        case .Error: guard l as! RespError == r as! RespError else { return false }
        case .Integer: guard l as! RespInteger == r as! RespInteger else { return false }
        case .NullArray: guard l as! RespNullArray == r as! RespNullArray else { return false }
        case .NullBulkString: guard l as! RespNullBulkString == r as! RespNullBulkString else { return false }
        case .SimpleString: guard l as! RespSimpleString == r as! RespSimpleString else { return false }
        }
    }
    
    return true
}
