import NIO
import XCTest
@testable import Redis

class RedisDataDecoderTests: XCTestCase {
    let decoder = RedisDataDecoder()
    let allocator = ByteBufferAllocator()

    private func simpleStringTestCase(protocolString: String,
                                      expectedString: String?,
                                      otherString: String? = nil) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string:  protocolString)
        try embeddedChannel.writeInbound(buff)
        let decoded: RedisData? = embeddedChannel.readInbound()
        let otherInbound: RedisData? = embeddedChannel.readInbound()

        XCTAssertEqual(decoded?.string, expectedString)
        XCTAssertEqual(otherInbound?.string, otherString)
        _ = try embeddedChannel.finish()
    }

    func testSimpleString() throws {
        try assertWillParseNil(string: "+OK")
        try simpleStringTestCase(protocolString: "+OK\r\n", expectedString: "OK")
        try simpleStringTestCase(protocolString: "+OK\r\n+OTHER STRINGS\r\n",
                                 expectedString: "OK",
                                 otherString: "OTHER STRINGS")

        // decode special charachters guard against string.int
        try simpleStringTestCase(protocolString: "+a complicated string³forTanner\r\n",
                                 expectedString: "a complicated string³forTanner")
    }

    // Test Decoding Errors, one case should be fine
    private func errorTestCase(protocolString: String,
                               expectedString: String?,
                               otherString: String? = nil) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string:  protocolString)
        try embeddedChannel.writeInbound(buff)
        let decoded: RedisData? = embeddedChannel.readInbound()
        let otherInbound: RedisData? = embeddedChannel.readInbound()

        func assertErrorStored(redisData: RedisData, string: String) {
            switch redisData.storage {
            case let .error(redisError):
                XCTAssertEqual(redisError.reason, string)
            default:
                XCTFail("No Error Found")
            }
        }

        if expectedString == nil && otherString == nil {
            XCTAssertNil(decoded)
            XCTAssertNil(otherInbound)
        }

        if let string = expectedString {
            guard let data = decoded else { return XCTFail() }
            assertErrorStored(redisData: data, string: string)
        }

        if let string = otherString {
            guard let data = otherInbound else { return XCTFail() }
            assertErrorStored(redisData: data, string: string)
        }

        _ = try embeddedChannel.finish()
    }

    func testErrors() throws {
        try assertWillParseNil(string: "-ERR")
        try assertWillParseNil(string: "-ERROR\r")
        try errorTestCase(protocolString: "-ERROR\r\n", expectedString: "ERROR")
        try errorTestCase(protocolString: "-ERROR\r\n-OTHER ERROR\r\n",
                          expectedString: "ERROR",
                          otherString: "OTHER ERROR")
    }

    private func integerTestCase(protocolString: String,
                                      expectedInt: Int?,
                                      otherInt: Int? = nil) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string:  protocolString)
        try embeddedChannel.writeInbound(buff)
        let decoded: RedisData? = embeddedChannel.readInbound()
        let otherInbound: RedisData? = embeddedChannel.readInbound()

        XCTAssertEqual(decoded?.int, expectedInt)
        XCTAssertEqual(otherInbound?.int, otherInt)
        _ = try embeddedChannel.finish()
    }

    func testIntegers() throws {
        try assertWillParseNil(string: ":100")
        try assertWillParseNil(string: ":100\r")
        try integerTestCase(protocolString: ":1000\r\n",
                            expectedInt: 1000)

        try integerTestCase(protocolString: ":1000\r\n:99\r\n",
                            expectedInt: 1000,
                            otherInt: 99)
    }

    private func bulkStringTestCase(protocolString: String,
                                      expectedString: String?,
                                      otherString: String? = nil) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string:  protocolString)
        try embeddedChannel.writeInbound(buff)
        let decoded: RedisData? = embeddedChannel.readInbound()
        let otherInbound: RedisData? = embeddedChannel.readInbound()

        XCTAssertEqual(decoded?.string, expectedString)
        XCTAssertEqual(otherInbound?.string, otherString)
        _ = try embeddedChannel.finish()
    }

    func testBulkString() throws {
        try assertWillParseNil(string: "$0\r\n\r")
        try bulkStringTestCase(protocolString: "$0\r\n\r\n",
                               expectedString: "")
        try assertWillParseNil(string: "$1\r\na\r")
        try bulkStringTestCase(protocolString: "$1\r\na\r\n", expectedString: "a")
        try assertWillParseNil(string: "$3\r\naaa\r")
        try bulkStringTestCase(protocolString: "$3\r\nfoo\r\n",
                               expectedString: "foo")
        try bulkStringTestCase(protocolString: "$3\r\naaa\r\n", expectedString: "aaa")
        try bulkStringTestCase(protocolString: "$1\r\na\r\n$2\r\naa\r\n",
                               expectedString: "a",
                               otherString: "aa")

        // decode special charachters guard against multibyte decoding
        try bulkStringTestCase(protocolString: "$3\r\nn³\r\n",
                                expectedString: "n³")
    }

    // Test Null String
    func testNullBulkString() throws {
        let embeddedChannel = EmbeddedChannel()
        defer {
            do {
                _ = try embeddedChannel.finish()
            } catch let err {
                XCTFail("Error \(err)")
            }
        }
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: "$-1\r")
        try embeddedChannel.writeInbound(buff)

        let maybeNil: RedisData? = embeddedChannel.readInbound()
        XCTAssertNil(maybeNil)

        var otherBuff = allocator.buffer(capacity: 256)
        otherBuff.write(string: "\n")
        try embeddedChannel.writeInbound(otherBuff)
        guard let decoded: RedisData = embeddedChannel.readInbound()
            else { return XCTFail() }

        switch decoded.storage {
        case .null:
            XCTAssert(true)
        default:
            XCTFail()
        }
    }

    private func assertWillParseNil(string: String) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: string)
        try embeddedChannel.writeInbound(buff)

        let maybeNil: RedisData? = embeddedChannel.readInbound()
        XCTAssertNil(maybeNil)
        do {
            _ = try embeddedChannel.finish()
        } catch let err {
            XCTFail("Error \(err)")
        }
    }

    private func assertArrayParsing(string: String,
                                    expectedElements: [RedisData] = []) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        defer { _ = try? embeddedChannel.finish() }
        var buff = allocator.buffer(capacity: 256)
        buff.write(string:  string)
        try embeddedChannel.writeInbound(buff)
        guard let decoded: RedisData = embeddedChannel.readInbound()
            else { return XCTFail()}
        guard let decodedArray = decoded.array,
            expectedElements.count == decodedArray.count else { return XCTFail() }

        compareAndValidateRedisArrays(redisArray: decodedArray,
                                      expectedElements: expectedElements)
    }

    private func compareAndValidateRedisArrays(redisArray: [RedisData],
                                               expectedElements: [RedisData]){
        redisArray.enumerated().forEach { (arg) in
            let (offset, decodedElement) = arg
            switch (decodedElement.storage, expectedElements[offset].storage) {
            case (let .bulkString(decoded), let .bulkString(expected)):
                XCTAssertEqual(decoded, expected)
            case (let .basicString(decoded), let .basicString(expected)):
                XCTAssertEqual(decoded, expected)
            case (let .integer(decoded), let .integer(expected)):
                XCTAssertEqual(decoded, expected)
            default:
                XCTFail()
            }
        }
    }

    func testArrays() throws {
        // partial of token
        let partial = "*0\r"
        try assertWillParseNil(string: partial)

        // empty array
        let empty = "*0\r\n"
        try assertArrayParsing(string: empty)

        // array with one element
        let fooArray = "*1\r\n$3\r\nfoo\r\n"
        try assertArrayParsing(string: fooArray,
                               expectedElements:[.bulkString("foo")])

        // array with three elements
        let fooBar3Array = "*3\r\n+foo\r\n$3\r\nbar\r\n:3\r\n"
        try assertArrayParsing(string: fooBar3Array,
                               expectedElements:[.basicString("foo"),
                                                 .bulkString("bar"),
                                                 .integer(3)])
    }

    func testAllTogether() throws {
        let expectedString = "string"
        let basicString = "+\(expectedString)\r\n"
        let expectedError = "error"
        let error = "-\(expectedError)\r\n"
        let expectedInteger = 1
        let integer = ":\(expectedInteger)\r\n"
        let expectedBulkString = "aa"
        let bulkString = "$2\r\naa\r\n"
        let nilString = "$-123\r\n"
        let fooBar3Array = "*3\r\n+foo\r\n$3\r\nbar\r\n:3\r\n"

        let embeddedChannel = EmbeddedChannel()
        defer {
            do { _ = try embeddedChannel.finish() }
            catch { XCTFail() }
        }

        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: basicString)
        buff.write(string: error)
        buff.write(string: integer)
        buff.write(string: bulkString)
        buff.write(string: nilString)
        buff.write(string: fooBar3Array)
        try embeddedChannel.writeInbound(buff)


        let decodedString: RedisData? = embeddedChannel.readInbound()
        let decodedError: RedisData? = embeddedChannel.readInbound()
        let decodedInteger: RedisData? = embeddedChannel.readInbound()
        let decodedBulkString: RedisData? = embeddedChannel.readInbound()
        let decodedNil: RedisData? = embeddedChannel.readInbound()
        let decodedArray: RedisData? = embeddedChannel.readInbound()

        XCTAssertEqual(decodedString?.string, expectedString)

        guard let errorStorage = decodedError?.storage else { return XCTFail() }
        switch errorStorage {
        case let .error(redisError):
            XCTAssertEqual(redisError.reason, expectedError)
        default:
            XCTFail("No Error Found")
        }

        XCTAssertEqual(decodedInteger?.int, expectedInteger)
        XCTAssertEqual(decodedBulkString?.string, expectedBulkString)

        guard let nilStorage = decodedNil?.storage else { return XCTFail() }
        switch nilStorage {
        case .null:
            XCTAssert(true)
        default:
            XCTFail("No Error Found")
        }

        guard let array = decodedArray?.array else { return XCTFail() }
        compareAndValidateRedisArrays(redisArray: array,
                                      expectedElements: [.basicString("foo"),
                                                         .bulkString("bar"),
                                                         .integer(3)])
    }

    static let allTests = [
        ("testSimpleString", testSimpleString),
        ("testErrors", testErrors),
        ("testIntegers", testIntegers),
        ("testBulkString", testBulkString),
        ("testNullBulkString", testNullBulkString),
        ("testArrays", testArrays),
        ("testAllTogether", testAllTogether),
    ]
}
