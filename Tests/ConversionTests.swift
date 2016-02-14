//
//  ConversionTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/14/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class ConversionTests: XCTestCase {

    func testArray_Ok() {
        assertNoThrow {
            let orig = RespArray(content: [try SimpleString(content: "yo")])
            let ret = try orig.toArray()
            XCTAssertEqual(ret.count, 1)
        }
    }
    
    func testArray_NullThrows() {
        let orig = NullArray()
        assertThrow(.WrongNativeTypeUnboxing(orig, "Array")) {
            _ = try orig.toArray()
        }
    }
    
    func testMaybeArray_Ok() {
        assertNoThrow {
            let orig = RespArray(content: [try SimpleString(content: "yo")])
            let ret = try orig.toMaybeArray()
            XCTAssertNotNil(ret)
            XCTAssertEqual(ret!.count, 1)
        }
    }
    
    func testMaybeArray_NullOk() {
        let orig = NullArray()
        assertNoThrow {
            let ret = try orig.toMaybeArray()
            XCTAssertNil(ret)
        }
    }
    
    func testSimpleString_Ok() {
        assertNoThrow {
            let orig = try SimpleString(content: "yo")
            let ret = try orig.toString()
            XCTAssertEqual(ret, "yo")
        }
    }
    
    func testBulkString_Ok() {
        assertNoThrow {
            let orig = BulkString(content: "yo")
            let ret = try orig.toString()
            XCTAssertEqual(ret, "yo")
        }
    }

    func testString_NullThrows() {
        let orig = NullBulkString()
        assertThrow(.WrongNativeTypeUnboxing(orig, "String")) {
            _ = try orig.toString()
        }
    }
    
    func testMaybeString_Ok() {
        assertNoThrow {
            let orig = BulkString(content: "yo")
            let ret = try orig.toMaybeString()
            XCTAssertEqual(ret, "yo")
        }
    }

    func testMaybeString_NullOk() {
        let orig = NullBulkString()
        assertNoThrow {
            let ret = try orig.toMaybeString()
            XCTAssertNil(ret)
        }
    }
    
    func testInt_Ok() {
        assertNoThrow {
            let orig = try Integer(content: "12")
            let ret = try orig.toInt()
            XCTAssertEqual(ret, 12)
        }
    }

    func testBool_Ok() {
        assertNoThrow {
            let orig = try Integer(content: "0")
            let ret = try orig.toBool()
            XCTAssertEqual(ret, false)
        }
    }
    
    func testError_Ok() {
        assertNoThrow {
            let orig = Error(content: "NOAUTH Password required")
            let ret = try orig.toError()
            XCTAssertEqual(ret.content, "NOAUTH Password required")
        }
    }

}
