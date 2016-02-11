//
//  Error.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

struct Error: RespObject {
    static var signature: String = "-"
    let respType: RespType = .Error
    
    let content: String
    
    //RESP allows for error to be split into "WRONGTYPE Operation against a key holding..."
    //two parts like this, where the first is an error kind and second just a message.
    //this is present in Redis implementations, but is not required by the protocol,
    //thus the optionals.
    var kind: String? {
        return self.content.componentsSeparatedByString(" ").first
    }
    
    var message: String? {
        return self.content
            .componentsSeparatedByString(" ")
            .dropFirst()
            .joinWithSeparator(" ")
    }
}
