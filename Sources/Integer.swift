//
//  Integer.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct Integer: RespObject {
    static var signature: String = ":"
    public let respType: RespType = .Integer
    
    public let intContent: Int64
    public var boolContent: Bool { return self.intContent != 0 }
    
    init(content: String) throws {
        
        guard let intContent = Int64(content) else {
            throw RedbirdError.SimpleStringInvalidInput(content)
        }
        self.intContent = intContent
    }
}

//equatable
extension Integer: Equatable {}
public func ==(lhs: Integer, rhs: Integer) -> Bool {
    return lhs.intContent == rhs.intContent
}

