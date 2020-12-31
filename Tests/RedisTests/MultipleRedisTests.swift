import Foundation
import Redis
import Vapor
import Logging
import XCTVapor

class MultipleRedisTests: XCTestCase {
    let one = RedisID(string: "one")
    let two = RedisID(string: "two")

    var redisConfig1: RedisConfiguration!
    var redisConfig2: RedisConfiguration!

    override func setUpWithError() throws {
        try super.setUpWithError()
        redisConfig1 = try RedisConfiguration(url: Environment.get("REDIS_URL_1") ?? "redis://localhost:6379/0")
        redisConfig2 = try RedisConfiguration(url: Environment.get("REDIS_URL_2") ?? "redis://localhost:6380/0")
    }

    func testApplicationRedis() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redises.use(redisConfig1, as: one)
        app.redises.use(redisConfig2, as: two)

        try app.boot()

        let info1 = try app.redis(one).send(command: "INFO").wait()
        XCTAssertContains(info1.string, "redis_version")

        let info2 = try app.redis(two).send(command: "INFO").wait()
        XCTAssertContains(info2.string, "redis_version")
    }

    func testSetAndGet() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redises.use(redisConfig1, as: one)
        app.redises.use(redisConfig2, as: two)

        try app.boot()

        try app.redis(one).set("name", to: "redis1").wait()
        try app.redis(two).set("name", to: "redis2").wait()

        XCTAssertEqual("redis1", try app.redis(one).get("name").wait().string)
        XCTAssertEqual("redis2", try app.redis(two).get("name").wait().string)

        XCTAssertNotEqual("redis1", try app.redis(two).get("name").wait().string)
        XCTAssertNotEqual("redis2", try app.redis(one).get("name").wait().string)
    }
}
