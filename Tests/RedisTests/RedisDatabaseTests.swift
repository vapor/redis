import NIO
import Dispatch
@testable import Redis
import XCTest

private extension RedisClientConfig {
    static func makeTest() -> RedisClientConfig {
        var config = RedisClientConfig()
        config.password = Environment.get("REDIS_PASSWORD")
        return config
    }
}

class RedisDatabaseTests: XCTestCase {
    let defaultTimeout = 2.0

    func testConnection() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let config = RedisClientConfig.makeTest()
        let database = try RedisDatabase(config: config)
        let redis = try database.newConnection(on: group).wait()
        defer { redis.close() }
        try redis.set("hello", to: "world").wait()
        let get = try redis.get("hello", as: String.self).wait()
        XCTAssertEqual(get, "world")
        try redis.delete("hello").wait()
        XCTAssertNil(try redis.get("hello", as: String.self).wait())
    }

    func testSelect() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let config = RedisClientConfig.makeTest()
        let database = try RedisDatabase(config: config)

        let redis = try database.newConnection(on: group).wait()
        defer { redis.close() }

        _ = try redis.select(2).wait()
        try redis.set("hello", to: "world").wait()
        let get = try redis.get("hello", as: String.self).wait()
        XCTAssertEqual(get, "world")

        _ = try redis.select(0).wait()
        XCTAssertNil(try redis.get("hello", as: String.self).wait())

        _ = try redis.select(2).wait()
        let reget = try redis.get("hello", as: String.self).wait()
        XCTAssertEqual(reget, "world")

        try redis.delete("hello").wait()
        XCTAssertNil(try redis.get("hello", as: String.self).wait())
    }

    func testSelectViaConfig() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        var config = RedisClientConfig.makeTest()
        config.database = 2

        let database = try RedisDatabase(config: config)

        let redis = try database.newConnection(on: group).wait()
        defer { redis.close() }

        try redis.set("hello", to: "world").wait()
        let get = try redis.get("hello", as: String.self).wait()
        XCTAssertEqual(get, "world")

        _ = try redis.select(0).wait()
        XCTAssertNil(try redis.get("hello", as: String.self).wait())

        _ = try redis.select(2).wait()
        let reget = try redis.get("hello", as: String.self).wait()
        XCTAssertEqual(reget, "world")

        try redis.delete("hello").wait()
        XCTAssertNil(try redis.get("hello", as: String.self).wait())
    }

    func testRace() throws {
        let exp = expectation(description: "both futures completed")

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let config = RedisClientConfig.makeTest()

        let database = try RedisDatabase(config: config)
        let redis = try database.newConnection(on: group).wait()

        try redis.set("hello1", to: "foo").wait()
        try redis.set("hello2", to: "bar").wait()

        let future1 = redis.get("hello1", as: String.self)
        let future2 = redis.get("hello2", as: String.self)

        future1.and(future2)
            .do {
                XCTAssertEqual("foo", $0)
                XCTAssertEqual("bar", $1)
                exp.fulfill()
            }
            .catch {
                XCTFail("\($0)")
            }

        waitForExpectations(timeout: 1, handler: nil)
    }

    static let allTests = [
        ("testConnection", testConnection),
        ("testSelect", testSelect),
        ("testSelectViaConfig", testSelectViaConfig),
        ("testRace", testRace),
    ]
}
