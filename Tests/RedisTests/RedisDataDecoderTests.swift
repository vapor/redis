import NIO
import XCTest
@testable import Redis

class RedisDataDecoderTests: XCTestCase {
    let decoder = RedisDataDecoder()
    let allocator = ByteBufferAllocator()

    private func simpleStringTestCase(
        protocolString: String,
        expectedString: String?,
        otherString: String? = nil
    ) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()

        var buff = allocator.buffer(capacity: 256)
        buff.write(string: protocolString)
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
        try simpleStringTestCase(
            protocolString: "+OK\r\n+OTHER STRINGS\r\n",
            expectedString: "OK",
            otherString: "OTHER STRINGS"
        )
        // decode special charachters guard against string.int
        try simpleStringTestCase(
            protocolString: "+a complicated string³forTanner\r\n",
            expectedString: "a complicated string³forTanner"
        )
    }

    // Test Decoding Errors, one case should be fine
    private func errorTestCase(
        protocolString: String,
        expectedString: String?,
        otherString: String? = nil
    ) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: protocolString)
        try embeddedChannel.writeInbound(buff)
        let decoded: RedisData? = embeddedChannel.readInbound()
        let otherInbound: RedisData? = embeddedChannel.readInbound()
        func assertErrorStored(redisData: RedisData, string: String) {
            guard case let RedisData.Storage.error(error) = redisData.storage else {
               return XCTFail("Error not stored")
            }
            XCTAssertEqual(error.reason, string)
        }
        if expectedString == nil && otherString == nil {
            XCTAssertNil(decoded)
            XCTAssertNil(otherInbound)
        }
        if let string = expectedString {
            guard let data = decoded else { return XCTFail("no decoded data") }
            assertErrorStored(redisData: data, string: string)
        }
        if let string = otherString {
            guard let data = otherInbound else { return XCTFail("no decoded data") }
            assertErrorStored(redisData: data, string: string)
        }
        _ = try embeddedChannel.finish()
    }

    func testErrors() throws {
        try assertWillParseNil(string: "-ERR")
        try assertWillParseNil(string: "-ERROR\r")
        try errorTestCase(protocolString: "-ERROR\r\n", expectedString: "ERROR")
        try errorTestCase(
            protocolString: "-ERROR\r\n-OTHER ERROR\r\n",
            expectedString: "ERROR",
            otherString: "OTHER ERROR"
        )
    }

    private func integerTestCase(protocolString: String, expectedInt: Int?, otherInt: Int? = nil) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: protocolString)
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
        try integerTestCase(protocolString: ":1000\r\n", expectedInt: 1000)
        try integerTestCase(protocolString: ":1000\r\n:99\r\n", expectedInt: 1000, otherInt: 99)
    }

    private func bulkStringTestCase(
        protocolData: Foundation.Data,
        expectedData: Foundation.Data?,
        otherData: Foundation.Data? = nil
    ) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(bytes: protocolData)
        try embeddedChannel.writeInbound(buff)
        let decoded: RedisData? = embeddedChannel.readInbound()
        let otherInbound: RedisData? = embeddedChannel.readInbound()
        XCTAssertEqual(decoded?.data, expectedData)
        XCTAssertEqual(otherInbound?.data, otherData)
        _ = try embeddedChannel.finish()
    }
    
    private func bulkStringTestCase(
        protocolString: String,
        expectedString: String?,
        otherString: String? = nil
    ) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: protocolString)
        try embeddedChannel.writeInbound(buff)
        let decoded: RedisData? = embeddedChannel.readInbound()
        let otherInbound: RedisData? = embeddedChannel.readInbound()
        XCTAssertEqual(decoded?.string, expectedString)
        XCTAssertEqual(otherInbound?.string, otherString)
        _ = try embeddedChannel.finish()
    }

    private func bulkStringTestCase(bytes: [UInt8]) throws {
        let data = Foundation.Data(bytes: bytes)
        let protocolData = "$\(data.count)\r\n".convertToData() + data + "\r\n".convertToData()
        XCTAssertNoThrow(try bulkStringTestCase(protocolData: protocolData, expectedData: data))
    }

    func testBulkString() throws {
        try assertWillParseNil(string: "$0\r\n\r")
        try bulkStringTestCase(protocolString: "$0\r\n\r\n", expectedString: "")
        try assertWillParseNil(string: "$1\r\na\r")
        try bulkStringTestCase(protocolString: "$1\r\na\r\n", expectedString: "a")
        try assertWillParseNil(string: "$3\r\naaa\r")
        try bulkStringTestCase(protocolString: "$3\r\nfoo\r\n", expectedString: "foo")
        try bulkStringTestCase(protocolString: "$3\r\naaa\r\n", expectedString: "aaa")
        try bulkStringTestCase(protocolString: "$1\r\na\r\n$2\r\naa\r\n", expectedString: "a", otherString: "aa")
        try bulkStringTestCase(protocolString: "$3\r\nn³\r\n", expectedString: "n³")
        let incompleteString = "*8\r\n$16\r\ntest8:1523640910\r\n$10\r\n1523640910\r\n$16\r\ntest9:15" +
        "23640913\r\n$10\r\n1523640913\r\n$17\r\ntest10:1523640916\r\n$10\r\n15"
        try bulkStringTestCase(protocolString: incompleteString, expectedString: nil)
        do {
            let str = "κόσμε"
            let bytes = str.convertToData()
            try bulkStringTestCase(protocolString: "$\(bytes.count)\r\n\(str)\r\n", expectedString: str)
        }

        // test raw bytes
        try bulkStringTestCase(bytes: [0x00, 0x01, 0x02, 0x03, 0x0A, 0xff]) // 0xff is problematic for UTF-8 encoding

        // test UTF-8 string
        try bulkStringTestCase(bytes: [UInt8]("κόσμε".convertToData()))
    }

    // Test Null String
    func testNullBulkString() throws {
        let embeddedChannel = EmbeddedChannel()
        defer { _ = try? embeddedChannel.finish() }
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: "$-1\r")
        try embeddedChannel.writeInbound(buff)
        let maybeNil: RedisData? = embeddedChannel.readInbound()
        XCTAssertNil(maybeNil)
        var otherBuff = allocator.buffer(capacity: 256)
        otherBuff.write(string: "\n")
        try embeddedChannel.writeInbound(otherBuff)
        guard let decoded: RedisData = embeddedChannel.readInbound() else { return XCTFail("no encoded data") }
        switch decoded.storage {
        case .null:
            XCTAssert(true)
        default:
            XCTFail("null was not stored")
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
        _ = try embeddedChannel.finish()
    }

    private func assertArrayParsing(string: String, expectedElements: [RedisData] = []) throws {
        let embeddedChannel = EmbeddedChannel()
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        defer { _ = try? embeddedChannel.finish() }
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: string)
        try embeddedChannel.writeInbound(buff)
        guard let decoded: RedisData = embeddedChannel.readInbound()
        else { return XCTFail("no decoded data") }
        guard let decodedArray = decoded.array, expectedElements.count == decodedArray.count
        else { return XCTFail("no decoded data") }
        compareAndValidateRedisArrays(redisArray: decodedArray, expectedElements: expectedElements)
    }

    private func compareAndValidateRedisArrays(redisArray: [RedisData], expectedElements: [RedisData]) {
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
                XCTFail("type match failure")
            }
        }
    }

    func testArrays() throws {
        // partial of token
        let partial = "*0\r"
        try assertWillParseNil(string: partial)
        let empty = "*0\r\n" // empty array
        try assertArrayParsing(string: empty)
        let fooArray = "*1\r\n$3\r\nfoo\r\n" // array with one element
        try assertArrayParsing(string: fooArray, expectedElements: [.bulkString("foo")])
        let fooBar3Array = "*3\r\n+foo\r\n$3\r\nbar\r\n:3\r\n"
        let expectedElements: [RedisData] = [.basicString("foo"), .bulkString("bar"), .integer(3)]
        try assertArrayParsing(string: fooBar3Array, expectedElements: expectedElements)
        try assertWillParseNil(string: "*2\r\n$5\r\ntest0\r\n")
    }

    // Test Null Array
    func testNullArray() throws {
        let embeddedChannel = EmbeddedChannel()
        defer { _ = try? embeddedChannel.finish() }
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: "*-1\r")
        try embeddedChannel.writeInbound(buff)
        let maybeNil: RedisData? = embeddedChannel.readInbound()
        XCTAssertNil(maybeNil)
        var otherBuff = allocator.buffer(capacity: 256)
        otherBuff.write(string: "\n")
        try embeddedChannel.writeInbound(otherBuff)
        guard let decoded: RedisData = embeddedChannel.readInbound() else { return XCTFail("no encoded data") }
        switch decoded.storage {
        case .null:
            XCTAssert(true)
        default:
            XCTFail("null was not stored")
        }
    }
}

