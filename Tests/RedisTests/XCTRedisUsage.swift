import Redis
import Vapor
import XCTest
import XCTRedis
import XCTVapor

private extension RedisID {
    static let one: RedisID = "one"
    static let two: RedisID = "two"
}

class XCTRedisUsage: XCTestCase {
    func test_usage_redis_fake_client() throws {
        let app = Application()
        let client = ArrayTestRedisClient()

        defer { app.shutdown() }

        client.prepare(with: .success(.bulkString(.init(string: "redis_version"))))
        client.prepare(with: .success(.bulkString(.init(string: "redis_version"))))

        app.redis(.one).use(.stub(client: client))
        app.redis(.two).use(.stub(client: client))

        try app.boot()

        let info1 = try app.redis(.one).send(command: "INFO").wait()
        XCTAssertContains(info1.string, "redis_version")

        let info2 = try app.redis(.two).send(command: "INFO").wait()
        XCTAssertContains(info2.string, "redis_version")
    }
}
