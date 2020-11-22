import Redis
import Vapor
import Logging
import XCTVapor

class RedisTests: XCTestCase {
    func testApplicationRedis() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis.configuration = try .init(
            hostname: env("REDIS_HOSTNAME") ?? "localhost",
            port: 6379
        )

        let info = try app.redis.send(command: "INFO").wait()
        XCTAssertContains(info.string, "redis_version")
    }

    func testRouteHandlerRedis() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis.configuration = try .init(
            hostname: env("REDIS_HOSTNAME") ?? "localhost",
            port: 6379
        )

        app.get("test") { req in
            req.redis.send(command: "INFO").map {
                $0.description
            }
        }

        try app.test(.GET, "test") { res in
            XCTAssertContains(res.body.string, "redis_version")
        }
    }
    
    func testInitConfigurationURL() throws {
        let app = Application()
        defer { app.shutdown() }

        let urlStr = URL(string: "redis://name:password@localhost:6379/0")
        
        let redisConfigurations = try RedisConfiguration(url: urlStr!)
        
        XCTAssertEqual(redisConfigurations.password, "password")
        XCTAssertEqual(redisConfigurations.database, 0)
    }
    
    func testCodable() throws {
        let app = Application()
        defer { app.shutdown() }
        app.redis.configuration = try .init(
            hostname: env("REDIS_HOSTNAME") ?? "localhost",
            port: 6379
        )

        struct Hello: Codable {
            var message: String
            var array: [Int]
            var dict: [String: Bool]
        }
        
        let hello = Hello(message: "world", array: [1, 2, 3], dict: ["yes": true, "false": false])
        try app.redis.set("hello", toJSON: hello).wait()
        
        let get = try app.redis.get("hello", asJSON: Hello.self).wait()
        XCTAssertEqual(get?.message, "world")
        XCTAssertEqual(get?.array.first, 1)
        XCTAssertEqual(get?.array.last, 3)
        XCTAssertEqual(get?.dict["yes"], true)
        XCTAssertEqual(get?.dict["false"], false)

        let _ = try app.redis.delete(["hello"]).wait()
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
