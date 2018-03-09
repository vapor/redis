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
/*
    func testPubSub() throws {
        // Subscribe
        try RedisClient.subscribe(to: ["foo"]) { _, error in
            XCTFail("\(error)")
        }.await(on: eventLoop).drain { data in
            XCTAssertEqual(data.channel, "foo")
            promise.complete(data.data)
        }.catch { error in
            XCTFail("\(error)")
        }.finally {
            // closed
        }

        // Publish
        let publisher = try RedisClient.connect(on: eventLoop) { _, error in
            XCTFail("\(error)")
        }
        let publish = try publisher.publish(.bulkString("it worked"), to: "foo").await(on: eventLoop)
        XCTAssertEqual(publish.int, 1)

        // Verify
        let data = try promise.future.await(on: eventLoop)
        XCTAssertEqual(data.string, "it worked")
    }
*/
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
     //   ("testPubSub", testPubSub),
        ("testStruct", testStruct),
     ]
}
