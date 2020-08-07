import Redis
import Vapor
import Logging
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
        XCTAssertContains(info.string, "redis_version")
    }

    override class func setUp() {
        XCTAssert(isLoggingConfigured)
    }
}

let isLoggingConfigured: Bool = {
    var env = Environment.testing
    try! LoggingSystem.bootstrap(from: &env)
    return true
}()

func env(_ name: String) -> String? {
    getenv(name).flatMap { String(cString: $0) }
}
