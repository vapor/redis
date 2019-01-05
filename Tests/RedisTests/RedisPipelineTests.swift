import Dispatch
import NIO
@testable import Redis
import XCTest

private extension RedisClientConfig {
    static func makeTest() -> RedisClientConfig {
        var config = RedisClientConfig()
        config.password = Environment.get("REDIS_PASSWORD")
        return config
    }
}

internal class RedisPipelineTests: XCTestCase {
    var connection: RedisClient!

    override func setUp() {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let config = RedisClientConfig.makeTest()

        guard
            let database = try? RedisDatabase(config: config),
            let conn = try? database.newConnection(on: group).wait()
        else {
            return XCTFail("Failed to properly setup Redis connection!")
        }

        connection = conn
    }

    override func tearDown() {
        _ = try? connection?.command("FLUSHALL").wait()
        connection?.close()
    }

    func testEnqueue() {
        let pipeline = connection.makePipeline()

        XCTAssertNoThrow(try pipeline.enqueue(command: "PING"))
        XCTAssertNoThrow(try pipeline.enqueue(command: "SET", arguments: ["KEY", "VALUE"]))
    }

    func testExecuteFails() throws {
        let pipeline = try connection.makePipeline()
            .enqueue(command: "GET")

        XCTAssertThrowsError(try pipeline.execute().wait())
    }

    func testExecuteSucceeds() throws {
        let results = try connection.makePipeline()
            .enqueue(command: "SET", arguments: ["key", "value"])
            .execute().wait()

        XCTAssertEqual(results.count, 1)
    }

    func testExecuteIsOrdered() throws {
        let results = try connection.makePipeline()
            .enqueue(command: "SET", arguments: ["key", 1])
            .enqueue(command: "INCR", arguments: ["key"])
            .enqueue(command: "DECR", arguments: ["key"])
            .enqueue(command: "INCRBY", arguments: ["key", 15])
            .execute().wait()

        XCTAssertEqual(results[0].string, "OK")
        XCTAssertEqual(results[1].int, 2)
        XCTAssertEqual(results[2].int, 1)
        XCTAssertEqual(results[3].int, 16)
    }

    static let allTests = [
        ("testEnqueue", testEnqueue),
        ("testExecuteFails", testExecuteFails),
        ("testExecuteSucceeds", testExecuteSucceeds),
        ("testExecuteIsOrdered", testExecuteIsOrdered),
    ]
}
