//
//  FormattingTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class FormattingTests: XCTestCase {

    func testError() {
        
        let obj = Error(content: "WAAAT unknown command 'BLAH'")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "-WAAAT unknown command 'BLAH'\r\n")
    }
    
    func testSimpleString() {
        
        let obj = try! SimpleString(content: "OK")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "+OK\r\n")
    }
    
    func testInteger() {
        
        let obj = try! Integer(content: "1000")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, ":1000\r\n")
    }
    
    func testBulkString_Normal() {
        
        let obj = BulkString(content: "foobar")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "$6foobar\r\n")
    }

    func testBulkString_Empty() {
        
        let obj = BulkString(content: "")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "$0\r\n")
    }
    
    func testBulkString_Null() {
        
        let obj = NullBulkString()
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "$-1\r\n")
    }

    func testInitialFormatter_Integer() {
        
        let obj = try! Integer(content: "1000")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, ":1000\r\n")
    }

}
