import RediStack
import NIO

@available(*, deprecated, renamed: "RESPValue")
public typealias RedisData = RESPValue

@available(*, deprecated, renamed: "RedisConfiguration")
public typealias RedisClientConfig = RedisConfiguration

@available(*, deprecated, renamed: "RESPValueConvertible")
public typealias RedisDataConvertible = RESPValueConvertible

extension RESPValueConvertible {
    @available(*, deprecated, message: "This has been made a failable initializer - init?(fromRESP:)")
    public static func convertFromRedisData(_ data: RESPValue) throws -> Self {
        guard let value = Self(fromRESP: data) else { throw RedisClientError.failedRESPConversion(to: Self.self) }
        return value
    }
    
    @available(*, deprecated, renamed: "convertedToRESPValue()")
    public func convertToRedisData() throws -> RESPValue {
        return self.convertedToRESPValue()
    }
}

extension RedisClient {
    @available(*, deprecated, message: "This method has been removed. Use send(command:with:) instead.")
    public func command(_ command: String, _ arguments: [RESPValue] = []) -> EventLoopFuture<RESPValue> {
        self.send(command: command, with: arguments)
    }
    
    @available(*, unavailable, message: "Use send(command:with:) instead.")
    public func send(_ message: RESPValue) -> EventLoopFuture<RESPValue> { preconditionFailure("Unavailable API") }
}

// MARK: Basic Commands

extension RedisClient {
    @available(*, deprecated, renamed: "select(database:)")
    public func select(_ database: Int) -> EventLoopFuture<String> {
        return self.select(database: database)
            .map { return "OK" }
    }
    
    @available(*, deprecated, message: "Provide a RedisKey and TimeAmount instead instead.")
    public func expire(_ key: String, after deadline: Int) -> EventLoopFuture<Int> {
        return self.expire(.init(key), after: .seconds(.init(deadline)))
            .map { result in result ? 1 : 0 }
    }
}

// MARK: String Commands

extension RedisClient {
    @available(*, deprecated, renamed: "get(_:asJSON:)")
    public func jsonGet<D: Decodable>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> {
        return self.get(.init(key), asJSON: type)
    }
    
    @available(*, deprecated, renamed: "set(_:toJSON:)")
    public func jsonSet<E: Encodable>(_ key: String, as type: E) -> EventLoopFuture<Void> {
        return self.set(.init(key), toJSON: type)
    }

    @available(*, deprecated, renamed: "get(_:)")
    public func rawGet(_ key: String) -> EventLoopFuture<RESPValue> {
        #warning("Use the new self.get(_:) method")
        // return self.get(.init(key))
        return self.get(.init(key), as: RESPValue.self)
            // safe because .get(_:) calls the RESPValueConvertible.init(fromRESP:) method
            // which always succeeds for RESPValue (returns self)
            .map { return $0! }
    }
}

// MARK: Hash Commands

extension RedisClient {
    @available(*, deprecated, renamed: "hkeys(in:)")
    public func hkeys(_ key: String) -> EventLoopFuture<[String]> {
        return self.hkeys(in: .init(key))
    }
    
//    @available(*, deprecated, renamed: "hget(_:from:as:)")
//    public func hget<D: RESPValueConvertible>(_ key: String, field: String, as type: D.Type) -> EventLoopFuture<D?> {
//        return self.hget(field, from: .init(key))
//    }
    
//    @available(*, deprecated, renamed: "hget(_:from:)")
//    public func hget(_ key: String, field: String) -> EventLoopFuture<RESPValue> {
//        return self.hget(field, from: .init(key))
//    }
    
//    @available(*, deprecated, renamed: "hmget(_:from:)")
//    public func hmget(_ key: String, fields: [String]) -> EventLoopFuture<[RESPValue]> {
//        return self.hmget(fields, from: .init(key))
//    }
    
//    @available(*, deprecated, renamed: "hgetall(from:)")
//    public func hgetall(_ key: String) -> EventLoopFuture<[String: RESPValue]> {
//        return self.hgetall(from: .init(key))
//    }
    
    @available(*, deprecated, renamed: "hset(_:to:in:)")
    public func hset<E: RESPValueConvertible>(_ key: String, field: String, to data: E) -> EventLoopFuture<Int> {
        return self.hset(field, to: data, in: .init(key))
            .map { return $0 ? 1 : 0 }
    }
    
