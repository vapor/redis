import Redis
import Vapor
import Logging
import XCTVapor
@preconcurrency import RediStack
import XCTest

extension String {
    var int: Int? { Int(self) }
}

final class RedisTests: XCTestCase {
    var redisConfig: RedisConfiguration!

    override class func setUp() {
        XCTAssert(isLoggingConfigured)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        redisConfig = try RedisConfiguration(
            hostname: Environment.get("REDIS_HOSTNAME") ?? "localhost",
            port: Environment.get("REDIS_PORT")?.int ?? 6379,
            pool: .init(connectionRetryTimeout: .milliseconds(100))
        )
    }
}

// MARK: Core RediStack integration
extension RedisTests {
    func testApplicationRedis() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis.configuration = redisConfig
        try app.boot()

        let info = try app.redis.send(command: "INFO").wait()
        XCTAssertContains(info.string, "redis_version")
    }

    func testRouteHandlerRedis() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis.configuration = redisConfig

        app.get("test") { req in
            req.redis.send(command: "INFO").map {
                $0.description
            }
        }

        try app.test(.GET, "test") { res in
            XCTAssertContains(res.body.string, "redis_version")
        }
    }
}

// MARK: Configuration Validation

extension RedisTests {
    func testInitConfigurationURL() throws {
        let urlStr = URL(string: "redis://name:password@localhost:6379/0")
        
        let redisConfiguration = try RedisConfiguration(url: urlStr!)
        
        XCTAssertEqual(redisConfiguration.password, "password")
        XCTAssertEqual(redisConfiguration.database, 0)
    }
}

// MARK: Redis extensions
extension RedisTests {
    func testCodable() throws {
        let app = Application()
        defer { app.shutdown() }
        app.redis.configuration = redisConfig
        try app.boot()

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

    func testRequestConnectionLeasing() throws {
        let app = Application()
        defer { app.shutdown() }
        app.redis.configuration = self.redisConfig

        app.get("test") {
            $0.redis
                .withBorrowedClient { client in
                    return client.send(command: "MULTI")
                        .flatMap { _ in client.send(command: "PING") }
                        .flatMap { queuedResponse -> EventLoopFuture<RESPValue> in
                            XCTAssertEqual(queuedResponse.string, "QUEUED")
                            return client.send(command: "EXEC")
                        }
                }
                .map { result -> [String] in
                    guard let response = result.array else { return [] }
                    return response.compactMap(String.init(fromRESP:))
                }
        }

        try app.test(.GET, "test") {
            XCTAssertEqual($0.body.string, #"["PONG"]"#)
        }
    }

    func testApplicationConnectionLeasing() throws {
        let app = Application()
        defer { app.shutdown() }

        app.redis.configuration = self.redisConfig
        try app.boot()

        let result = try app.redis
            .withBorrowedConnection { client in
                return client.send(command: "MULTI")
                  .flatMap { _ in client.send(command: "PING") }
                  .flatMap { queuedResponse -> EventLoopFuture<RESPValue> in
                      XCTAssertEqual(queuedResponse.string, "QUEUED")
                      return client.send(command: "EXEC")
                  }
            }
            .map { result -> [String] in
                guard let response = result.array else { return [] }
                return response.compactMap(String.init(fromRESP:))
            }
            .wait()

        XCTAssertEqual(result, ["PONG"])
    }
}

// MARK: Vapor integration
extension RedisTests {
    func testSessions() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        app.redis.configuration = redisConfig

        // Configure sessions.
        app.sessions.use(.redis)
        app.middleware.use(app.sessions.middleware)

        // Setup routes.
        app.get("set", ":value") { req -> HTTPStatus in
            req.session.data["name"] = req.parameters.get("value")
            return .ok
        }
        app.get("get") { req -> String in
            req.session.data["name"] ?? "n/a"
        }
        app.get("del") { req -> HTTPStatus in
            req.session.destroy()
            return .ok
        }

        // Store session id.
        var sessionID: String?
        try app.test(.GET, "/set/vapor") { res in
            sessionID = res.headers.setCookie?["vapor-session"]?.string
            XCTAssertEqual(res.status, .ok)
        }
        XCTAssertFalse(try XCTUnwrap(sessionID).contains("vrs-"), "session token has the redis key prefix!")

        try app.test(.GET, "/get", beforeRequest: { req in
            var cookies = HTTPCookies()
            cookies["vapor-session"] = .init(string: sessionID!)
            req.headers.cookie = cookies
        }) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "vapor")
        }
    }
    
    func testCache() throws {
        let app = Application()
        defer { app.shutdown() }
        
        app.redis.configuration = redisConfig
        app.caches.use(.redis)
        try app.boot()

        XCTAssertNoThrow(try app.redis.send(command: "DEL", with: [.init(from: "foo")]).wait())
        try XCTAssertNil(app.cache.get("foo", as: String.self).wait())
        try app.cache.set("foo", to: "bar").wait()
        try XCTAssertEqual(app.cache.get("foo", as: String.self).wait(), "bar")
        
        // Test expiration
        try app.cache.set("foo2", to: "bar2", expiresIn: .seconds(1)).wait()
        try XCTAssertEqual(app.cache.get("foo2", as: String.self).wait(), "bar2")
        sleep(1)
        try XCTAssertNil(app.cache.get("foo2", as: String.self).wait())
    }
    
    func testCacheCustomCoders() throws {
        let app = Application()
        defer { app.shutdown() }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        app.redis.configuration = redisConfig
        app.caches.use(.redis(encoder: encoder, decoder: decoder))
        try app.boot()
        
        let date = Date(timeIntervalSince1970: 10_000_000_000)
        let isoDate = ISO8601DateFormatter().string(from: date)
        
        try app.cache.set("test", to: date).wait()
        let rawValue = try XCTUnwrap(app.redis.get("test", as: String.self).wait())
        XCTAssertEqual(rawValue, #""\#(isoDate)""#)
        let value = try XCTUnwrap(app.cache.get("test", as: Date.self).wait())
        XCTAssertEqual(value, date)
    }
}

// MARK: Test Helpers

let isLoggingConfigured: Bool = {
    var env = Environment.testing
    try! LoggingSystem.bootstrap(from: &env)
    return true
}()
