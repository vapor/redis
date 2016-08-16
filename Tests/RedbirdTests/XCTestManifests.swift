//
//  XCTestManifests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 3/29/16.
//
//

extension ConversionTests {
    static var allTests : [(String, (ConversionTests) -> () throws -> Void)] {
        return [
            ("testArray_Ok", testArray_Ok),
            ("testArray_NullThrows", testArray_NullThrows),
            ("testMaybeArray_Ok", testMaybeArray_Ok),
            ("testMaybeArray_NullOk", testMaybeArray_NullOk),
            ("testSimpleString_Ok", testSimpleString_Ok),
            ("testBulkString_Ok", testBulkString_Ok),
            ("testString_NullThrows", testString_NullThrows),
            ("testMaybeString_Ok", testMaybeString_Ok),
            ("testMaybeString_NullOk", testMaybeString_NullOk),
            ("testInt_Ok", testInt_Ok),
            ("testBool_Ok", testBool_Ok),
            ("testError_Ok", testError_Ok)
        ]
    }
}

extension FormattingTests {
    static var allTests : [(String, (FormattingTests) -> () throws -> Void)] {
        return [
            ("testInitialFormatter_Integer", testInitialFormatter_Integer),
            ("testError", testError),
            ("testSimpleString", testSimpleString),
            ("testInteger", testInteger),
            ("testBulkString_Normal", testBulkString_Normal),
            ("testBulkString_Empty", testBulkString_Empty),
            ("testBulkString_Null", testBulkString_Null),
            ("testArray_Normal", testArray_Normal),
            ("testArray_Empty", testArray_Empty),
            ("testArray_Null", testArray_Null),
            ("testArray_TwoStrings", testArray_TwoStrings),
            ("testArray_ArrayOfArrays", testArray_ArrayOfArrays)
        ]
    }
}

extension ParsingTests {
    static var allTests : [(String, (ParsingTests) -> () throws -> Void)] {
        return [
            ("testParsingError_NothingReadYet", testParsingError_NothingReadYet),
            ("testParsingError_FirstReadChar", testParsingError_FirstReadChar),
            ("testParsingSimpleString", testParsingSimpleString),
            ("testParsingSimpleString_WithLeftover", testParsingSimpleString_WithLeftover),
            ("testParsingInteger", testParsingInteger),
            ("testParsingBulkString_Normal", testParsingBulkString_Normal),
            ("testParsingBulkString_Normal_WithLeftover", testParsingBulkString_Normal_WithLeftover),
            ("testParsingBulkString_Empty", testParsingBulkString_Empty),
            ("testParsingBulkString_Null", testParsingBulkString_Null),
            ("testParsingArray_Null", testParsingArray_Null),
            ("testParsingArray_Empty", testParsingArray_Empty),
            ("testParsingArray_Normal", testParsingArray_Normal),
            ("testParsingArray_TwoString", testParsingArray_TwoString),
            ("testParsingArray_ArrayOfArrays", testParsingArray_ArrayOfArrays)
        ]
    }
}

extension RedbirdTests {
    static var allTests : [(String, (RedbirdTests) -> () throws -> Void)] {
        return [
            ("testServersideKilledSocket_Reconnected", testServersideKilledSocket_Reconnected),
            ("testServersideTimeout", testServersideTimeout),
            ("testSimpleString_Ping", testSimpleString_Ping),
            ("testError_UnknownCommand", testError_UnknownCommand),
            ("testBulkString_SetGet", testBulkString_SetGet),
            ("testPipelining_PingSetGetUnknownPing", testPipelining_PingSetGetUnknownPing),
            ("testCommandReconnectFailsOnFailed", testCommandReconnectFailsOnFailed),
            ("testPipelineReconnectFailsOnFailed", testPipelineReconnectFailsOnFailed),
            ("testCommandReconnectSucceedsTheSecondTime", testCommandReconnectSucceedsTheSecondTime),
            ("testPipelineReconnectSucceedsTheSecondTime", testPipelineReconnectSucceedsTheSecondTime)
        ]
    }
}

extension StringTests {
    static var allTests : [(String, (StringTests) -> () throws -> Void)] {
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
            ("testByteArrayView", testByteArrayView),
            ("testSplitAround_NotFound", testSplitAround_NotFound),
            ("testSplitAround_Middle", testSplitAround_Middle),
            ("testSplitAround_Start", testSplitAround_Start),
            ("testSplitAround_End", testSplitAround_End)
        ]
    }
}





