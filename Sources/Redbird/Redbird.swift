//
//  Redbird.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct RedbirdConfig {
    var address: String
    var port: Int
    var password: String?
    
    public init(address: String = "127.0.0.1", port: Int = 6379, password: String? = nil) {
        self.address = address
        self.port = port
        self.password = password
    }
}

///Redis client object
public class Redbird {
    
    private(set) var socket: Socket
    let config: RedbirdConfig

    public var address: String { return self.config.address }
    public var port: Int { return self.config.port }
    
    public init(config: RedbirdConfig = RedbirdConfig()) throws {
		
        self.config = config
        self.socket = try Redbird.createSocket(ClientSocket.self, config: config)
        try self.preflight()
	}
    
    private static func createSocket(socketType: Socket.Type, config: RedbirdConfig) throws -> Socket {
        
        let socket: Socket
        do {
            socket = try socketType.newWithConfig(config)
        } catch {
            throw RedbirdError.FailedToCreateSocket(error)
        }
        return socket
    }
    
    private func preflight() throws {
        try self.authIfNeeded()
    }
    
    private func authIfNeeded() throws {
        //if we have a password, immediately try to authenticate
        if let password = self.config.password {
            try self.auth(password: password)
        }
    }
    
    init(config: RedbirdConfig, socket: Socket) {
        self.config = config
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
    
    func handleComms(@noescape comms: () throws -> ()) throws {
        //we inspect all thrown errors and try to handle certain ones
        do {
            try comms()
        } catch RedbirdError.NoDataFromSocket {
            
            //try to reconnect with a new socket
            self.socket = try Redbird.createSocket(self.socket.dynamicType, config: self.config)
            try self.preflight()
            
            //rerun this command
            try comms()
        }
    }
    
    public func command(name: String, params: [String] = []) throws -> RespObject {
        
        let formatted = try self.formatCommand(name, params: params)
        var ret: RespObject?
        
        try self.handleComms {
            
            //send the command string
            try self.socket.write(formatted)
            
            //delegate reading to parsers
            let reader: SocketReader = self.socket
            
            //try to parse the string into a Resp object, fail if no parser accepts it
            let (responseObject, _) = try InitialParser().parse([], reader: reader)
            
            //TODO: read up on whether potential leftover characters from
            //parsing should be treated as error or not, for now ignore them.
            ret = responseObject
        }
        return ret!
    }
    
    public func pipeline() -> Pipeline {
        return Pipeline(config: self.config, socket: self.socket)
    }
}

public class Pipeline: Redbird {
    
    private var commands = [String]()
    
    public override func command(name: String, params: [String]) throws -> RespObject {
        fatalError("You must call enqueue on a Pipeline instance")
    }
    
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
        var ret: [RespObject]?
        
        try self.handleComms {
            
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
            ret = responses
        }
        return ret!
    }
}

struct CommandFormatter {
    
    func commandToString(command: String, params: [String]) throws -> String {
        
        let comps = ([command] + params).map { RespBulkString(content: $0) as RespObject }
        let formatted = try ArrayFormatter().format(RespArray(content: comps))
        return formatted
    }
}

