//
//  Error.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct RespError: RespObject, ErrorProtocol {
    static var signature: String = "-"
    public let respType: RespType = .Error
    
    public let content: String
    
    //RESP allows for error to be split into "WRONGTYPE Operation against a key holding..."
    //two parts like this, where the first is an error kind and second just a message.
    //this is present in Redis implementations, but is not required by the protocol,
    //thus the optionals.
    public var kind: String? {
        return self.content.subwords().first
    }
    
    public var message: String? {
        return self.content.stringWithDroppedFirstWord()
    }
}

//equatable
extension RespError: Equatable {}
public func ==(lhs: RespError, rhs: RespError) -> Bool {
    return lhs.content == rhs.content
}

