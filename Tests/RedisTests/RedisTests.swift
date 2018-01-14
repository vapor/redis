import Async
import Dispatch
@testable import Redis
import TCP
import XCTest

class RedisTests: XCTestCase {
    func testCRUD() throws {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.redis.test.crud")
        let redis = try RedisClient.connect(hostname: "localhost", port: 6379, on: eventLoop)
        let set = try redis.set("world", forKey: "hello").await(on: eventLoop)
        XCTAssertEqual(set.string, "OK")
        let get = try redis.get(forKey: "hello").await(on: eventLoop)
        XCTAssertEqual(get.string, "world")
        let delete = try redis.delete(keys: ["hello"]).await(on: eventLoop)
        XCTAssertEqual(delete.int, 1)
    }

    func testPubSub() throws {
        let eventLoop = try DefaultEventLoop(label: "codes.vapor.redis.test.pubsub")
        let redis = try RedisClient.subscribe(to: ["foo"], hostname: "localhost", port: 6379, on: eventLoop).await(on: eventLoop)

        let promise = Promise(RedisData.self)
        let drain = redis.drain { data, upstream in
            XCTAssertEqual(data.channel, "foo")
            promise.complete(data.data)
        }.catch { error in
            XCTFail("\(error)")
        }.finally {
            // closed
        }
        drain.upstream?.request(count: .max)

        let publisher = try RedisClient.connect(hostname: "localhost", port: 6379, on: eventLoop)
        let res = try publisher.publish(.bulkString("it worked"), to: "foo").await(on: eventLoop)
        XCTAssertEqual(res.int, 1)

        let data = try promise.future.await(on: eventLoop)
        XCTAssertEqual(data.string, "it worked")
    }

    static let allTests = [
        ("testCRUD", testCRUD),
        ("testPubSub", testPubSub),
    ]
}
