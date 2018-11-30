extension RedisClient {
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
        let resp = command("EXPIRE", [RedisData(stringLiteral: key), RedisData(bulk: deadline.description)])
            .map(to: Int.self) { data in
                guard let value = data.int else {
                    throw RedisError(identifier: "expire", reason: "Could not convert resp to int")
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
