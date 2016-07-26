//
//  Redbird.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

public struct RedbirdConfig {
    var address: String
    var port: UInt16
    var password: String?
    
    public init(address: String = "127.0.0.1", port: UInt16 = 6379, password: String? = nil) {
        self.address = address
        self.port = port
        self.password = password
    }
}

public typealias Byte = UInt8

///Redis client object
public class Redbird {
    
    private(set) var socket: Socket
    let config: RedbirdConfig

    public var address: String { return self.config.address }
    public var port: UInt16 { return self.config.port }
    
    public init(config: RedbirdConfig = RedbirdConfig()) throws {
		
        self.config = config
        self.socket = try ClientSocket(address: config.address, port: config.port)
        try self.preflight()
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
            throw RedbirdError.moreThanOneWordSpecifiedAsCommand(name)
        }
        
        //format the outgoing command into a Resp string
        let formatted = try CommandFormatter().commandToString(command: name, params: params)
        return formatted
    }
    
    func handleComms(comms: @noescape () throws -> ()) throws {
        //we inspect all thrown errors and try to handle certain ones
        do {
            try comms()
        } catch {
            
            var retry = false
            if case RedbirdError.noDataFromSocket = error {
                retry = true
            }
            if let e = error as? SocketError {
                switch e.type {
                case .sendFailedToSendAllBytes:
                    fallthrough
                case .readFailed:
                    retry = true
                default:
                    break
                }
            }
            
            guard retry else { throw error } //rethrow
            
            //first close the old socket properly
            self.socket.close()
            
            //try to reconnect with a new socket
            self.socket = try self.socket.newWithConfig(config: self.config)
            try self.preflight()
            
            //rerun this command
            try comms()
        }
    }
    
    @discardableResult
    public func command(_ name: String, params: [String] = []) throws -> RespObject {
        
        let formatted = try self.formatCommand(name: name, params: params)
        var ret: RespObject?
        
        try self.handleComms {
            
            //send the command string
            try self.socket.write(string: formatted)
            
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
    
    @discardableResult
    public override func command(_ name: String, params: [String]) throws -> RespObject {
        fatalError("You must call enqueue on a Pipeline instance")
    }
    
    public func enqueue(_ name: String, params: [String] = []) throws -> Pipeline {
        let formatted = try self.formatCommand(name: name, params: params)
        self.commands.append(formatted)
        return self
    }
    
    @discardableResult
    public func execute() throws -> [RespObject] {
        guard self.commands.count > 0 else {
            throw RedbirdError.pipelineNoCommandProvided
        }
        let formatted = self.commands.reduce("", +)
        var ret: [RespObject]?
        
        try self.handleComms {
            
            //send the command string
            try self.socket.write(string: formatted)
            
            //delegate reading to parsers
            let reader: SocketReader = self.socket
            
            var leftovers = [Byte]()
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

