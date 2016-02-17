//
//  RedbirdTests.swift
//  RedbirdTests
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

func assertNoThrow(@noescape block: () throws -> ()) {
    do {
        try block()
    } catch {
        XCTFail("Should not have thrown \(error)")
    }
}

func assertThrow(@autoclosure errorType: () -> RedbirdError, @noescape block: () throws -> ()) {
    do {
        try block()
        XCTFail("Should have thrown an error, but didn't")
    } catch {
        //all good
        XCTAssertEqual(String(errorType()), String(error as! RedbirdError))
    }
}

class RedbirdTests: XCTestCase {
    
    func live(@noescape block: (client: Redbird) throws -> ()) {
        do {
            let client = try Redbird()
            try block(client: client)
        } catch {
            XCTAssert(false, "Failed to create client \(error)")
        }
    }
    
    func liveShouldThrow(@noescape block: (client: Redbird) throws -> ()) {
        do {
            let client = try Redbird()
            try block(client: client)
            XCTFail("Should have thrown")
        } catch {
            //all good
        }
    }
    
    func testServersideKilledSocket() {
        liveShouldThrow { (client) in
            
            //kill our connection, simulating e.g. server disconnecting us/crashing
            try client.command("CLIENT", params: ["KILL", "SKIPME", "NO"])
            
            //try to ping, expected to throw
            _ = try client.command("PING")
        }
    }
    
    func testServersideTimeout() {
        liveShouldThrow { (client) in
            
            //set timeout to 1 sec
            try client.command("CONFIG", params: ["SET", "timeout", "1"])
            sleep(2)
            
            //try to ping, expected to throw
            _ = try client.command("PING")
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


    
}
