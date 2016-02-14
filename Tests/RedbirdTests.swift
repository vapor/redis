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
    
    func testSimpleString_Ping() {
        
        live { (client) in
            let response = try client.command("PING")
            XCTAssertEqual(response.respType, RespType.SimpleString)
            XCTAssertEqual(response as? SimpleString, try? SimpleString(content: "PONG"))
        }
    }
    
    func testError_UnknownCommand() {
        
        live { (client) in
            let response = try client.command("BLAH")
            XCTAssertEqual(response.respType, RespType.Error)
            XCTAssertEqual((response as? Error)?.kind, "ERR")
        }
    }
    
    func testBulkString_SetGet() {
        
        live { (client) in
            let setResponse = try client.command("SET", params: ["test", "Me_llamo_test"])
            let getResponse = try client.command("GET", params: ["test"])
            
            XCTAssertEqual(setResponse.respType, RespType.SimpleString)
            XCTAssertEqual(setResponse as? SimpleString, try? SimpleString(content: "OK"))
            XCTAssertEqual(getResponse.respType, RespType.BulkString)
            XCTAssertEqual(getResponse as? BulkString, BulkString(content: "Me_llamo_test"))
        }
    }


    
}
