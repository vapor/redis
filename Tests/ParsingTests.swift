//
//  ParsingTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class ParsingTests: XCTestCase {

    func testParsingNull() {
        
        let obj = try! NullParser().parse("$-1\r\n")
        XCTAssertEqual(obj.respType, RespType.Null)
    }
    
    func testParsingError() {

        let obj = try! ErrorParser().parse("-WAAAT unknown command 'BLAH'\r\n")
        XCTAssertEqual(obj.respType, RespType.Error)
        let err = obj as! Error
        XCTAssertEqual(err.content, "WAAAT unknown command 'BLAH'")
        XCTAssertEqual(err.kind, "WAAAT")
        XCTAssertEqual(err.message, "unknown command 'BLAH'")
    }
    
    func testParsingSimpleString() {
        
        let obj = try! SimpleStringParser().parse("+OK\r\n")
        XCTAssertEqual(obj.respType, RespType.SimpleString)
        let simpleString = obj as! SimpleString
        XCTAssertEqual(simpleString.content, "OK")
    }

    
}
