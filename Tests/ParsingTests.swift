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
        let obj = try! ErrorParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Error)
        let err = obj as! Error
        XCTAssertEqual(err.content, "WAAAT unknown command 'BLAH'")
        XCTAssertEqual(err.kind, "WAAAT")
        XCTAssertEqual(err.message, "unknown command 'BLAH'")
    }
    
    func testParsingError_FirstReadChar() {
        
        let reader = TestReader(content: "WAAAT unknown command 'BLAH'\r\n")
        let obj = try! ErrorParser().parse("-".ccharArrayView(), reader: reader)
        XCTAssertEqual(obj.respType, RespType.Error)
        let err = obj as! Error
        XCTAssertEqual(err.content, "WAAAT unknown command 'BLAH'")
        XCTAssertEqual(err.kind, "WAAAT")
        XCTAssertEqual(err.message, "unknown command 'BLAH'")
    }

    func testParsingSimpleString() {
        
        let reader = TestReader(content: "+OK\r\n")
        let obj = try! SimpleStringParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.SimpleString)
        let simpleString = obj as! SimpleString
        XCTAssertEqual(simpleString.content, "OK")
    }

    func testParsingInteger() {
        
        let reader = TestReader(content: ":1000\r\n")
        let obj = try! IntegerParser().parse([], reader: reader)
        XCTAssertEqual(obj.respType, RespType.Integer)
        let int = obj as! Integer
        XCTAssertEqual(int.intContent, 1000)
        XCTAssertEqual(int.boolContent, true)
    }
    
//    func testParsingBulkString() {
//        
//        let obj = try! BulkStringParser().parse("+OK\r\n")
//        XCTAssertEqual(obj.respType, RespType.SimpleString)
//        let simpleString = obj as! SimpleString
//        XCTAssertEqual(simpleString.content, "OK")
//    }
    
    //    func testParsingNull() {
    //
    //        let obj = try! NullParser().parse("$-1\r\n")
    //        XCTAssertEqual(obj.respType, RespType.Null)
    //    }


}
