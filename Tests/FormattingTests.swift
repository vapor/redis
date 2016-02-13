//
//  FormattingTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class FormattingTests: XCTestCase {

    func testInitialFormatter_Integer() {
        
        let obj = try! Integer(content: "1000")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, ":1000\r\n")
    }

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
        XCTAssertEqual(str, "$6\r\nfoobar\r\n")
    }

    func testBulkString_Empty() {
        
        let obj = BulkString(content: "")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "$0\r\n\r\n")
    }
    
    func testBulkString_Null() {
        
        let obj = NullBulkString()
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "$-1\r\n")
    }

    func testArray_Normal() {
        
        let input: [RespObject] = [
            try! Integer(content: "1"),
            try! Integer(content: "205"),
            BulkString(content: "foobar"),
            try! Integer(content: "0"),
            try! Integer(content: "-1")
        ]
        let obj = RespArray(content: input)
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "*5\r\n:1\r\n:205\r\n$6\r\nfoobar\r\n:0\r\n:-1\r\n")
    }
    
    func testArray_Empty() {
        
        let input: [RespObject] = []
        let obj = RespArray(content: input)
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "*0\r\n")
    }

    func testArray_Null() {
        
        let obj = NullArray()
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "*-1\r\n")
    }
    
    func testArray_TwoStrings() {
        
        let input: [RespObject] = [
            BulkString(content: "foo"),
            BulkString(content: "bar"),
        ]
        let obj = RespArray(content: input)
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n")
    }
    
    func testArray_ArrayOfArrays() {
        
        let input: [RespObject] = [
            RespArray(content: [
                try! Integer(content: "1"),
                try! Integer(content: "2"),
                try! Integer(content: "3"),
                ]),
            RespArray(content: [
                try! SimpleString(content: "Foo"),
                Error(content: "Bar")
                ])
        ]
        let obj = RespArray(content: input)
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "*2\r\n*3\r\n:1\r\n:2\r\n:3\r\n*2\r\n+Foo\r\n-Bar\r\n")
    }

}
