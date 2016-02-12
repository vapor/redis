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
    
    func command(name: String, params: [String] = []) throws -> RespObject {
        
        //format the outgoing command into a Resp string
        let formatted = CommandSendFormatter().commandToString(name)

        //send the command string
        try self.socket.write(formatted)

        //delegate reading to parsers
        let reader: SocketReader = self.socket
        
        //try to parse the string into a Resp object, fail if no parser accepts it
        let responseObject = try InitialParser().parse([], reader: reader)
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

