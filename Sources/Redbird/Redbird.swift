//
//  Redbird.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

///Redis client object
public class Redbird {
    
    let socket: ClientSocket

    public var address: String { return self.socket.address }
    public var port: Int { return self.socket.port }
    
    public init(address: String = "127.0.0.1", port: Int = 6379) throws {
		
        self.socket = try ClientSocket(address: address, port: port)
	}
    
    public func command(name: String, params: [String] = []) throws -> RespObject {
        
        //format the outgoing command into a Resp string
        let formatted = try CommandSendFormatter().commandToString(name, params: params)

        //send the command string
        try self.socket.write(formatted)

        //delegate reading to parsers
        let reader: SocketReader = self.socket
        
        //try to parse the string into a Resp object, fail if no parser accepts it
        let (responseObject, _) = try InitialParser().parse([], reader: reader)
        
        //TODO: read up on whether potential leftover characters from
        //parsing should be treated as error or not, for now ignore them.
        
        return responseObject
    }
}

/// Command convenience functions
extension Redbird {
    
}

struct CommandSendFormatter {
    
    func commandToString(command: String, params: [String]) throws -> String {
        
        let comps = ([command] + params).map { BulkString(content: $0) as RespObject }
        let formatted = try ArrayFormatter().format(RespArray(content: comps))
        return formatted
    }
}

