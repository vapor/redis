import NIO
import Dispatch
@testable import Redis
import XCTest

extension RedisClient {
    /// Creates a test event loop and Redis client.
    static func makeTest() throws -> RedisClient {
        let group = MultiThreadedEventLoopGroup(numThreads: 1)
        let client = try RedisClient.connect(hostname: "localhost", port: 6379, on: group) { error in
            XCTFail("\(error)")
        }.wait()
        return client
    }
}

class RedisTests: XCTestCase {
    func testCRUD() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        try redis.set("hello", to: "world").wait()
        let get = try redis.get("hello", as: String.self).wait()
        XCTAssertEqual(get, "world")
        try redis.delete("hello").wait()
        XCTAssertNil(try redis.get("hello", as: String.self).wait())
    }

    func testPubSubSingleChannel() throws {
        let redisSubscriber = try RedisClient.makeTest()
        let redisPublisher = try RedisClient.makeTest()
        defer {
            redisPublisher.close()
            redisSubscriber.close()
        }

        let channel1 = "channel1"
        let channel2 = "channel2"

        let expectedChannel1Msg = "Stuff and things"

        var channelReceivedData = false
        _ = try redisSubscriber.subscribe(Set([channel1])) { channelData in
            channelReceivedData = true
            XCTAssert(channelData.data.string == expectedChannel1Msg)
        }.catch { _ in
            XCTFail("this should not throw an error")
        }
        sleep(1)
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
        try redis.jsonSet("hello", to: hello).wait()
        let get = try redis.jsonGet("hello", as: Hello.self).wait()
        XCTAssertEqual(get?.message, "world")
        XCTAssertEqual(get?.array.first, 1)
        XCTAssertEqual(get?.array.last, 3)
        XCTAssertEqual(get?.dict["yes"], true)
        XCTAssertEqual(get?.dict["false"], false)
        try redis.delete("hello").wait()
    }

    func testStringCommands() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }

        let values = ["hello": RedisData(bulk: "world"), "hello2": RedisData(bulk: "world2")]
        try redis.mset(with: values).wait()
        let resp = try redis.mget(["hello", "hello2"]).wait()
        XCTAssertEqual(resp[0].string, "world")
        XCTAssertEqual(resp[1].string, "world2")
        _ = try redis.delete(["hello", "hello2"]).wait()

        let number = try redis.increment("number").wait()
        XCTAssertEqual(number, 1)
        let number2 = try redis.increment("number", by: 10).wait()
        XCTAssertEqual(number2, 11)
        let number3 = try redis.decrement("number", by: 10).wait()
        XCTAssertEqual(number3, 1)
        let number4 = try redis.decrement("number").wait()
        XCTAssertEqual(number4, 0)
        _ = try redis.delete(["number"]).wait()
    }

    func testListCommands() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        _ = try redis.command("FLUSHALL").wait()

        let lpushResp = try redis.lpush([RedisData(bulk: "hello")], into: "mylist").wait()
        XCTAssertEqual(lpushResp, 1)

        let rpushResp = try redis.rpush([RedisData(bulk: "hello1")], into: "mylist").wait()
        XCTAssertEqual(rpushResp, 2)

        let length = try redis.length(of: "mylist").wait()
        XCTAssertEqual(length, 2)

        let item = try redis.lIndex(list: "mylist", index: 0).wait()
        XCTAssertEqual(item.string, "hello")

        let items = try redis.lrange(list: "mylist", range: 0...1).wait()
        XCTAssertEqual(items.array?.count, 2)

        try redis.lSet(RedisData(bulk: "hello2"), at: 0, in: "mylist").wait()
        let item2 = try redis.lIndex(list: "mylist", index: 0).wait()
        XCTAssertEqual(item2.string, "hello2")

        let rpopResp = try redis.rPop("mylist").wait()
        XCTAssertEqual(rpopResp.string, "hello1")

        let rpoplpush = try redis.rpoplpush(source: "mylist", destination: "list2").wait()
        XCTAssertEqual(rpoplpush.string, "hello2")

        _ = try redis.delete(["mylist", "list2"]).wait()
    }

    static let allTests = [
        ("testCRUD", testCRUD),
        ("testPubSubSingleChannel", testPubSubSingleChannel),
        ("testPubSubMultiChannel", testPubSubMultiChannel),
        ("testStruct", testStruct),
        ("testStringCommands", testStringCommands),
        ("testListCommands", testListCommands)
    ]
}
