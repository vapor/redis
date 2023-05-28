import Foundation
import Redis
import Vapor
import Logging
import XCTVapor
import XCTest

private extension RedisID {
    static let one: RedisID = "one"
    static let two: RedisID = "two"
}

class MultipleRedisTests: XCTestCase {

    var redisConfig: RedisConfiguration!
    var redisConfig2: RedisConfiguration!

    override func setUpWithError() throws {
        try super.setUpWithError()

        redisConfig = try RedisConfiguration(
            hostname: Environment.get("REDIS_HOSTNAME") ?? "localhost",
            port: Environment.get("REDIS_PORT")?.int ?? 6379,
            pool: .init(connectionRetryTimeout: .milliseconds(100))
        )
        redisConfig2 = try RedisConfiguration(
            hostname: Environment.get("REDIS_HOSTNAME_2") ?? "localhost",
            port: Environment.get("REDIS_PORT_2")?.int ?? 6380,
            pool: .init(connectionRetryTimeout: .milliseconds(100))
        )
    }

    func testApplicationRedis() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis(.one).configuration = redisConfig
        app.redis(.two).configuration = redisConfig2

        try app.boot()

        let info1 = try app.redis(.one).send(command: "INFO").wait()
        XCTAssertContains(info1.string, "redis_version")

        let info2 = try app.redis(.two).send(command: "INFO").wait()
        XCTAssertContains(info2.string, "redis_version")
    }

    func testSetAndGet() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis(.one).configuration = redisConfig
        app.redis(.two).configuration = redisConfig2

        app.get("test1") { req in
            req.redis(.one).get("name").map {
                $0.description
            }
        }
        app.get("test2") { req in
            req.redis(.two).get("name").map {
                $0.description
            }
        }

        try app.boot()

        try app.redis(.one).set("name", to: "redis1").wait()
        try app.redis(.two).set("name", to: "redis2").wait()

        try app.test(.GET, "test1") { res in
            XCTAssertEqual(res.body.string, "redis1")
        }

        try app.test(.GET, "test2") { res in
            XCTAssertEqual(res.body.string, "redis2")
        }

        XCTAssertEqual("redis1", try app.redis(.one).get("name").wait().string)
        XCTAssertEqual("redis2", try app.redis(.two).get("name").wait().string)
    }
}
