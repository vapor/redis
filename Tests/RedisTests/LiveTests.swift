import XCTest
@testable import Redis
import Random

class LiveTests: XCTestCase {
    func testPing() throws {
        let client = try Client.makeTest()
        let res = try client.command(.ping)
        XCTAssertEqual(res.string, "PONG")
    }

    func testString() throws {
        let client = try Client.makeTest()
        do {
            let res = try client.command(.set, ["FOO", "BAR"])
            XCTAssertEqual(res.string, "OK")
        }
        do {
            let res = try client.command(.get, ["FOO"])
            XCTAssertEqual(res.string, "BAR")
        }
    }

    func testData() throws {
        let client = try Client.makeTest()
        let random = try OSRandom.bytes(count: 65_536)
        do {
            let res = try client.command(.set, ["FOO".makeBytes(), random])
            XCTAssertEqual(res.string, "OK")
        }
        do {
            let res = try client.command(.get, ["FOO"])
            XCTAssert(res.bytes! == random)
        }
    }

    func testPerformance() throws {
        let key = "P".makeBytes()
        let random = try OSRandom.bytes(count: 2^^16)

        measure {
            for _ in 0..<128 {
                do {
                    let client = try Client.makeTest()
                    do {
                        let res = try client.command(.set, [key, random])
                        XCTAssertEqual(res.string, "OK")
                    }
                    do {
                        let bytes = try client.command(.get, [key]).bytes ?? []
                        XCTAssert(bytes == random)
                    }
                } catch {
                    XCTFail("\(error)")
                }
            }
        }

    }

    static var allTests = [
        ("testPing", testPing),
        ("testString", testString),
        ("testData", testData),
        ("testPerformance", testPerformance)
    ]
}

extension Client {
    static func makeTest() throws -> Client {
        return try Client(hostname: "127.0.0.1", port: 6379)
    }
}

infix operator ^^
func ^^(num: Int, power: Int) -> Int {
    var res = num
    for _ in 1 ..< power {
        res *= num
    }
    return res
}
