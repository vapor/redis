import NIO
import Dispatch
@testable import Redis
import XCTest

extension RedisClient {
    /// Creates a test event loop and Redis client.
    static func makeTest() throws -> RedisClient {
        let group = MultiThreadedEventLoopGroup(numThreads: 1)
        let client = try RedisClient.connect(on: group) { error in
            XCTFail("\(error)")
        }.wait()
        return client
    }
}

class RedisTests: XCTestCase {
    func testCRUD() throws {
        let redis = try RedisClient.makeTest()
        _ = try redis.set("world", forKey: "hello")
        let get = try redis.get(String.self, forKey: "hello").wait()
        XCTAssertEqual(get, "world")
        _ = try redis.remove("hello")
        XCTAssertNil(try redis.get(String.self, forKey: "hello").wait())
        redis.close()
    }

    func testPubSubSingleChannel() throws {
        let redisSubscriber = try RedisClient.makeTest()
        let redisPublisher = try RedisClient.makeTest()
        defer {
            redisPublisher.close()
            redisSubscriber.close()
        }

        let channel1 = "channel/1"
        let channel2 = "channel/2"

        let expectedChannel1Msg = "Stuff and things"

        var channelReceivedData = false
        _ = try redisSubscriber.subscribe(Set([channel1])) { channelData in
            channelReceivedData = true
            XCTAssert(channelData.data.string == expectedChannel1Msg)
        }.catch { _ in
            XCTFail("this should not throw an error")
        }
        _ = try redisPublisher.publish("Stuff and things", to: channel1).wait()
        _ = try redisPublisher.publish("Stuff and things 3", to: channel2).wait()
        sleep(1)
        XCTAssert(channelReceivedData)
    }

    func testPubSubMultiChannel() throws {
        let redisSubscriber = try RedisClient.makeTest()
        let redisPublisher = try RedisClient.makeTest()
        defer {
            redisPublisher.close()
            redisSubscriber.close()
        }

        let channel1 = "channel/1"
        let channel2 = "channel/2"

        let expectedChannel1Msg = "Stuff and things"
        let expectedChannel2Msg = "Stuff and things 3"

        var channelReceivedData = false
        _ = try redisSubscriber.subscribe(Set([channel1, channel2])) { channelData in
            channelReceivedData = true
            XCTAssert(channelData.data.string == expectedChannel1Msg ||
                channelData.data.string == expectedChannel2Msg)
        }.catch { _ in
            XCTFail("this should not throw an error")
        }
        _ = try redisPublisher.publish("Stuff and things", to: channel1).wait()
        _ = try redisPublisher.publish("Stuff and things 3", to: channel2).wait()
        sleep(1)
        XCTAssert(channelReceivedData)
    }

    func testStruct() throws {
        struct Hello: Codable {
            var message: String
            var array: [Int]
            var dict: [String: Bool]
        }
        let hello = Hello(message: "world", array: [1, 2, 3], dict: ["yes": true, "false": false])
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        try redis.set(hello, forKey: "hello").wait()
        let get = try redis.get(Hello.self, forKey: "hello").wait()
        XCTAssertEqual(get?.message, "world")
        XCTAssertEqual(get?.array.first, 1)
        XCTAssertEqual(get?.array.last, 3)
        XCTAssertEqual(get?.dict["yes"], true)
        XCTAssertEqual(get?.dict["false"], false)
        try redis.remove("hello").wait()
    }

    static let allTests = [
        ("testCRUD", testCRUD),
        ("testPubSubSingleChannel", testPubSubSingleChannel),
        ("testPubSubMultiChannel", testPubSubMultiChannel),
        ("testStruct", testStruct)
    ]
}
