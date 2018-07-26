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

    static let allTests = [
        ("testConnection", testConnection),
        ("testSelect", testSelect),
        ("testSelectViaConfig", testSelectViaConfig),
    ]
}
