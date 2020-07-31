import Redis
import Vapor
import XCTVapor

class RedisTests: XCTestCase {
    func testBasic() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis.configuration = try .init(
            hostname: "localhost",
            port: 6379
        )

        let info = try app.redis.send(command: "INFO").wait()
        print(info)
    }
}
