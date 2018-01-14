import Async
import Dispatch
@testable import Redis
import TCP
import XCTest

class RedisTests: XCTestCase {
    func testCRUD() throws {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.redis.test.crud")
        let redis = try RedisClient.connect(on: eventLoop)
        let set = try redis.set("world", forKey: "hello").await(on: eventLoop)
        XCTAssertEqual(set.string, "OK")
        let get = try redis.get(forKey: "hello").await(on: eventLoop)
        XCTAssertEqual(get.string, "world")
        let delete = try redis.delete(keys: ["hello"]).await(on: eventLoop)
        XCTAssertEqual(delete.int, 1)
    }

    func testPubSub() throws {
        // Setup
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.redis.test.pubsub")
        let promise = Promise(RedisData.self)

        // Subscribe
        try RedisClient.subscribe(to: ["foo"], on: eventLoop).await(on: eventLoop).drain { data, upstream in
            XCTAssertEqual(data.channel, "foo")
            promise.complete(data.data)
        }.catch { error in
            XCTFail("\(error)")
        }.upstream?.request(count: .max)

        // Publish
        let publisher = try RedisClient.connect(on: eventLoop)
        let publish = try publisher.publish(.bulkString("it worked"), to: "foo").await(on: eventLoop)
        XCTAssertEqual(publish.int, 1)

        // Verify
        let data = try promise.future.await(on: eventLoop)
        XCTAssertEqual(data.string, "it worked")
    }

    static let allTests = [
        ("testCRUD", testCRUD),
        ("testPubSub", testPubSub),
    ]
}
