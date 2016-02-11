//
//  Redbird.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

///Redis client object
class Redbird {
    
    let socket: ClientSocket
    
    init(address: String = "127.0.0.1", port: Int = 6379) throws {
		
        self.socket = try ClientSocket(address: address, port: port)
	}
    
    func command(name: String) throws -> RespObject {
        
        let formatted = CommandSendFormatter().commandToString(name)
        try self.socket.write(formatted)
        let response = try self.socket.readAll()
        let responseObject = try DefaultParser().parse(response)
        return responseObject
    }
}

/// Command convenience functions
extension Redbird {
    
}

struct CommandSendFormatter {
    
    private let terminator = "\r\n"
    
    func commandToString(command: String) -> String {
        let out = [
            command,
            terminator
        ].joinWithSeparator("")
        return out
    }
}

