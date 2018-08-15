import XCTest
import NIO
@testable import Redis

class RedisDataEncoderTests: XCTestCase {
    var channel: EmbeddedChannel!
    override func setUp() {
        super.setUp()
        channel = EmbeddedChannel()
        _ = try? channel.pipeline.add(handler: RedisDataEncoder()).wait()
    }

    override func tearDown() {
        super.tearDown()
        _ = try? channel.finish()
    }

    private func validatEncodedMessage(expectedMessage: String) {
        let writtenData: IOData = channel.readOutbound()!
        switch writtenData {
        case .byteBuffer(let buff):
            let writtenResponse = buff.getString(at: buff.readerIndex, length: buff.readableBytes)!
            XCTAssertEqual(writtenResponse, expectedMessage)
        case .fileRegion:
            XCTFail("Unexpected file region")
        }
    }

    private func validatEncodedMessage(expectedData: Data) {
        let writtenData: IOData = channel.readOutbound()!
        switch writtenData {
        case .byteBuffer(let buff):
            let writtenResponse = buff.getData(at: buff.readerIndex, length: buff.readableBytes)!
            XCTAssertEqual(writtenResponse, expectedData)
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
        let err = RedisError(identifier: "serverSide", reason: myReason)
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

        let data = Data(bytes: [0x00, 0x00, 0x01, 0x02, 0x03, 0xff])
        XCTAssertNoThrow(try channel.writeOutbound(RedisData.bulkString(data)))
        validatEncodedMessage(expectedData: "$\(data.count)\r\n".convertToData() + data + "\r\n".convertToData())
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
        let redisError = RedisError(identifier: "serverSide", reason: bar)
        let redisArray: [RedisData] = [
            .basicString(foo),
            .error(redisError),
            .integer(number),
            .bulkString(baz),
            .null
        ]

        XCTAssertNoThrow(try channel.writeOutbound(RedisData.array(redisArray)))
        let expected = "*\(redisArray.count)\r\n+\(foo)\r\n-\(bar)\r\n:\(number)\r\n$3\r\n\(baz)\r\n$-1\r\n"
        validatEncodedMessage(expectedMessage: expected)

        XCTAssertNoThrow(try channel.writeOutbound(RedisData.array([])))
        validatEncodedMessage(expectedMessage: "*0\r\n")
    }

    static let allTests = [
        ("testEncodingSimpleString", testEncodingSimpleString),
        ("testEncodingError", testEncodingError),
        ("testEncodingInteger", testEncodingInteger),
        ("testEncodingBulkString", testEncodingBulkString),
        ("testEncodingNil", testEncodingNil),
        ("testEncodingArray", testEncodingArray)
    ]
}