    @available(*, deprecated, renamed: "hmset(_:in:)")
    public func hmset(_ key: String, items: [(String, RESPValue)]) -> EventLoopFuture<String> {
        let fields: [String: RESPValue] = items.reduce(into: [:]) { result, next in
            result[next.0] = next.1
        }
        return self.hmset(fields, in: .init(key))
            .map { return "OK" }
    }

    @available(*, deprecated, renamed: "hdel(_:from:)")
    public func hdel(_ key: String, fields: String...) -> EventLoopFuture<Int> {
        return self.hdel(fields, from: .init(key))
    }

    @available(*, deprecated, renamed: "hdel(_:from:)")
    public func hdel(_ key: String, fields: [String]) -> EventLoopFuture<Int> {
        return self.hdel(fields, from: .init(key))
    }

    @available(*, deprecated, renamed: "hexists(_:in:)")
    public func hexists(_ key: String, field: String) -> EventLoopFuture<Bool> {
        return self.hexists(field, in: .init(key))
    }
}

// MARK: List Commands

extension RedisClient {
    @available(*, deprecated, renamed: "lrange(from:indices:)")
    public func lrange(list: String, range: ClosedRange<Int>) -> EventLoopFuture<RESPValue> {
        return self.lrange(from: .init(list), indices: range)
            .map { return .array($0) }
    }
    
    @available(*, deprecated, renamed: "lindex(_:from:)")
    public func lIndex(list: String, index: Int) -> EventLoopFuture<RESPValue> {
        return self.lindex(index, from: .init(list))
    }
    
    @available(*, deprecated, renamed: "llen(of:)")
    public func length(of list: String) -> EventLoopFuture<Int> {
        return self.llen(of: .init(list))
    }
    
    @available(*, deprecated, renamed: "lset(index:to:in:)")
    public func lSet(_ item: RESPValue, at index: Int, in list: String) -> EventLoopFuture<Void> {
        return self.lset(index: index, to: item, in: .init(list))
    }
    
    @available(*, deprecated, renamed: "rpop(from:)")
    public func rPop(_ list: String) -> EventLoopFuture<RESPValue> {
        return self.rpop(from: .init(list))
    }
    
    @available(*, deprecated, renamed: "lpop(from:)")
    public func lpop(_ list: String) -> EventLoopFuture<RESPValue> {
        return self.lpop(from: .init(list))
    }
    
    @available(*, deprecated, renamed: "lrem(_:from:count:)")
    public func lrem(_ list: String, count: Int, value: RESPValue) -> EventLoopFuture<Int> {
        return self.lrem(value, from: .init(list), count: count)
    }
    
    @available(*, deprecated, renamed: "rpoplpush(from:to:)")
    public func rpoplpush(source: String, destination: String) -> EventLoopFuture<RESPValue> {
        return self.rpoplpush(from: .init(source), to: .init(destination))
    }
    
    @available(*, deprecated, renamed: "blpop(from:timeout:)")
    public func blpop(_ lists: [String], timeout: Int = 0) -> EventLoopFuture<(String, RESPValue)?> {
        let keys = lists.map(RedisKey.init(_:))
        return self.blpop(from: keys, timeout: .seconds(.init(timeout)))
            .map {
                guard let result = $0 else { return nil }
                return (result.0.rawValue, result.1)
            }
    }
    
    @available(*, deprecated, renamed: "brpop(from:timeout:)")
    public func brpop(_ lists: [String], timeout: Int = 0) -> EventLoopFuture<(String, RESPValue)?> {
        let keys = lists.map(RedisKey.init(_:))
        return self.brpop(from: keys, timeout: .seconds(.init(timeout)))
            .map {
                guard let result = $0 else { return nil }
                return (result.0.rawValue, result.1)
            }
    }
    
    @available(*, deprecated, renamed: "brpoplpush(from:to:timeout:)")
    public func brpoplpush(_ source: String, _ dest: String, timeout: Int = 0) -> EventLoopFuture<RESPValue> {
        return self.brpoplpush(from: .init(source), to: .init(dest), timeout: .seconds(.init(timeout)))
            .map { $0 ?? .null }
        #warning("remove the map")
    }
}

// MARK: Set Commands

