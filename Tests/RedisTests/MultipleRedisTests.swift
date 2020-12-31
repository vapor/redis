import Foundation
import Redis
import Vapor
import Logging
import XCTVapor

class MultipleRedisTests: XCTestCase {
    let one = RedisID(string: "one")
    let two = RedisID(string: "two")

    var redisConfig: RedisConfiguration!
    var redisConfig2: RedisConfiguration!

    override func setUpWithError() throws {
        try super.setUpWithError()

        redisConfig = try RedisConfiguration(hostname: Environment.get("REDIS_HOSTNAME") ?? "localhost",
                                             port: Environment.get("REDIS_PORT")?.int ?? 6379)
        redisConfig2 = try RedisConfiguration(hostname: Environment.get("REDIS_2_HOSTNAME") ?? "localhost",
                                             port: Environment.get("REDIS_2_PORT")?.int ?? 6380)
    }

    func testApplicationRedis() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redises.use(redisConfig, as: one)
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

        app.redises.use(redisConfig, as: one)
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
