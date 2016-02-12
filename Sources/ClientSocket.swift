//
//  ClientSocket.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

//Inspired by socket-handling code in https://github.com/kylef/Curassow
//and by the book https://books.google.co.uk/books/about/TCP_IP_Sockets_in_C.html?id=11YK8bbqYkEC&redir_esc=y

#if os(Linux)
    import Glibc
    
    private let sock_stream = Int32(SOCK_STREAM.rawValue)
    
    private let s_connect = Glibc.connect
    private let s_close = Glibc.close
    private let s_read = Glibc.read
    private let s_write = Glibc.write
#else
    import Darwin.C
    
    private let sock_stream = SOCK_STREAM
    
    private let s_connect = Darwin.connect
    private let s_close = Darwin.close
    private let s_read = Darwin.read
    private let s_write = Darwin.write
#endif

class ClientSocket {
    
    typealias Descriptor = Int32
    typealias Port = UInt16
    
    private let descriptor: Descriptor
    
    let address: String
    let port: Int
    
    init(address: String, port: Int) throws {
        
        self.descriptor = socket(AF_INET, sock_stream, Int32(IPPROTO_TCP))
        guard self.descriptor > 0 else { throw SocketError("Failed to create socket") }
        
        self.address = address
        self.port = port
        try self.connect()
    }

    deinit {
        s_close(self.descriptor)
    }
    
    //MARK: Actual functionality
    
    func write(string: String) throws {
        
        let len = Int(strlen(string))
        let written = s_write(self.descriptor, string, len)
        guard written == len else { throw SocketError("Didn't send all bytes") }
    }
    
    func read(bytes: Int = BufferCapacity) throws -> [CChar] {
        let data = Data(capacity: bytes)
        let receivedBytes = s_read(self.descriptor, data.bytes, data.capacity)
        guard receivedBytes > -1 else { throw SocketError("Invalid read") }
        return Array(data.characters[0..<receivedBytes])
    }

    //MARK: Private utils

    private var _address: in_addr {
        return in_addr(s_addr: self.address.withCString { inet_addr($0) })
    }
    
    private var _port: in_port_t {
        return in_port_t(htons(in_port_t(self.port)))
    }
    
    private func connect() throws {
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr = self._address
        addr.sin_port = self._port
        addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        
        let con = s_connect(self.descriptor, sockaddr_cast(&addr), socklen_t(sizeof(sockaddr_in)))
        guard con > -1 else { throw SocketError("Couldn't connect") }
    }
    
    private func sockaddr_cast(p: UnsafeMutablePointer<Void>) -> UnsafeMutablePointer<sockaddr> {
        return UnsafeMutablePointer<sockaddr>(p)
    }
    
    //convert little-endian to big-endian for network transfer
    //aka Host TO Network Short
    private func htons(value: CUnsignedShort) -> CUnsignedShort {
        return (value << 8) + (value >> 8)
    }
}

extension ClientSocket {
    
    func readUntilEnd() throws -> [CChar] {
        
        var totalBuffer = [CChar]()
        
        while true {
            
            let readChars = try self.read()
            
            //append received chars
            totalBuffer.appendContentsOf(readChars)
            
            //if less than max chars were received, finish up
            if readChars.count < BufferCapacity {
                //end of transmission
                return totalBuffer
            }
        }
    }
    
    func readAll() throws -> String {
        let chars = try self.readUntilEnd()
        guard let string = String.fromCString(chars) else {
            throw SocketError("Failed to parse into a string received chars: \(chars)")
        }
        return string
    }
}

//see error codes: https://gist.github.com/gabrielfalcao/4216897
struct SocketError : ErrorType, CustomStringConvertible {
    
    let details: String
    let number: Int32
    
    init(_ details: String) {
        self.details = details
        self.number = errno //last reported error code
    }
    
    var description: String {
        return "Socket failed with code \(number) [\(details)]"
    }
}

private let BufferCapacity = 512

class Data {
    
    let bytes: UnsafeMutablePointer<Int8>
    let capacity: Int

    init(capacity: Int = BufferCapacity) {
        self.bytes = UnsafeMutablePointer<Int8>(malloc(capacity + 1))
        //add null strings terminator at location 'capacity'
        //so that whatever we receive, we always terminate properly when converting to a string?
        //otherwise we might overread and read garbage, potentially opening a security hole.
        self.bytes[capacity] = 0
        self.capacity = capacity
    }

    deinit {
        free(self.bytes)
    }
    
    var characters: [CChar] {
        var data = [CChar](count: self.capacity, repeatedValue: 0)
        memcpy(&data, self.bytes, data.count)
        return data
    }
}

