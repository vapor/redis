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

        let obj = try! ErrorParser().parse("-ERR unknown command 'BLAH'\r\n")
        XCTAssertEqual(obj.respType, RespType.Error)
        let err = obj as! Error
        XCTAssertEqual(err.content, "ERR unknown command 'BLAH'")
    }
    
}
