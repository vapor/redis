//
//  SimpleString.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

struct SimpleString: RespObject {
    static var signature: String = "+"
    let respType: RespType = .SimpleString
    
    let content: String
    
    init(content: String) throws {
        if content.containsString("\r") || content.containsString("\n") {
            throw RedbirdError.SimpleStringInvalidInput(content)
        }
        self.content = content
    }
}


