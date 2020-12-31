import Foundation
import Redis
import Vapor
import Logging
import XCTVapor

class MultipleRedisTests: XCTestCase {
    let one = RedisID(string: "one")
    let two = RedisID(string: "two")

    var redis1Config: RedisConfiguration!
    var redis2Config: RedisConfiguration!

    override func setUpWithError() throws {
        try super.setUpWithError()
        redis1Config = try RedisConfiguration(hostname: env("REDIS_HOSTNAME") ?? "localhost", port: 6379)
        redis2Config = try RedisConfiguration(hostname: env("REDIS_HOSTNAME_2") ?? "localhost", port: 6380)
    }

    func testApplicationRedis() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redisConfigurations = [
            one: redis1Config,
            two: redis2Config
        ]

        let info1 = try app.redis(one).send(command: "INFO").wait()
        XCTAssertContains(info1.string, "redis_version")

        let info2 = try app.redis(two).send(command: "INFO").wait()
        XCTAssertContains(info2.string, "redis_version")
    }

    func testSetAndGet() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redisConfigurations = [
            one: redis1Config,
            two: redis2Config
        ]

        try app.redis(one).set("name", to: "redis1").wait()
        try app.redis(two).set("name", to: "redis2").wait()
        XCTAssertEqual("redis1", try app.redis(one).get("name").wait().string)
        XCTAssertNotEqual("redis1", try app.redis(two).get("name").wait().string)
        XCTAssertNotEqual("redis2", try app.redis(one).get("name").wait().string)
        XCTAssertEqual("redis2", try app.redis(two).get("name").wait().string)
    }
}
