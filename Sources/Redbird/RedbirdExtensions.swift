//
//  RedbirdExtensions.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/13/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

//TODO: https://github.com/czechboy0/Redbird/issues/4

extension Redbird {
    
    public func auth(password password: String) throws {
        let ret = try self.command("AUTH", params: [password])
        switch ret.respType {
        case .Error: throw try ret.toError()
        case .SimpleString: if try ret.toString() == "OK" { return }
        default: break
        }
        throw RedbirdError.UnexpectedReturnedObject(ret)
    }
}
