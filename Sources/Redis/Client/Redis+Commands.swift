/// Connection commands
extension RedisClient {
    // MARK: Auth

    /// Request for authentication in a password-protected Redis server
    public func authorize(with password: String) -> Future<Void> {
        return command("AUTH", [RedisData(bulk: password)]).transform(to: ())
    }

    // MARK: Delete

    /// Removes the specified keys. A key is ignored if it does not exist.
    public func delete(_ key: String) -> Future<Void> {
        return command("DEL", [RedisData(bulk: key)]).transform(to: ())
    }

    /// Removes the specified keys. A key is ignored if it does not exist.
    public func delete(_ keys: String...) -> Future<Int> {
        return delete(keys)
    }

    /// Removes the specified keys. A key is ignored if it does not exist.
    public func delete(_ keys: [String]) -> Future<Int> {
        let resp = command("DEL", keys.map(RedisData.init(bulk:))).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "delete", reason: "Could not convert resp to int.")
            }
            return value
        }
        return resp
    }

    // MARK: Expire
    
    /// Set a timeout on key. After the timeout has expired, the key will automatically be deleted.
    /// A key with an associated timeout is often said to be volatile in Redis terminology.
    ///
    ///     let res = try redis.expire("foo", after: 42).wait()
    ///
    /// https://redis.io/commands/expire
    public func expire(_ key: String, after deadline: Int) -> Future<Int> {
        let resp = command("EXPIRE", [RedisData(stringLiteral:key), RedisData(integerLiteral: deadline)]).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "expire", reason: "Could not convert resp to in.t")
            }

            return value
        }

        return resp
    }

    // MARK: Convertible

    /// Gets key as a `RedisDataConvertible` type.
    public func get<D>(_ key: String, as type: D.Type) -> Future<D?> where D: RedisDataConvertible {
        return rawGet(key).map(to: D?.self) { data in
            if data.isNull {
                return nil
            } else {
                return try D.convertFromRedisData(data)
            }
        }
    }

    /// Sets key to a `RedisDataConvertible` type.
    public func set<E>(_ key: String, to data: E) -> Future<Void> where E: RedisDataConvertible {
        return Future.flatMap(on: self.eventLoop) {
            let data = try data.convertToRedisData()
            switch data.storage {
            case .bulkString: break
            default:
                throw RedisError(
                    identifier: "setData",
                    reason: "Set data must be of type bulkString"
                )
            }
            return self.rawSet(key, to: data)
        }
    }

    // MARK: JSON

    /// Gets key as a decodable type.
    public func jsonGet<D>(_ key: String, as type: D.Type) -> Future<D?> where D: Decodable {
        return get(key, as: Data.self).thenThrowing { data in
            return try data.flatMap { data in
                return try JSONDecoder().decode(D.self, from: data)
            }
        }
    }

    /// Sets key to an encodable item.
    public func jsonSet<E>(_ key: String, to entity: E) -> Future<Void> where E: Encodable {
        do {
            return try set(key, to: JSONEncoder().encode(entity))
        } catch {
            return eventLoop.newFailedFuture(error: error)
        }
    }

    // MARK: JSON

    /// Gets key as `RedisData`.
    public func rawGet(_ key: String) -> Future<RedisData> {
        return command("GET", [RedisData(bulk: key)])
    }

    /// Sets key to `RedisData`.
    public func rawSet(_ key: String, to data: RedisData) -> Future<Void> {
        return command("SET", [RedisData(bulk: key), data]).transform(to: ())
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
                throw RedisError(identifier: "increment", reason: "Could not convert resp to int.")
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
                throw RedisError(identifier: "decrement", reason: "Could not convert resp to int.")
            }
            return value
        }
        return resp
    }

}

/// List commands
extension RedisClient {
    /// Returns the specified elements of the list stored at key.
    public func lrange(list: String, range: ClosedRange<Int>) -> Future<RedisData> {
        let lower = RedisData(bulk: range.lowerBound.description)
        let upper = RedisData(bulk: range.upperBound.description)
        return command("LRANGE", [RedisData(bulk: list), lower, upper])
    }

    /// Insert all the specified values at the tail of the list stored at key.
    public func rpush(_ values: [RedisData], into list: String) -> Future<Int> {
        var args = values
        args.insert(RedisData(bulk: list), at: 0)
        let resp = command("RPUSH", args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "rpush", reason: "Could not convert resp to int.")
            }
            return value
        }
        return resp
    }

    /// Insert all the specified values at the head of the list stored at key.
    public func lpush(_ values: [RedisData], into list: String) -> Future<Int> {
        var args = values
        args.insert(RedisData(bulk: list), at: 0)
        let resp = command("LPUSH", args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "rpush", reason: "Could not convert resp to int.")
            }
            return value
        }
        return resp
    }

    /// Returns the element at index in the list stored at key.
    public func lIndex(list: String, index: Int) -> Future<RedisData> {
        return command("LINDEX", [RedisData(bulk: list), RedisData(bulk: index.description)])
    }

    /// Returns the length of the list stored at key.
    public func length(of list: String) -> Future<Int> {
        let resp = command("LLEN", [RedisData(bulk: list)]).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "length", reason: "Could not convert resp to int.")
            }
            return value
        }
        return resp
    }

    /// Sets the list element at index to value.
    public func lSet(_ item: RedisData, at index: Int, in list: String) -> Future<Void> {
        let resp = command("LSET", [RedisData(bulk: list), RedisData(bulk: index.description), item])
        return resp.transform(to: ())
    }

    /// Removes and returns the last element of the list stored at key.
    public func rPop(_ list: String) -> Future<RedisData> {
        return command("RPOP", [RedisData(bulk: list)])
    }

    /// Atomically returns and removes the last element (tail) of the list stored at source,
    /// and pushes the element at the first element (head) of the list stored at destination.
    public func rpoplpush(source: String, destination: String) -> Future<RedisData> {
        return command("RPOPLPUSH", [RedisData(bulk: source), RedisData(bulk: destination)])
    }

    /// Select the Redis logical database having the specified zero-based numeric index.
    /// New connections always use the database 0.
    ///
    ///     let res = try redis.select(42).wait()
    ///
    /// https://redis.io/commands/select
    public func select(_ database: Int) -> Future<String> {
        return command("SELECT", [RedisData(bulk: database.description)]).map { data in
            switch data.storage {
            case .basicString(let string): return string
            default: throw RedisError(identifier: "select", reason: "Unexpected response: \(data).")
            }
        }
    }
}
