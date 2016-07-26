//
//  ParsingTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import Redbird

class TestReader: SocketReader {
    
    var content: [Byte]
    
    init(content: String) {
        self.content = content.byteArrayView()
    }
    
    init(bytes: [Byte]) {
        self.content = bytes
    }
    
    func read(bytes: Int) throws -> [Byte] {
        
        precondition(bytes > 0)
        let toReadCount = min(bytes, self.content.count)
        let head = Array(self.content.prefix(toReadCount))
        self.content.removeFirst(toReadCount)
        return head
    }
}

class ParsingTests: XCTestCase {

    func testParsingError_NothingReadYet() {
        
        let reader = TestReader(content: "-WAAAT unknown command 'BLAH'\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Error)
        XCTAssertEqual(leftovers, [])
        let err = obj as! RespError
        XCTAssertEqual(err.content, "WAAAT unknown command 'BLAH'")
        XCTAssertEqual(err.kind, "WAAAT")
        XCTAssertEqual(err.message, "unknown command 'BLAH'")
    }
    
    func testParsingError_FirstReadChar() {
        
        let reader = TestReader(content: "WAAAT unknown command 'BLAH'\r\n")
        let (obj, leftovers) = try! InitialParser().parse("-".byteArrayView(), reader: reader)
        XCTAssertEqual(obj.respType, RespType.Error)
        XCTAssertEqual(leftovers, [])
        let err = obj as! RespError
        XCTAssertEqual(err.content, "WAAAT unknown command 'BLAH'")
        XCTAssertEqual(err.kind, "WAAAT")
        XCTAssertEqual(err.message, "unknown command 'BLAH'")
    }

    func testParsingSimpleString() {
        
        let reader = TestReader(content: "+OK\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.SimpleString)
        XCTAssertEqual(leftovers, [])
        let simpleString = obj as! RespSimpleString
        XCTAssertEqual(simpleString.content, "OK")
    }
    
    /// This test assumes a high buffer size, e.g. 512, so that
    /// reading overshoots to gather all the characters on first non-initial read
    func testParsingSimpleString_WithLeftover() {
        
        let reader = TestReader(content: "+OK\r\nleftover")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.SimpleString)
        XCTAssertEqual(leftovers, "leftover".byteArrayView())
        let simpleString = obj as! RespSimpleString
        XCTAssertEqual(simpleString.content, "OK")
    }

    func testParsingInteger() {
        
        let reader = TestReader(content: ":1000\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Integer)
        XCTAssertEqual(leftovers, [])
        let int = obj as! RespInteger
        XCTAssertEqual(int.intContent, 1000)
        XCTAssertEqual(int.boolContent, true)
    }
    
    func testParsingBulkString_Normal() {
        
        let reader = TestReader(content: "$6\r\nfoobar\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.BulkString)
        XCTAssertEqual(leftovers, [])
        let bulkString = obj as! RespBulkString
        XCTAssertEqual(bulkString.content, "foobar")
    }
    
    func testParsingBulkString_Normal_WithLeftover() {
        
        let reader = TestReader(content: "$6\r\nfoobar\r\nleftover")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.BulkString)
        XCTAssertEqual(leftovers, "leftover".byteArrayView())
        let bulkString = obj as! RespBulkString
        XCTAssertEqual(bulkString.content, "foobar")
    }
    
    func testParsingBulkString_Empty() {
        
        let reader = TestReader(content: "$0\r\n\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.BulkString)
        XCTAssertEqual(leftovers, [])
        let bulkString = obj as! RespBulkString
        XCTAssertEqual(bulkString.content, "")
    }

    func testParsingBulkString_Null() {
        
        let reader = TestReader(content: "$-1\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.NullBulkString)
        XCTAssertEqual(leftovers, [])
        XCTAssertNotNil(obj as? RespNullBulkString)
    }
    
    func testParsingArray_Null() {
        
        let reader = TestReader(content: "*-1\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.NullArray)
        XCTAssertEqual(leftovers, [])
        XCTAssertNotNil(obj as? RespNullArray)
    }
    
    func testParsingArray_Empty() {
        
        let reader = TestReader(content: "*0\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Array)
        XCTAssertEqual(leftovers, [])
        let array = obj as! RespArray
        XCTAssertEqual(array, RespArray(content: []))
    }
    
    func testParsingArray_Normal() {
        
        let reader = TestReader(content: "*5\r\n:1\r\n:205\r\n:0\r\n:-1\r\n$6\r\nfoobar\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Array)
        XCTAssertEqual(leftovers, [])
        let array = obj as! RespArray
        do {
            let expected: [RespObject] = [
                try RespInteger(content: "1"),
                try RespInteger(content: "205"),
                try RespInteger(content: "0"),
                try RespInteger(content: "-1"),
                RespBulkString(content: "foobar")
            ]
            XCTAssertEqual(array, RespArray(content: expected))
        } catch {
            XCTFail("\(error)")
        }
    }
    
    func testParsingArray_TwoString() {
        
        let reader = TestReader(content: "*2\r\n$3\r\nfoo\r\n$3\r\nbar\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Array)
        XCTAssertEqual(leftovers, [])
        let array = obj as! RespArray
        let expected: [RespObject] = [
            RespBulkString(content: "foo"),
            RespBulkString(content: "bar")
        ]
        XCTAssertEqual(array, RespArray(content: expected))
    }

    func testParsingArray_ArrayOfArrays() {
        
        let reader = TestReader(content: "*2\r\n*3\r\n:1\r\n:2\r\n:3\r\n*2\r\n+Foo\r\n-Bar\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Array)
        XCTAssertEqual(leftovers, [])
        let array = obj as! RespArray
        let expected: [RespObject] = [
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
        XCTAssertEqual(array, RespArray(content: expected))
    }
    
}
