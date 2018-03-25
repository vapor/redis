import Foundation
import Async

/// Connection commands
extension RedisClient {
    /// Request for authentication in a password-protected Redis server
    public func authorize(with password: String) -> Future<Void> {
        return command("AUTH", [RedisData(bulk: password)]).transform(to: ())
    }
    
}

/// Key commands
extension RedisClient {
    /// Removes the specified keys. A key is ignored if it does not exist.
    public func delete(_ keys: [String]) throws -> Future<Int> {
        let resp = command("DEL", keys.map(RedisData.init(bulk:))).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "delete", reason: "Could not convert resp to int", source: .capture())
            }
            return value
        }
        return resp
    }
}

/// String commands
extension RedisClient {
    /// Sets the given keys to their respective values.
    public func mset(with values: [String: RedisData]) -> Future<Void> {
        let args = values.reduce(into: [RedisData]()) { (result, keyValue) in
            result.append(RedisData(bulk: keyValue.key))
            result.append(keyValue.value)
        }
        return command("MSET", args).transform(to: ())
    }
    
    /// Returns the values of all specified keys.
    public func mget(_ keys: [String]) -> Future<[RedisData]> {
        return command("MGET", keys.map(RedisData.init(bulk:))).map(to: [RedisData].self) { data  in
            return data.array ?? []
        }
    }
    
    /// Increments the number stored at key by one or a specified amount.
    public func increment(_ key: String, by amount: Int? = nil) -> Future<Int> {
        let name = amount == nil ? "INCR" : "INCRBY"
        let args = amount == nil ? [RedisData(bulk: key)] : [RedisData(bulk: key), RedisData(bulk: amount!.description)]
        let resp = command(name, args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "increment", reason: "Could not convert resp to int", source: .capture())
            }
            return value
        }
        return resp
    }
    
    /// Decrements the number stored at key by one or a specified amount.
    public func decrement(_ key: String, by amount: Int? = nil) -> Future<Int> {
        let name = amount == nil ? "DECR" : "DECRBY"
        let args = amount == nil ? [RedisData(bulk: key)] : [RedisData(bulk: key), RedisData(bulk: amount!.description)]
        let resp = command(name, args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "decrement", reason: "Could not convert resp to int", source: .capture())
            }
            return value
        }
        return resp
    }
    
}

/// List commands
extension RedisClient {
    
    public func lrange(list: String, range: ClosedRange<Int>) -> Future<RedisData> {
        let lower = RedisData(bulk: range.lowerBound.description)
        let upper = RedisData(bulk: range.upperBound.description)
        return command("LRANGE", [RedisData(bulk: list), lower, upper])
    }
}
