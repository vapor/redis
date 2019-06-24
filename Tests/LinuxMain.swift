import XCTest

import RedisTests

var tests = [XCTestCaseEntry]()
tests += RedisTests.__allTests()

XCTMain(tests)
