//
//  FormattingTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/11/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class FormattingTests: XCTestCase {

    func testNull() {
        
        let obj = Null()
        let str = try! NullFormatter().format(obj)
        XCTAssertEqual(str, "$-1\r\n")
    }
}
