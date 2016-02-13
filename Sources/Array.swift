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
        case .BulkString: guard l as! BulkString == r as! BulkString else { return false }
        case .Error: guard l as! Error == r as! Error else { return false }
        case .Integer: guard l as! Integer == r as! Integer else { return false }
        case .NullArray: guard l as! NullArray == r as! NullArray else { return false }
        case .NullBulkString: guard l as! NullBulkString == r as! NullBulkString else { return false }
        case .SimpleString: guard l as! SimpleString == r as! SimpleString else { return false }
        }
    }
    
    return true
}
