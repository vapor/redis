import Redis
import Vapor
import XCTVapor

class RedisTests: XCTestCase {
    func testBasic() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis.configuration = try .init(
            hostname: env("REDIS_HOSTNAME") ?? "localhost",
            port: 6379
        )

        let info = try app.redis.send(command: "INFO").wait()
        print(info)
    }
}

func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}
