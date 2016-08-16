//
//  FormattingTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import Redbird

class FormattingTests: XCTestCase {

    func testInitialFormatter_Integer() {
        
        let obj = try! RespInteger(content: "1000")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, ":1000\r\n")
    }

    func testError() {
        
        let obj = RespError(content: "WAAAT unknown command 'BLAH'")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "-WAAAT unknown command 'BLAH'\r\n")
    }
    
    func testSimpleString() {
        
        let obj = try! RespSimpleString(content: "OK")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "+OK\r\n")
    }
    
    func testInteger() {
        
        let obj = try! RespInteger(content: "1000")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, ":1000\r\n")
    }
    
    func testBulkString_Normal() {
        
        let obj = RespBulkString(content: "foobar")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "$6\r\nfoobar\r\n")
    }

    func testBulkString_Empty() {
        
        let obj = RespBulkString(content: "")
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "$0\r\n\r\n")
    }
    
    func testBulkString_Null() {
        
        let obj = RespNullBulkString()
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "$-1\r\n")
    }

    func testArray_Normal() {
        
        let input: [RespObject] = [
            try! RespInteger(content: "1"),
            try! RespInteger(content: "205"),
            RespBulkString(content: "foobar"),
            try! RespInteger(content: "0"),
            try! RespInteger(content: "-1")
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
        
        let obj = RespNullArray()
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "*-1\r\n")
    }
    
    func testArray_TwoStrings() {
        
        let input: [RespObject] = [
            RespBulkString(content: "foo"),
            RespBulkString(content: "bar"),
        ]
        let obj = RespArray(content: input)
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n")
    }
    
    func testArray_ArrayOfArrays() {
        
        let input: [RespObject] = [
            RespArray(content: [
                try! RespInteger(content: "1"),
                try! RespInteger(content: "2"),
                try! RespInteger(content: "3"),
                ]),
            RespArray(content: [
                try! RespSimpleString(content: "Foo"),
                RespError(content: "Bar")
                ])
        ]
        let obj = RespArray(content: input)
        let str = try! InitialFormatter().format(obj)
        XCTAssertEqual(str, "*2\r\n*3\r\n:1\r\n:2\r\n:3\r\n*2\r\n+Foo\r\n-Bar\r\n")
    }
}
