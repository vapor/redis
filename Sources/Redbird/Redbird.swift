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
    
    init(socket: ClientSocket) {
        self.socket = socket
    }
    
    func formatCommand(name: String, params: [String] = []) throws -> String {
        
        //make sure nobody passed params in the command name
        //TODO: will become obsolete once we change name to an enum value
        guard name.subwords().count == 1 else {
            throw RedbirdError.MoreThanOneWordSpecifiedAsCommand(name)
        }
        
        //format the outgoing command into a Resp string
        let formatted = try CommandFormatter().commandToString(name, params: params)
        return formatted
    }
    
    public func command(name: String, params: [String] = []) throws -> RespObject {
        
        let formatted = try self.formatCommand(name, params: params)
        
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
    
    public func pipeline() -> Pipeline {
        return Pipeline(socket: self.socket)
    }
}

public class Pipeline: Redbird {
    
    private var commands = [String]()
    
    public func enqueue(name: String, params: [String] = []) throws -> Pipeline {
        let formatted = try self.formatCommand(name, params: params)
        self.commands.append(formatted)
        return self
    }
    
    public func execute() throws -> [RespObject] {
        guard self.commands.count > 0 else {
            throw RedbirdError.PipelineNoCommandProvided
        }
        let formatted = self.commands.reduce("", combine: +)
        
        //send the command string
        try self.socket.write(formatted)
        
        //delegate reading to parsers
        let reader: SocketReader = self.socket

        var leftovers = [CChar]()
        var responses = [RespObject]()
        for _ in self.commands {
            //try to parse the string into a Resp object, fail if no parser accepts it
            let (responseObject, los) = try InitialParser().parse(leftovers, reader: reader)
            leftovers = los
            responses.append(responseObject)
        }
        return responses
    }
}

struct CommandFormatter {
    
    func commandToString(command: String, params: [String]) throws -> String {
        
        let comps = ([command] + params).map { BulkString(content: $0) as RespObject }
        let formatted = try ArrayFormatter().format(RespArray(content: comps))
        return formatted
    }
}

