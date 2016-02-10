//
//  Types.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

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

protocol RespEncodable {
    func encode() -> String
}

protocol RespDecodable {
    init(input: String)
}

protocol RESPCodable: RespEncodable, RespDecodable {}



