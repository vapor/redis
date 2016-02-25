//
//  StringTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/10/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import Redbird

#if os(Linux)
    extension StringTests: XCTestCaseProvider {
        var allTests : [(String, () throws -> Void)] {
            return [
                ("testStrippingTrailingTerminator", testStrippingTrailingTerminator),
                ("testStrippingSignature", testStrippingSignature),
                ("testStrippingSignatureAndTrailingTerminator", testStrippingSignatureAndTrailingTerminator),
                ("testWrappingTrailingTerminator", testWrappingTrailingTerminator),
                ("testWrappingSignature", testWrappingSignature),
                ("testWrappingSignatureAndTrailingTerminator", testWrappingSignatureAndTrailingTerminator),
                ("testHasPrefix", testHasPrefix),
                ("testHasSuffix", testHasSuffix),
                ("testContainsCharacter", testContainsCharacter),
                ("testCCharArrayView", testCCharArrayView),
                ("testSplitAround_NotFound", testSplitAround_NotFound),
                ("testSplitAround_Middle", testSplitAround_Middle),
                ("testSplitAround_Start", testSplitAround_Start),
                ("testSplitAround_End", testSplitAround_End)
            ]
        }
    }
#endif

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
    
    func testWrappingTrailingTerminator() {
        
        let string = "HELLO world".wrappedTrailingTerminator()
        XCTAssertEqual(string, "HELLO world\r\n")
    }
    
    func testWrappingSignature() {
        
        let string = "HELLO world".wrappedSingleInitialCharacterSignature("+")
        XCTAssertEqual(string, "+HELLO world")
    }
    
    func testWrappingSignatureAndTrailingTerminator() {
        
        let string = "HELLO world".wrappedInitialSignatureAndTrailingTerminator("+")
        XCTAssertEqual(string, "+HELLO world\r\n")
    }
    
    func testHasPrefix() {
        
        let has = "Hello World".hasPrefixStr("Hell")
        XCTAssertTrue(has)
    }
    
    func testHasSuffix() {
        
        let has = "Hello World".hasSuffixStr("rld")
        XCTAssertTrue(has)
    }
    
    func testContainsCharacter() {
        
        let does = "Hello World".containsCharacter("W")
        XCTAssertTrue(does)
    }
    
    func testCCharArrayView() {
        
        let chars = "Yol lo".ccharArrayView()
        let exp = [89, 111, 108, 32, 108, 111].map { CChar($0) }
        XCTAssertEqual(chars, exp)
    }
    
    func testSplitAround_NotFound() {
        
        let split = try! "Hello World".splitAround("Meh")
        XCTAssertEqual(split.0, "Hello World")
        XCTAssertNil(split.1)
    }
    
    func testSplitAround_Middle() {
        
        let split = try! "Hello World".splitAround("Wor")
        XCTAssertEqual(split.0, "Hello Wor")
        XCTAssertEqual(split.1, "ld")
    }
    
    func testSplitAround_Start() {
        
        let split = try! "Hello World".splitAround("H")
        XCTAssertEqual(split.0, "H")
        XCTAssertEqual(split.1, "ello World")
    }
    
    func testSplitAround_End() {
        
        let split = try! "Hello World".splitAround("rld")
        XCTAssertEqual(split.0, "Hello World")
        XCTAssertEqual(split.1, "")
    }

}
