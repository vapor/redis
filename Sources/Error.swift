//
//  Error.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

/// Parses the Error type
struct Error: RespObject {
    static var signature: String = "-"
    let respType: RespType = .Error
    
    let content: String
}
