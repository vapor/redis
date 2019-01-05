import XCTest
@testable import RedisTests

XCTMain([
    testCase(RedisTests.allTests),
    testCase(RedisDatabaseTests.allTests),
    testCase(RedisDataEncoderTests.allTests),
    testCase(RedisDataDecoderTests.allTests),
    testCase(RedisPipelineTests.allTests)
])
