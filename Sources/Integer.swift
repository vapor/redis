//
//  Integer.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

struct Integer: RespObject {
    static var signature: String = ":"
    let respType: RespType = .Integer
    
    let intContent: Int64
    var boolContent: Bool { return self.intContent != 0 }
    
    init(content: String) throws {
        
        guard let intContent = Int64(content) else {
            throw RedbirdError.SimpleStringInvalidInput(content)
        }
        self.intContent = intContent
    }
}

//equatable
extension Integer: Equatable {}
func ==(lhs: Integer, rhs: Integer) -> Bool {
    return lhs.intContent == rhs.intContent
}

