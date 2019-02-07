import XCTest
@testable import RedisTests

XCTMain([
	testCase(RedisTests.allTests),
    testCase(RedisDataDecoderTests.allTests),
    testCase(RedisDataEncoderTests.allTests),
    testCase(RedisDatabaseTests.allTests),
    testCase(RedisDataConvertibleTests.allTests)
])
