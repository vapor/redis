//
//  SimpleString.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct RespSimpleString: RespObject {
    static let signature: String = "+"
    public let respType: RespType = .SimpleString
    
    public let content: String
    
    init(content: String) throws {
        if content.contains(character: "\r") || content.contains(character: "\n") {
            throw RedbirdError.simpleStringInvalidInput(content)
        }
        self.content = content
    }
}

//equatable
extension RespSimpleString: Equatable {}
public func ==(lhs: RespSimpleString, rhs: RespSimpleString) -> Bool {
    return lhs.content == rhs.content
}