extension RedisClient {
    @available(*, deprecated, renamed: "smembers(of:)")
    public func smembers(_ key: String) -> EventLoopFuture<RESPValue> {
        return self.smembers(of: .init(key))
            .map { return .array($0) }
    }
    
    @available(*, deprecated, renamed: "sismember(_:of:)")
    public func sismember(_ key: String, item: RESPValue) -> EventLoopFuture<Bool> {
        return self.sismember(item, of: .init(key))
    }
    
    @available(*, deprecated, renamed: "scard(of:)")
    public func scard(_ key: String) -> EventLoopFuture<Int> {
        return self.scard(of: .init(key))
    }
    
    @available(*, deprecated, renamed: "sadd(_:to:)")
    public func sadd(_ key: String, items: [RESPValue]) -> EventLoopFuture<Int> {
        return self.sadd(items, to: .init(key))
    }
    
    @available(*, deprecated, renamed: "srem(_:from:)")
    public func srem(_ key: String, items: [RESPValue]) -> EventLoopFuture<Int> {
        return self.srem(items, from: .init(key))
    }
    
    @available(*, deprecated, renamed: "spop(from:)")
    public func spop(_ key: String) -> EventLoopFuture<RESPValue> {
        return self.spop(from: .init(key))
            .map { return $0[0] }
    }
    
    @available(*, deprecated, renamed: "srandmember(from:max:)")
    public func srandmember(_ key: String, max count: Int = 1) -> EventLoopFuture<RESPValue> {
        return self.srandmember(from: .init(key), max: count)
            .map { return .array($0) }
    }
}

// MARK: Sorted Set Commands

extension RedisClient {
    @available(*, deprecated, renamed: "zadd(_:to:inserting:returning:)")
    public func zadd(_ key: String, items: [(String, RESPValue)], options: [String] = []) -> EventLoopFuture<Int> {
        let convertedItems = items.map { (item: (String, RESPValue)) -> (RESPValue, Double) in
            guard let double = Double(item.0) else { preconditionFailure("Invalid Double representation.") }
            return (item.1, double)
        }
        
        var returnOption = RedisZaddReturnBehavior.insertedElementsCount
        var insertOption: RedisZaddInsertBehavior? = nil
        for opt in options {
            switch opt.uppercased() {
            case "XX":
                if insertOption != nil { preconditionFailure("XX and NX are mutually exclusive!") }
                else { insertOption = .onlyExistingElements }
            case "NX":
                if insertOption != nil { preconditionFailure("XX and NX are mutually exclusive!") }
                else { insertOption = .onlyNewElements }
            case "CH":
                returnOption = .changedElementsCount
            default: break
            }
        }
        
        return self.zadd(
            convertedItems,
            to: .init(key),
            inserting: insertOption ?? .allElements,
            returning: returnOption
        )
    }
    
    @available(*, unavailable, message: "The string based API has been replaced with zcount(of:withScoresBetween:)")
    public func zcount(_ key: String, min: String, max: String) -> EventLoopFuture<Int> { preconditionFailure("Unsupported API") }
    
    @available(*, deprecated, renamed: "zrange(from:firstIndex:lastIndex:includeScoresInResponse:)")
    public func zrange(_ key: String, start: Int, stop: Int, withScores: Bool = false) -> EventLoopFuture<[RESPValue]> {
        return self.zrange(from: .init(key), firstIndex: start, lastIndex: stop, includeScoresInResponse: withScores)
    }
    
    @available(*, unavailable, message: "The string based API has been replaced with zrangebyscore(from:withScoresBetween:limitBy:includeScoresInResponse:)")
    public func zrangebyscore(_ key: String, min: String, max: String, withScores: Bool = false, limit: (Int, Int)? = nil) -> EventLoopFuture<[RESPValue]> {
        preconditionFailure("Unsupported API")
    }
    
    @available(*, deprecated, renamed: "zrem(_:from:)")
    public func zrem(_ key: String, members: [RESPValue]) -> EventLoopFuture<Int> {
        return self.zrem(members, from: .init(key))
    }
}

// MARK: String Commands

extension RedisClient {
    @available(*, deprecated, renamed: "mset(_:)")
    public func mset(with values: [String: RESPValue]) -> EventLoopFuture<Void> {
        let operations: [RedisKey: RESPValue] = values.reduce(into: [:]) { result, next in
            result[.init(next.0)] = next.1
        }
        return self.mset(operations)
    }
}
