//
//  RedbirdTests.swift
//  RedbirdTests
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import Redbird

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

func assertNoThrow(block: @noescape () throws -> ()) {
    do {
        try block()
    } catch {
        XCTFail("Should not have thrown \(error)")
    }
}

func assertThrow(_ errorType: @autoclosure () -> RedbirdError, block: @noescape () throws -> ()) {
    do {
        try block()
        XCTFail("Should have thrown an error, but didn't")
    } catch {
        //all good
        XCTAssertEqual(String(errorType()), String(error as! RedbirdError))
    }
}

class RedbirdTests: XCTestCase {
    
    func live(block: @noescape (client: Redbird) throws -> ()) {
        do {
            let client = try Redbird()
            try block(client: client)
        } catch {
            XCTAssert(false, "Failed to create client \(error)")
        }
    }
    
    func liveShouldThrow(block: @noescape (client: Redbird) throws -> ()) {
        do {
            let client = try Redbird()
            try block(client: client)
            XCTFail("Should have thrown")
        } catch {
            //all good
        }
    }
    
    func testServersideKilledSocket_Reconnected() {
        live { (client) in
            
            //kill our connection, simulating e.g. server disconnecting us/crashing
            _ = try client.command("CLIENT", params: ["KILL", "SKIPME", "NO"])
            
            //try to ping, expected to reconnect
            let resp = try client.command("PING")
            XCTAssertEqual(try? resp.toString(), "PONG")
        }
    }
    
    func testServersideTimeout() {
        live { (client) in
            
            //set timeout to 1 sec
            _ = try client.command("CONFIG", params: ["SET", "timeout", "1"])
            sleep(2)
            
            //try to ping, expected to reconnect
            let resp = try client.command("PING")
            XCTAssertEqual(try? resp.toString(), "PONG")
        }
    }
    
    func testSimpleString_Ping() {
        
        live { (client) in
            let response = try client.command("PING")
            XCTAssertEqual(response.respType, RespType.SimpleString)
            XCTAssertEqual(response as? RespSimpleString, try? RespSimpleString(content: "PONG"))
        }
    }
    
    func testError_UnknownCommand() {
        
        live { (client) in
            let response = try client.command("BLAH")
            XCTAssertEqual(response.respType, RespType.Error)
            XCTAssertEqual((response as? RespError)?.kind, "ERR")
        }
    }
    
    func testBulkString_SetGet() {
        
        live { (client) in
            let setResponse = try client.command("SET", params: ["test", "Me_llamo_test"])
            let getResponse = try client.command("GET", params: ["test"])
            
            XCTAssertEqual(setResponse.respType, RespType.SimpleString)
            XCTAssertEqual(setResponse as? RespSimpleString, try? RespSimpleString(content: "OK"))
            XCTAssertEqual(getResponse.respType, RespType.BulkString)
            XCTAssertEqual(getResponse as? RespBulkString, RespBulkString(content: "Me_llamo_test"))
        }
    }
    
    func testPipelining_PingSetGetUnknownPing() {
        live { (client) in
            let pip = client.pipeline()
            let responses = try pip
                .enqueue("PING")
                .enqueue("SET", params: ["test", "Me_llamo_test"])
                .enqueue("GET", params: ["test"])
                .enqueue("BLAH")
                .enqueue("PING")
                .execute()
            XCTAssertEqual(responses.count, 5)
            XCTAssertEqual(try responses[0].toString(), "PONG")
            XCTAssertEqual(try responses[1].toString(), "OK")
            XCTAssertEqual(try responses[2].toString(), "Me_llamo_test")
            XCTAssertEqual(try responses[3].toError().content, "ERR unknown command \'BLAH\'")
            XCTAssertEqual(try responses[4].toString(), "PONG")
        }
    }

    func shouldThrow(block: @noescape () throws -> ()) {
        do {
            try block()
            XCTFail("Should have thrown")
        } catch {
            //all good
        }
    }
    
    func testCommandReconnectFailsOnFailed() {
        
        let socket = DeadSocket()
        let client = Redbird(config: RedbirdConfig(), socket: socket)
        
        //dead socket, fails both times
        shouldThrow {
            _ = try client.command("PING")
        }
    }
    
    func testPipelineReconnectFailsOnFailed() {
        
        let socket = DeadSocket()
        let client = Redbird(config: RedbirdConfig(), socket: socket)
        
        //dead socket, fails both times
        shouldThrow {
            _ = try client.pipeline().enqueue("PING").execute()
        }
    }
    
    func testCommandReconnectSucceedsTheSecondTime() {
        
        let socket = ReconnectableSocket()
        let client = Redbird(config: RedbirdConfig(), socket: socket)
        
        //reconnects
        let resp = try! client.command("PING")
        XCTAssertEqual(try? resp.toString(), "PONG")
    }
    
    func testPipelineReconnectSucceedsTheSecondTime() {
        
        let socket = ReconnectableSocket()
        let client = Redbird(config: RedbirdConfig(), socket: socket)
        
        //reconnects
        let resp = try! client.pipeline().enqueue("PING").execute()
        XCTAssertEqual(try? resp.first!.toString(), "PONG")
    }

    
}

class GoodSocket: Socket {
    
    let testReader: TestReader = TestReader(content: "+PONG\r\n")
    
    func write(string: String) throws {
        //
    }
    
    func close() {}
    
    func read(bytes: Int) throws -> [Byte] {
        return try self.testReader.read(bytes: bytes)
    }
    
    func newWithConfig(config: RedbirdConfig) throws -> Socket {
        return GoodSocket()
    }
}

class DeadSocket: Socket {
    
    func write(string: String) throws {
        //
    }
    
    func close() {}
    
    func read(bytes: Int) throws -> [Byte] {
        return []
    }
    
    func newWithConfig(config: RedbirdConfig) throws -> Socket {
        return DeadSocket()
    }
}

class ReconnectableSocket: Socket {
    
    func write(string: String) throws {
        //
    }
    
    func close() {}
    
    func read(bytes: Int) throws -> [Byte] {
        return []
    }
    
    func newWithConfig(config: RedbirdConfig) throws -> Socket {
        return GoodSocket()
    }
}



