import XCTest
import NIO
@testable import Redis

class RedisDataEncoderTests: XCTestCase {
    var channel: EmbeddedChannel!
    override func setUp() {
        super.setUp()
        channel = EmbeddedChannel()
        do {
        _ = try channel.pipeline.add(handler: RedisDataEncoder()).wait()
        } catch {
            XCTFail()
        }
    }

    override func tearDown() {
        super.tearDown()
        _ = try? channel.finish()
    }

    private func validatEncodedMessage(expectedMessage: String) {
        let writtenData: IOData = channel.readOutbound()!
        switch writtenData{
        case .byteBuffer(let b):
            let writtenResponse = b.getString(at: b.readerIndex, length: b.readableBytes)!
            XCTAssertEqual(writtenResponse, expectedMessage)
        case .fileRegion:
            XCTFail("Unexpected file region")
        }
    }

    func testEncodingSimpleString() throws {
        let sample = "foo"
        XCTAssertNoThrow(try channel.writeOutbound(RedisData.basicString("foo")))
        validatEncodedMessage(expectedMessage: "+\(sample)\r\n")
    }

    func testEncodingError() throws {
        let myReason = "My reasonable Error"
        let err = RedisError(identifier: "serverSide", reason: myReason, source: .capture())
        XCTAssertNoThrow(try channel.writeOutbound(RedisData.error(err)))
        validatEncodedMessage(expectedMessage: "-\(myReason)\r\n")
    }

    func testEncodingInteger() throws {
        let myInteger = 1112
        XCTAssertNoThrow(try channel.writeOutbound(RedisData.integer(myInteger)))
        validatEncodedMessage(expectedMessage: ":\(myInteger)\r\n")
    }

    func testEncodingBulkString() throws {
        let myString = "My big bulky string"
        XCTAssertNoThrow(try channel.writeOutbound(RedisData.bulkString(myString)))
        validatEncodedMessage(expectedMessage: "$19\r\n\(myString)\r\n")
        XCTAssertNoThrow(try channel.writeOutbound(RedisData.bulkString("")))
        validatEncodedMessage(expectedMessage: "$0\r\n\r\n")
    }

    func testEncodingNil() throws {
        XCTAssertNoThrow(try channel.writeOutbound(RedisData.null))
        validatEncodedMessage(expectedMessage: "$-1\r\n")
    }

    func testEncodingArray() throws {
        let foo = "foo"
        let bar = "bar"
        let baz = "baz"
        let number = 123
        let redisError = RedisError(identifier: "serverSide", reason: bar, source: .capture())
        let redisArray: [RedisData] = [
            .basicString(foo),
            .error(redisError),
            .integer(number),
            .bulkString(baz),
            .null
        ]

        XCTAssertNoThrow(try channel.writeOutbound(RedisData.array(redisArray)))
        validatEncodedMessage(expectedMessage: "*\(redisArray.count)\r\n+\(foo)\r\n-\(bar)\r\n:\(number)\r\n$3\r\n\(baz)\r\n$-1\r\n")

        XCTAssertNoThrow(try channel.writeOutbound(RedisData.array([])))
        validatEncodedMessage(expectedMessage: "*0\r\n")
    }

    static let allTests = [
        ("testEncodingSimpleString", testEncodingSimpleString),
        ("testEncodingError", testEncodingError),
        ("testEncodingInteger", testEncodingInteger),
        ("testEncodingBulkString", testEncodingBulkString),
        ("testEncodingNil", testEncodingNil),
        ("testEncodingArray", testEncodingArray),
        ]
}
