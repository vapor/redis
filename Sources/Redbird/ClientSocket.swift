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
    private let s_alarm = Glibc.alarm
#else
    import Darwin.C
    
    private let sock_stream = SOCK_STREAM
    
    private let s_connect = Darwin.connect
    private let s_close = Darwin.close
    private let s_read = Darwin.read
    private let s_write = Darwin.write
    private let s_alarm = Darwin.alarm
#endif

public enum SocketErrorType {
    case CreateSocketFailed
    case WriteFailedToSendAllBytes
    case ReadFailed
    case ConnectFailed
    case UnparsableChars([CChar])
}

//see error codes: https://gist.github.com/gabrielfalcao/4216897
public struct SocketError : ErrorType, CustomStringConvertible {
    
    public let type: SocketErrorType
    public let number: Int32
    
    init(_ type: SocketErrorType) {
        self.type = type
        self.number = errno //last reported error code
    }
    
    public var description: String {
        return "Socket failed with code \(self.number) [\(self.type)]"
    }
}

class ClientSocket {
    
    typealias Descriptor = Int32
    typealias Port = UInt16
    
    private let descriptor: Descriptor
    
    let address: String
    let port: Int
    
    init(address: String, port: Int) throws {
        
        self.descriptor = socket(AF_INET, sock_stream, Int32(IPPROTO_TCP))
        guard self.descriptor > 0 else { throw SocketError(.CreateSocketFailed) }
        
        self.address = address
        self.port = port
        try self.connect()
    }

    deinit {
        self.disconnect()
    }
    
    //MARK: Actual functionality
    
    func write(string: String) throws {
        
        let len = Int(strlen(string))
        let written = s_write(self.descriptor, string, len)
        guard written == len else { throw SocketError(.WriteFailedToSendAllBytes) }
    }
    
    func read(bytes: Int = BufferCapacity) throws -> [CChar] {
        let data = Data(capacity: bytes)
        let receivedBytes = s_read(self.descriptor, data.bytes, data.capacity)
        guard receivedBytes > -1 else { throw SocketError(.ReadFailed) }
        return Array(data.characters[0..<receivedBytes])
    }

    //MARK: Private utils

    private var _address: in_addr {
        return in_addr(s_addr: self.address.withCString { inet_addr($0) })
    }
    
    private var _port: in_port_t {
        return in_port_t(htons(in_port_t(self.port)))
    }
    
    func connect() throws {
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr = self._address
        addr.sin_port = self._port
        addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        
        let con = s_connect(self.descriptor, sockaddr_cast(&addr), socklen_t(sizeof(sockaddr_in)))
        guard con > -1 else { throw SocketError(.ConnectFailed) }
    }
    
    func disconnect() {
        s_close(self.descriptor)
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

protocol SocketReader: class {
    func read(bytes: Int) throws -> [CChar]
}

extension SocketReader {

    /// Reads until 1) we run out of characters or 2) we detect the delimiter
    /// whichever happens first.
    func readUntilDelimiter(alreadyRead alreadyRead: [CChar], delimiter: String) throws -> ([CChar], [CChar]?) {
        
        var totalBuffer = alreadyRead
        let delimiterChars = delimiter.ccharArrayView()
        var lastReadCount = BufferCapacity
        
        while true {
            
            //test whether the incoming chars contain the delimiter
            let (head, tail) = totalBuffer.splitAround(delimiterChars)
            
            //if we have a tail, we found the delimiter in the buffer,
            //or if there's no more data to read
            //let's terminate and return the current split
            if tail != nil || lastReadCount < BufferCapacity {
                //end of transmission
                return (head, tail)
            }
            
            //read more characters from the reader
            let readChars = try self.read(BufferCapacity)
            lastReadCount = readChars.count
            
            //append received chars before delimiter
            totalBuffer.appendContentsOf(readChars)
        }
    }
}

extension ClientSocket: SocketReader {}

extension CollectionType where Generator.Element == CChar {
    
    func stringView() throws -> String {
        let selfArray = Array(self) + [0]
        guard let string = String.fromCString(selfArray) else {
            throw SocketError(.UnparsableChars(selfArray))
        }
        return string
    }
}

//private let BufferCapacity = 4 //for testing
private let BufferCapacity = 512

class Data {
    
    let bytes: UnsafeMutablePointer<Int8>
    let capacity: Int

    init(capacity: Int = BufferCapacity) {
        self.bytes = UnsafeMutablePointer<Int8>(malloc(capacity + 1))
        //add null strings terminator at location 'capacity'
        //so that whatever we receive, we always terminate properly when converting to a string?
        //otherwise we might overread and read garbage, potentially opening a security hole.
        self.bytes[capacity] = Int8(0)
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

