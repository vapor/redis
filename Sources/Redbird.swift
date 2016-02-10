
///Redis client object
class Redbird {
    
    let socket: ClientSocket
    
    init(address: String = "127.0.0.1", port: Int = 6379) throws {
		
        self.socket = try ClientSocket(address: address, port: port)
	}
    
    func command(name: String) throws -> String {
        
        let formatted = CommandFormatter().commandToString(name)
        try self.socket.write(formatted)
        return try self.socket.readAll()
    }
}

struct CommandFormatter {
    
    private let terminator = "\r\n"
    
    func commandToString(command: String) -> String {
        let out = [
            command,
            terminator
        ].joinWithSeparator("")
        return out
    }
}

