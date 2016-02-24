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
//                ("testPerf_ParsingArray_Normal", testPerf_ParsingArray_Normal)
//            ]
//        }
//    }
//#endif

#if os(Linux)
#else
class PerformanceTests: XCTestCase {

    func urlForFixture(name: String) -> NSURL {
        let url: NSURL
        //if we're running from CLI, use SPM_INSTALL_PATH to find fixtures, otherwise bundle
        if let path = NSProcessInfo().environment["SPM_INSTALL_PATH"] {
            url = NSURL(string: "file://\(path)/../Tests/Redbird/\(name).txt")!
        } else {
            url = NSBundle(forClass: PerformanceTests.classForCoder()).URLForResource(name, withExtension: "txt")!
        }
        print("Loading fixture from url \(url)")
        return url
    }
    
    func testPerf_ParsingArray_Normal() {
        
        let strUrl = urlForFixture("teststring")
        let str = try! String(contentsOfURL: strUrl)
        measureBlock {
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
        measureBlock {
            _ = try! InitialFormatter().format(input)
        }
    }

}
#endif
