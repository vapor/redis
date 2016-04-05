//
//  PerformanceTests.swift
//  Redbird
//
//  Created by Honza Dvorsky on 2/24/16.
//  Copyright © 2016 Honza Dvorsky. All rights reserved.
//

import XCTest
@testable import Redbird

//#if os(Linux)
//    extension PerformanceTests: XCTestCaseProvider {
//        var allTests : [(String, () throws -> Void)] {
//            return [
//                ("testPerf_ParsingArray_Normal", testPerf_ParsingArray_Normal),
//                ("testPerf_LargeArray", testPerf_LargeArray)
//            ]
//        }
//    }
//#endif

#if os(Linux)
#else
class PerformanceTests: XCTestCase {

    func urlForFixture(name: String) -> NSURL {

        let parent = (#file).componentsSeparated(by: "/").dropLast().joined(separator: "/")
        let url = NSURL(string: "file://\(parent)/\(name).txt")!
        print("Loading fixture from url \(url)")
        return url
    }
    
    func testPerf_ParsingArray_Normal() {
        
        let strUrl = urlForFixture("teststring")
        let str = try! String(contentsOf: strUrl, encoding: NSUTF8StringEncoding)
        measure {
            let reader = TestReader(content: str)
            let (_, _) = try! InitialParser().parse([], reader: reader)
        }
    }
    
    func testPerf_LargeArray() {
        let subinput: [RespObject] = [
            RespBulkString(content: "large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here, large text right here"),
            try! RespInteger(content: "1234567"),
            RespError(content: "ERR Something went mildly wrong"),
            RespNullArray(),
            try! RespSimpleString(content: "Jokes"),
            RespNullBulkString()
        ]
        let content: [RespObject] = Array(1..<100).map { _ in RespArray(content: subinput) }
        let input = RespArray(content: content)
        measure {
            _ = try! InitialFormatter().format(input)
        }
    }

}
#endif
