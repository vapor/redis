import XCTest
@testable import Redis
import Random
import Dispatch

class LiveTests: XCTestCase {
    func testPing() throws {
        let client = try TCPClient()
        let res = try client.command(.ping)
        XCTAssertEqual(res?.string, "PONG")
    }

    func testKeys() throws {
        let client = try TCPClient()
        try client.command(.flushall)
        try client.command(.set, ["FOO", "BAR"])
        try client.command(.set, ["BAR", "BAZ"])

        let res = try client.command(.keys, ["*"])

        XCTAssertEqual(res!.array!.flatMap { $0?.string }, ["FOO", "BAR"])
    }

    func testString() throws {
        let client = try TCPClient()
        do {
            let res = try client.command(.set, ["FOO", "BAR"])
            XCTAssertEqual(res?.string, "OK")
        }
        do {
            let res = try client.command(.get, ["FOO"])
            XCTAssertEqual(res?.string, "BAR")
        }
    }

    func testData() throws {
        let client = try TCPClient()
        let random = try OSRandom.bytes(count: 65_536)
        do {
            let res = try client.command(.set, ["FOO".makeBytes(), random])
            XCTAssertEqual(res?.string, "OK")
        }
        do {
            let res = try client.command(.get, ["FOO"])
            XCTAssert(res!.bytes! == random)
        }
    }

    func testHash() throws {
        let client = try TCPClient()
        try client.command(.flushall)
        do {
            let res = try client.command(.hset, ["BAZ", "BAR", "FOO"])
            XCTAssertEqual(res?.int, 1)
        }
        do {
            let res = try client.command(.hget, ["BAZ", "BAR"])
            XCTAssertEqual(res?.string, "FOO")
        }
        do {
            let res = try client.command(.hset, ["BAZ", "BAR", "BAR"])
            XCTAssertEqual(res?.int, 0)
        }
        do {
            let res = try client.command(.hget, ["BAZ", "BAR"])
            XCTAssertEqual(res?.string, "BAR")
        }
        do {
            let res = try client.command(.hkeys, ["BAZ"])
            XCTAssertEqual(res!.array!.flatMap { $0?.string }, ["BAR"])
        }
        do {
            try client.command(.hdel, ["BAZ", "BAR"])
            let res = try client.command(.hkeys, ["BAZ"])
            XCTAssertEqual(res!.array!.flatMap { $0?.string }, [])
        }
    }

    func testPerformance() throws {
        let key = "P".makeBytes()
        let random = try OSRandom.bytes(count: 2^^16)

        measure {
            for _ in 0..<128 {
                do {
                    let client = try TCPClient()
                    do {
                        let res = try client.command(.set, [key, random])
                        XCTAssertEqual(res?.string, "OK")
                    }
                    do {
                        let bytes = try client.command(.get, [key])?.bytes ?? []
                        XCTAssert(bytes == random)
                    }
                } catch {
                    XCTFail("\(error)")
                }
            }
        }

    }

    func testPipeline() throws {
        let client = try TCPClient()

        let results = try client
            .makePipeline()
            .enqueue(.set, ["FOO", "BAR"])
            .enqueue(.set, ["Hello", "World"])
            .enqueue(.get, ["Hello"])
            .enqueue(.get, ["FOO"])
            .execute()

        XCTAssertEqual(results.count, 4)
        XCTAssertEqual(results[0]?.string, "OK")
        XCTAssertEqual(results[1]?.string, "OK")
        XCTAssertEqual(results[2]?.string, "World")
        XCTAssertEqual(results[3]?.string, "BAR")
    }

    func testError() throws {
        let client = try TCPClient()

        let blah = try Command("BLAH")
        do {
            try client.command(blah)
        } catch let error as RedisError {
            XCTAssert(error.reason.contains("BLAH"))
        } catch {
            XCTFail("\(error)")
        }
    }

    func testPubSub() throws {
        let exp = expectation(description: "publish")

        let group = DispatchGroup()
        group.enter()
        background {
            group.leave()
            let client = try? TCPClient()
            _ = try? client?.subscribe(channel: "vapor") { data in
                let array = data?.array ?? []
                XCTAssertEqual(array.count, 3)
                XCTAssertEqual(array.last??.string, "foo")
                exp.fulfill()
            }
        }

        group.wait()
        usleep(500)

        let client = try TCPClient()
        try client.publish(channel: "vapor", "foo")

        waitForExpectations(timeout: 2)
    }

    static var allTests = [
        ("testPing", testPing),
        ("testString", testString),
        ("testData", testData),
        // ("testPerformance", testPerformance), // no linux
        ("testPipeline", testPipeline),
        ("testError", testError),
        ("testPubSub", testPubSub)
    ]
}

infix operator ^^
func ^^(num: Int, power: Int) -> Int {
    var res = num
    for _ in 1 ..< power {
        res *= num
    }
    return res
}
