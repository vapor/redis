import NIO
import Dispatch
@testable import Redis
import XCTest

extension RedisClient {
    /// Creates a test event loop and Redis client.
    static func makeTest() throws -> RedisClient {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let password = Environment.get("REDIS_PASSWORD")
        let client = try RedisClient.connect(
            hostname: "localhost",
            port: 6379,
            password: password,
            on: group
        ) { error in
            XCTFail("\(error)")
        }.wait()
        return client
    }
}

class RedisTests: XCTestCase {
    let defaultTimeout = 2.0
    func testCRUD() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        try redis.set("hello", to: "world").wait()
        let get = try redis.get("hello", as: String.self).wait()
        XCTAssertEqual(get, "world")
        try redis.delete("hello").wait()
        XCTAssertNil(try redis.get("hello", as: String.self).wait())
    }

    func testPubSubSingleChannel() throws {
        let futureExpectation = expectation(description: "Subscriber should receive message")

        let redisSubscriber = try RedisClient.makeTest()
        let redisPublisher = try RedisClient.makeTest()
        defer {
            redisPublisher.close()
            redisSubscriber.close()
        }

        let channel1 = "channel1"
        let channel2 = "channel2"

        let expectedChannel1Msg = "Stuff and things"
        _ = try redisSubscriber.subscribe(Set([channel1])) { channelData in
            if channelData.data.string == expectedChannel1Msg {
                futureExpectation.fulfill()
            }
        }.catch { _ in
            XCTFail("this should not throw an error")
        }

        _ = try redisPublisher.publish("Stuff and things", to: channel1).wait()
        _ = try redisPublisher.publish("Stuff and things 3", to: channel2).wait()
        waitForExpectations(timeout: defaultTimeout)
    }

    func testPubSubMultiChannel() throws {
        let expectedChannel1Msg = "Stuff and things"
        let expectedChannel2Msg = "Stuff and things 3"
        let futureExpectation1 = expectation(description: "Subscriber should receive message \(expectedChannel1Msg)")
        let futureExpectation2 = expectation(description: "Subscriber should receive message \(expectedChannel2Msg)")
        let redisSubscriber = try RedisClient.makeTest()
        let redisPublisher = try RedisClient.makeTest()
        defer {
            redisPublisher.close()
            redisSubscriber.close()
        }

        let channel1 = "channel/1"
        let channel2 = "channel/2"

        _ = try redisSubscriber.subscribe(Set([channel1, channel2])) { channelData in
            if channelData.data.string == expectedChannel1Msg {
                futureExpectation1.fulfill()
            } else if channelData.data.string == expectedChannel2Msg {
                futureExpectation2.fulfill()
            }
        }.catch { _ in
            XCTFail("this should not throw an error")
        }
        _ = try redisPublisher.publish("Stuff and things", to: channel1).wait()
        _ = try redisPublisher.publish("Stuff and things 3", to: channel2).wait()
        waitForExpectations(timeout: defaultTimeout)
    }

    func testStruct() throws {
        struct Hello: Codable {
            var message: String
            var array: [Int]
            var dict: [String: Bool]
        }
        let hello = Hello(message: "world", array: [1, 2, 3], dict: ["yes": true, "false": false])
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        try redis.jsonSet("hello", to: hello).wait()
        let get = try redis.jsonGet("hello", as: Hello.self).wait()
        XCTAssertEqual(get?.message, "world")
        XCTAssertEqual(get?.array.first, 1)
        XCTAssertEqual(get?.array.last, 3)
        XCTAssertEqual(get?.dict["yes"], true)
        XCTAssertEqual(get?.dict["false"], false)
        try redis.delete("hello").wait()
    }

    func testStringCommands() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }

        let values = ["hello": RedisData(bulk: "world"), "hello2": RedisData(bulk: "world2")]
        try redis.mset(with: values).wait()
        let resp = try redis.mget(["hello", "hello2"]).wait()
        XCTAssertEqual(resp[0].string, "world")
        XCTAssertEqual(resp[1].string, "world2")
        _ = try redis.delete(["hello", "hello2"]).wait()

        let number = try redis.increment("number").wait()
        XCTAssertEqual(number, 1)
        let number2 = try redis.increment("number", by: 10).wait()
        XCTAssertEqual(number2, 11)
        let number3 = try redis.decrement("number", by: 10).wait()
        XCTAssertEqual(number3, 1)
        let number4 = try redis.decrement("number").wait()
        XCTAssertEqual(number4, 0)
        _ = try redis.delete(["number"]).wait()
    }
    
    
    func testHashCommands() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        
        // create hash value
        let hsetResponse = try redis.hset("hello", field: "world", to: RedisData(bulk: "whatever")).wait()
        XCTAssertEqual(hsetResponse, 1)
        
        // hash field must exist
        let hexistsResponse = try redis.hexists("hello", field: "world").wait()
        XCTAssertEqual(hexistsResponse, true)
        
        // get all field names
        let hkeysResponse = try redis.hkeys("hello").wait()
        XCTAssertEqual(hkeysResponse.count, 1)
        XCTAssertEqual(hkeysResponse.first, "world")
        
        // update hash value
        let hsetResponse2 = try redis.hset("hello", field: "world", to: RedisData(bulk: "value")).wait()
        XCTAssertEqual(hsetResponse2, 0)
        
        // get hash value
        let hgetResponse = try redis.hget("hello", field: "world", as: String.self).wait()
        XCTAssertNotNil(hgetResponse)
        XCTAssertEqual(hgetResponse, "value")
        
        
        // create other 2 hash values
        let _ = try redis.hset("hello", field: "world2", to: RedisData(bulk: "whatever2")).wait()
        let _ = try redis.hset("hello", field: "world3", to: RedisData(bulk: "whatever3")).wait()
        
        // get all keys:values
        let all = try redis.hgetall("hello").wait()
        XCTAssertEqual(all.count, 3)
        
        // verify value
        if let value = all["world2"] {
            let convertedValue = try String.convertFromRedisData(value)
            XCTAssertEqual(convertedValue, "whatever2")
        } else {
            XCTFail("value should exist")
        }

        // delete hash value
        let hdelResponse = try redis.hdel("hello", fields: "not-existing-field").wait()
        XCTAssertEqual(hdelResponse, 0)
        let hdelResponse2 = try redis.hdel("hello", fields: "world").wait()
        XCTAssertEqual(hdelResponse2, 1)
        let hdelResponse3 = try redis.hdel("hello", fields: "world2").wait()
        XCTAssertEqual(hdelResponse3, 1)
        let hdelResponse4 = try redis.hdel("hello", fields: "world3").wait()
        XCTAssertEqual(hdelResponse4, 1)

        // get hash value
        let hgetResponse2 = try redis.hget("hello", field: "world", as: String.self).wait()
        XCTAssertNil(hgetResponse2)

        // hash field must not exist
        let hexistsResponse2 = try redis.hexists("hello", field: "world").wait()
        XCTAssertEqual(hexistsResponse2, false)
    }
    
    

    func testListCommands() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        _ = try redis.command("FLUSHALL").wait()

        let lpushResp = try redis.lpush([RedisData(bulk: "hello")], into: "mylist").wait()
        XCTAssertEqual(lpushResp, 1)

        let rpushResp = try redis.rpush([RedisData(bulk: "hello1")], into: "mylist").wait()
        XCTAssertEqual(rpushResp, 2)

        let length = try redis.length(of: "mylist").wait()
        XCTAssertEqual(length, 2)

        let item = try redis.lIndex(list: "mylist", index: 0).wait()
        XCTAssertEqual(item.string, "hello")

        let items = try redis.lrange(list: "mylist", range: 0...1).wait()
        XCTAssertEqual(items.array?.count, 2)

        try redis.lSet(RedisData(bulk: "hello2"), at: 0, in: "mylist").wait()
        let item2 = try redis.lIndex(list: "mylist", index: 0).wait()
        XCTAssertEqual(item2.string, "hello2")

        let rpopResp = try redis.rPop("mylist").wait()
        XCTAssertEqual(rpopResp.string, "hello1")

        let rpoplpush = try redis.rpoplpush(source: "mylist", destination: "list2").wait()
        XCTAssertEqual(rpoplpush.string, "hello2")

        let lpopResp = try redis.lpop("list2").wait()
        XCTAssertEqual(lpopResp.string, "hello2")

        let blpopResp1 = try redis.blpop(["myList"], timeout: 1).wait()
        XCTAssertNil(blpopResp1)

        let _ = try redis.lpush([RedisData(bulk: "hello")], into: "mylist").wait()
        let blpopResp2 = try redis.blpop(["mylist"], timeout: 1).wait()
        XCTAssertEqual(blpopResp2?.0, "mylist")
        XCTAssertEqual(blpopResp2?.1.string, "hello")

        let brpopResp1 = try redis.brpop(["mylist"], timeout: 1).wait()
        XCTAssertNil(brpopResp1)

        let _ = try redis.lpush([RedisData(bulk: "hello")], into: "mylist").wait()
        let brpopResp2 = try redis.brpop(["mylist"], timeout: 1).wait()
        XCTAssertEqual(brpopResp2?.0, "mylist")
        XCTAssertEqual(brpopResp2?.1.string, "hello")

        let brpoplpushResp1 = try redis.brpoplpush("mylist", "list2", timeout: 1).wait()
        XCTAssertEqual(brpoplpushResp1.isNull, true)

        let _ = try redis.lpush([RedisData(bulk: "hello")], into: "mylist").wait()
        let brpoplpushResp2 = try redis.brpoplpush("mylist", "list2", timeout: 1).wait()
        XCTAssertEqual(brpoplpushResp2.string, "hello")
        let brpoplpushResp3 = try redis.lpop("list2").wait()
        XCTAssertEqual(brpoplpushResp3.string, "hello")

        let _ = try redis.lpush([RedisData(bulk: "hello"), RedisData(bulk: "hello1"), RedisData(bulk: "hello")], into: "mylist").wait()

        XCTAssertEqual(try redis.length(of: "mylist").wait(), 3)
        XCTAssertEqual(try redis.lrem("mylist", count: 1, value: "hello").wait(), 1)
        XCTAssertEqual(try redis.length(of: "mylist").wait(), 2)

        _ = try redis.delete(["mylist", "list2"]).wait()
    }

    func testExpire() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        _ = try redis.command("FLUSHALL").wait()

        try redis.set("foo", to: "bar").wait()
        XCTAssertEqual(try redis.get("foo", as: String.self).wait(), "bar")
        _ = try redis.expire("foo", after: 1).wait()
        sleep(2)
        XCTAssertEqual(try redis.get("foo", as: String.self).wait(), nil)
    }

    func testSetCommands() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        _ = try redis.command("FLUSHALL").wait()

        let dataSet = ["Hello", ",", "World", "!"]

        let addResp1 = try redis.sadd("set1", items: [RedisData(bulk: dataSet[0])]).wait()
        XCTAssertEqual(addResp1, 1)
        let addResp2 = try redis.sadd(
            "set1",
            items: [RedisData(bulk: dataSet[1]), RedisData(bulk: dataSet[2]), RedisData(bulk: dataSet[3])]
        ).wait()
        XCTAssertEqual(addResp2, 3)
        let addResp3 = try redis.sadd("set1", items: [RedisData(bulk: dataSet[1])]).wait()
        XCTAssertEqual(addResp3, 0)

        let countResp = try redis.scard("set1").wait()
        XCTAssertEqual(countResp, 4)

        let membersResp = try redis.smembers("set1").wait().array!.map { $0.string! }
        XCTAssertTrue(membersResp.allSatisfy { dataSet.contains($0) })

        let isMemberResp1 = try redis.sismember("set1", item: RedisData(bulk: dataSet[0])).wait()
        XCTAssertTrue(isMemberResp1)
        let isMemberResp2 = try redis.sismember("set1", item: RedisData(bulk: "Vapor")).wait()
        XCTAssertFalse(isMemberResp2)

        let randResp1 = try redis.srandmember("set1").wait().array!
        XCTAssertTrue(dataSet.contains(randResp1[0].string!))
        let randResp2 = try redis.srandmember("set1", max: 2).wait().array!
        XCTAssertTrue(randResp2.allSatisfy { dataSet.contains($0.string!) })
        let randResp3 = try redis.srandmember("set1", max: 5).wait().array!
        XCTAssertTrue(randResp3.count == 4)
        _ = try redis.sadd("set2", items: [RedisData(bulk: "Vapor"), RedisData(bulk: "Redis")]).wait()
        let randResp4 = try redis.srandmember("set2", max: -3).wait().array!
        XCTAssertTrue(randResp4.count == 3)
        let randResp5 = try redis.srandmember("set2", max: 3).wait().array!
        XCTAssertTrue(randResp5.count == 2)

        let popResp = try redis.spop("set1").wait().string!
        XCTAssertTrue(dataSet.contains(popResp))
        XCTAssertEqual(try redis.scard("set1").wait(), 3)

        let itemToRemove = dataSet.first(where: { $0 != popResp })!
        let remResp1 = try redis.srem("set1", items: [RedisData(bulk: itemToRemove)]).wait()
        XCTAssertEqual(remResp1, 1)
        let remResp2 = try redis.srem("set1", items: [RedisData(bulk: "Vapor")]).wait()
        XCTAssertEqual(remResp2, 0)
        let remainingToRemove = dataSet.filter({ $0 != popResp && $0 != itemToRemove }).map { RedisData(bulk: $0) }
        let remResp3 = try redis.srem("set1", items: remainingToRemove).wait()
        XCTAssertEqual(remResp3, 2)
    }

    func testSortedSetCommands() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        _ = try redis.command("FLUSHALL").wait()

        let dataSet = [("1", RedisData(bulk: "data1")),("2", RedisData(bulk: "data2")),("4", RedisData(bulk: "data3"))]

        let addResp1 = try redis.zadd("zset1", items: dataSet).wait()
        XCTAssertEqual(addResp1, 3)

        let countResp1 = try redis.zcount("zset1", min: "1", max: "(3").wait()
        XCTAssertEqual(countResp1, 2)

        let addResp2 = try redis.zadd("zset1", items: [("3", RedisData(bulk: "data1"))], options: ["XX"]).wait()
        XCTAssertEqual(addResp2, 0)

        let countResp2 = try redis.zcount("zset1", min: "1", max: "(3").wait()
        XCTAssertEqual(countResp2, 1)

        let rangeResp1 = try redis.zrange("zset1", start: 0, stop: 0).wait()
        XCTAssertEqual(rangeResp1.count, 1)
        XCTAssertEqual(rangeResp1[0].string, "data2")

        let rangeScoreResp1 = try redis.zrangebyscore("zset1", min: "3", max: "3").wait()
        XCTAssertEqual(rangeScoreResp1.count, 1)
        XCTAssertEqual(rangeScoreResp1[0].string, "data1")

        let rangeScoreResp2 = try redis.zrangebyscore("zset1", min: "-100", max: "100", withScores: true, limit: (1,2)).wait()
        XCTAssertEqual(rangeScoreResp2.count, 4)
        XCTAssertEqual(rangeScoreResp2[0].string, "data1")
        XCTAssertEqual(rangeScoreResp2[1].string, "3")
        XCTAssertEqual(rangeScoreResp2[2].string, "data3")
        XCTAssertEqual(rangeScoreResp2[3].string, "4")

        let _ = try redis.delete(["zset1"]).wait()
    }
    
    func testPipeline() throws {
        let redis = try RedisClient.makeTest()
        defer { redis.close() }
        _ = try redis.command("FLUSHALL").wait()
        
        let pipeResp1 = try redis.pipeline { pipe in
            pipe.command("INCR", args: [RedisData(bulk: "key1")])
            pipe.command("INCR", args: [RedisData(bulk: "key1")])
            pipe.command("INCR", args: [RedisData(bulk: "key2")])
            pipe.command("INCR", args: [RedisData(bulk: "key1")])
        }.wait()
        
        XCTAssertEqual(pipeResp1.count, 4)
        XCTAssertEqual(pipeResp1[0].int, 1)
        XCTAssertEqual(pipeResp1[1].int, 2)
        XCTAssertEqual(pipeResp1[2].int, 1)
        XCTAssertEqual(pipeResp1[3].int, 3)
        
        // Check the actual keys
        XCTAssertEqual(try redis.get("key1", as: String.self).wait(), "3")
        XCTAssertEqual(try redis.get("key2", as: String.self).wait(), "1")
        
        let pipeResp2 = try redis.multi { pipe in
            pipe.command("INCR", args: RedisData(bulk: "key1"))
            pipe.command("GET", args: RedisData(bulk: "key3"))
            pipe.command("SET", args: RedisData(bulk: "key3"), RedisData(bulk: "string"))
            pipe.command("GET", args: [RedisData(bulk: "key3")])
            pipe.command("PING")
            }.wait()
        
        XCTAssertEqual(pipeResp2.count, 5)
        XCTAssertEqual(pipeResp2[0].int, 4)
        XCTAssertEqual(pipeResp2[1].isNull, true)
        XCTAssertEqual(pipeResp2[2].string, "OK")
        XCTAssertEqual(pipeResp2[3].string, "string")
        XCTAssertEqual(pipeResp2[4].string, "PONG")
        
        // Check the actual keys
        XCTAssertEqual(try redis.get("key1", as: String.self).wait(), "4")
        XCTAssertEqual(try redis.get("key2", as: String.self).wait(), "1")
        XCTAssertEqual(try redis.get("key3", as: String.self).wait(), "string")
        
        let _ = try redis.delete(["key1", "key2", "key3"]).wait()
    }

    static let allTests = [
        ("testCRUD", testCRUD),
        ("testPubSubSingleChannel", testPubSubSingleChannel),
        ("testPubSubMultiChannel", testPubSubMultiChannel),
        ("testStruct", testStruct),
        ("testStringCommands", testStringCommands),
        ("testListCommands", testListCommands),
        ("testExpire", testExpire),
        ("testSetCommands", testSetCommands),
        ("testHashCommands", testHashCommands),
        ("testSortedSetCommands", testSortedSetCommands),
        ("testPipeline", testPipeline)
    ]
}

#if !swift(>=4.2)
extension Sequence {
    func allSatisfy(_ predicate: (Element) throws -> Bool) rethrows -> Bool {
        return try !contains { try !predicate($0) }
    }
}
#endif
