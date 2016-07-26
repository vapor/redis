//
//  ConversionTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/14/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import Redbird

class ConversionTests: XCTestCase {

    func testArray_Ok() {
        assertNoThrow {
            let orig = RespArray(content: [try RespSimpleString(content: "yo")])
            let ret = try orig.toArray()
            XCTAssertEqual(ret.count, 1)
        }
    }
    
    func testArray_NullThrows() {
        let orig = RespNullArray()
        assertThrow(.wrongNativeTypeUnboxing(orig, "Array")) {
            _ = try orig.toArray()
        }
    }
    
    func testMaybeArray_Ok() {
        assertNoThrow {
            let orig = RespArray(content: [try RespSimpleString(content: "yo")])
            let ret = try orig.toMaybeArray()
            XCTAssertNotNil(ret)
            XCTAssertEqual(ret!.count, 1)
        }
    }
    
    func testMaybeArray_NullOk() {
        let orig = RespNullArray()
        assertNoThrow {
            let ret = try orig.toMaybeArray()
            XCTAssertNil(ret)
        }
    }
    
    func testSimpleString_Ok() {
        assertNoThrow {
            let orig = try RespSimpleString(content: "yo")
            let ret = try orig.toString()
            XCTAssertEqual(ret, "yo")
        }
    }
    
    func testBulkString_Ok() {
        assertNoThrow {
            let orig = RespBulkString(content: "yo")
            let ret = try orig.toString()
            XCTAssertEqual(ret, "yo")
        }
    }

    func testString_NullThrows() {
        let orig = RespNullBulkString()
        assertThrow(.wrongNativeTypeUnboxing(orig, "String")) {
            _ = try orig.toString()
        }
    }
    
    func testMaybeString_Ok() {
        assertNoThrow {
            let orig = RespBulkString(content: "yo")
            let ret = try orig.toMaybeString()
            XCTAssertEqual(ret, "yo")
        }
    }

    func testMaybeString_NullOk() {
        let orig = RespNullBulkString()
        assertNoThrow {
            let ret = try orig.toMaybeString()
            XCTAssertNil(ret)
        }
    }
    
    func testInt_Ok() {
        assertNoThrow {
            let orig = try RespInteger(content: "12")
            let ret = try orig.toInt()
            XCTAssertEqual(ret, 12)
        }
    }

    func testBool_Ok() {
        assertNoThrow {
            let orig = try RespInteger(content: "0")
            let ret = try orig.toBool()
            XCTAssertEqual(ret, false)
        }
    }
    
    func testError_Ok() {
        assertNoThrow {
            let orig = RespError(content: "NOAUTH Password required")
            let ret = try orig.toError()
            XCTAssertEqual(ret.content, "NOAUTH Password required")
        }
    }

}
