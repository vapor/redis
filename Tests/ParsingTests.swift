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


}
