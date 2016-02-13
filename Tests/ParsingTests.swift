//
//  ParsingTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class TestReader: SocketReader {
    
    var content: [CChar]
    
    init(content: String) {
        self.content = content.ccharArrayView()
    }
    
    func read(bytes: Int) throws -> [CChar] {
        
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
        let err = obj as! Error
        XCTAssertEqual(err.content, "WAAAT unknown command 'BLAH'")
        XCTAssertEqual(err.kind, "WAAAT")
        XCTAssertEqual(err.message, "unknown command 'BLAH'")
    }
    
    func testParsingError_FirstReadChar() {
        
        let reader = TestReader(content: "WAAAT unknown command 'BLAH'\r\n")
        let (obj, leftovers) = try! InitialParser().parse("-".ccharArrayView(), reader: reader)
        XCTAssertEqual(obj.respType, RespType.Error)
        XCTAssertEqual(leftovers, [])
        let err = obj as! Error
        XCTAssertEqual(err.content, "WAAAT unknown command 'BLAH'")
        XCTAssertEqual(err.kind, "WAAAT")
        XCTAssertEqual(err.message, "unknown command 'BLAH'")
    }

    func testParsingSimpleString() {
        
        let reader = TestReader(content: "+OK\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.SimpleString)
        XCTAssertEqual(leftovers, [])
        let simpleString = obj as! SimpleString
        XCTAssertEqual(simpleString.content, "OK")
    }
    
    /// This test assumes a high buffer size, e.g. 512, so that
    /// reading overshoots to gather all the characters on first non-initial read
    func testParsingSimpleString_WithLeftover() {
        
        let reader = TestReader(content: "+OK\r\nleftover")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.SimpleString)
        XCTAssertEqual(leftovers, "leftover".ccharArrayView())
        let simpleString = obj as! SimpleString
        XCTAssertEqual(simpleString.content, "OK")
    }

    func testParsingInteger() {
        
        let reader = TestReader(content: ":1000\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Integer)
        XCTAssertEqual(leftovers, [])
        let int = obj as! Integer
        XCTAssertEqual(int.intContent, 1000)
        XCTAssertEqual(int.boolContent, true)
    }
    
    func testParsingBulkString_Normal() {
        
        let reader = TestReader(content: "$6\r\nfoobar\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.BulkString)
        XCTAssertEqual(leftovers, [])
        let bulkString = obj as! BulkString
        XCTAssertEqual(bulkString.content, "foobar")
    }
    
    func testParsingBulkString_Normal_WithLeftover() {
        
        let reader = TestReader(content: "$6\r\nfoobar\r\nleftover")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.BulkString)
        XCTAssertEqual(leftovers, "leftover".ccharArrayView())
        let bulkString = obj as! BulkString
        XCTAssertEqual(bulkString.content, "foobar")
    }
    
    func testParsingBulkString_Empty() {
        
        let reader = TestReader(content: "$0\r\n\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.BulkString)
        XCTAssertEqual(leftovers, [])
        let bulkString = obj as! BulkString
        XCTAssertEqual(bulkString.content, "")
    }

    func testParsingBulkString_Null() {
        
        let reader = TestReader(content: "$-1\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.NullBulkString)
        XCTAssertEqual(leftovers, [])
        XCTAssertNotNil(obj as? NullBulkString)
    }
    
    func testParsingArray_Null() {
        
        let reader = TestReader(content: "*-1\r\n")
        let (obj, leftovers) = try! InitialParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.NullArray)
        XCTAssertEqual(leftovers, [])
        XCTAssertNotNil(obj as? NullArray)
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
                try Integer(content: "1"),
                try Integer(content: "205"),
                try Integer(content: "0"),
                try Integer(content: "-1"),
                BulkString(content: "foobar")
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
            BulkString(content: "foo"),
            BulkString(content: "bar")
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
                try! Integer(content: "1"),
                try! Integer(content: "2"),
                try! Integer(content: "3"),
                ]),
            RespArray(content: [
                try! SimpleString(content: "Foo"),
                Error(content: "Bar")
                ])
        ]
        XCTAssertEqual(array, RespArray(content: expected))
    }
    
}
