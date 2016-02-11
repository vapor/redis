//
//  StringTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest

class StringTests: XCTestCase {

    func testStrippingTrailingTerminator() {
        
        let string = "HELLO world\r\n".strippedTrailingTerminator()
        XCTAssertEqual(string, "HELLO world")
    }
    
    func testStrippingSignature() {
        
        let string = "+HELLO world".strippedSingleInitialCharacterSignature()
        XCTAssertEqual(string, "HELLO world")
    }

    func testStrippingSignatureAndTrailingTerminator() {
        
        let string = "+HELLO world\r\n".strippedInitialSignatureAndTrailingTerminator()
        XCTAssertEqual(string, "HELLO world")
    }
    
    func testHasPrefix() {
        
        let has = "Hello World".hasPrefix("Hell")
        XCTAssertTrue(has)
    }
    
    func testHasSuffix() {
        
        let has = "Hello World".hasSuffix("rld")
        XCTAssertTrue(has)
    }
    
    func testContainsCharacter() {
        
        let does = "Hello World".containsCharacter("W")
        XCTAssertTrue(does)
    }




}