extension RedisDataDecoderTests {
    // This is an exceptionally long test
    private struct Data {
        static let expectedString = "string"
        static let basicString = "+\(expectedString)\r\n"
        static let expectedError = "error"
        static let error = "-\(expectedError)\r\n"
        static let expectedInteger = 1
        static let integer = ":\(expectedInteger)\r\n"
        static let expectedBulkString = "aa"
        static let bulkString = "$2\r\naa\r\n"
        static let nilString = "$-123\r\n"
        static let fooBar3Array = "*3\r\n+foo\r\n$3\r\nbar\r\n:3\r\n"
        static let nilArray = "*-1\r\n"
    }

    func testAllTogether() throws {
        let embeddedChannel = EmbeddedChannel()
        defer { _ = try? embeddedChannel.finish() }
        try embeddedChannel.pipeline.add(handler: decoder).wait()
        var buff = allocator.buffer(capacity: 256)
        buff.write(string: Data.basicString)
        buff.write(string: Data.error)
        buff.write(string: Data.integer)
        buff.write(string: Data.bulkString)
        buff.write(string: Data.nilString)
        buff.write(string: Data.fooBar3Array)
        buff.write(string: Data.nilArray)
        try embeddedChannel.writeInbound(buff)
        let decodedString: RedisData? = embeddedChannel.readInbound()
        let decodedError: RedisData? = embeddedChannel.readInbound()
        let decodedInteger: RedisData? = embeddedChannel.readInbound()
        let decodedBulkString: RedisData? = embeddedChannel.readInbound()
        let decodedNil: RedisData? = embeddedChannel.readInbound()
        let decodedArray: RedisData? = embeddedChannel.readInbound()
        let decodedNilArray: RedisData? = embeddedChannel.readInbound()
        XCTAssertEqual(decodedString?.string, Data.expectedString)
        guard let errorStorage = decodedError?.storage else { return XCTFail("no decoded data stored") }
        switch errorStorage {
        case let .error(redisError):
            XCTAssertEqual(redisError.reason, Data.expectedError)
        default:
            XCTFail("No Error Found")
        }
        XCTAssertEqual(decodedInteger?.int, Data.expectedInteger)
        XCTAssertEqual(decodedBulkString?.string, Data.expectedBulkString)
        guard let nilStorage = decodedNil?.storage else { return XCTFail("no decoded data stored") }
        switch nilStorage {
        case .null:
            XCTAssert(true)
        default:
            XCTFail("No Error Found")
        }
        guard let array = decodedArray?.array else { return XCTFail("no decoded array found") }
        let expectedElements: [RedisData] = [.basicString("foo"), .bulkString("bar"), .integer(3)]
        compareAndValidateRedisArrays(redisArray: array, expectedElements: expectedElements)
        guard let nilArrayStorage = decodedNilArray?.storage else { return XCTFail("no decoded data stored")}
        switch nilArrayStorage {
        case .null:
            XCTAssert(true)
        default:
            XCTFail("No Error Found")
        }
    }
}

extension RedisDataDecoderTests {
    static let allTests = [
        ("testSimpleString", testSimpleString),
        ("testErrors", testErrors),
        ("testIntegers", testIntegers),
        ("testBulkString", testBulkString),
        ("testNullBulkString", testNullBulkString),
        ("testArrays", testArrays),
        ("testNullArray", testNullArray),
        ("testAllTogether", testAllTogether)
    ]
}
