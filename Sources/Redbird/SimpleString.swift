//
//  SimpleString.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct SimpleString: RespObject {
    static var signature: String = "+"
    public let respType: RespType = .SimpleString
    
    public let content: String
    
    init(content: String) throws {
        if content.containsCharacter("\r") || content.containsCharacter("\n") {
            throw RedbirdError.SimpleStringInvalidInput(content)
        }
        self.content = content
    }
}

//equatable
extension SimpleString: Equatable {}
public func ==(lhs: SimpleString, rhs: SimpleString) -> Bool {
    return lhs.content == rhs.content
}

