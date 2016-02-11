//
//  Types.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

let RespTerminator = "\r\n"

enum RespType {
    case Array
    case BulkString
    case Error
    case Integer
    case Null
    case SimpleString
}

protocol RespObject {
    var respType: RespType { get }
}
