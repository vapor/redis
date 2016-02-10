//
//  Null.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

struct Null: RespObject {
    static var signature: String = "$-1\r\n"
    var respType: RespType = .Null
}

//equatable
extension Null: Equatable {}
func ==(lhs: Null, rhs: Null) -> Bool { return true }







