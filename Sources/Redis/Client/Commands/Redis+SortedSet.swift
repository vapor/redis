// MARK: Sorted Set commands
extension RedisClient {
    /// Adds all the specified members with the specified scores
    /// to the sorted set stored at key
    ///
    /// https://redis.io/commands/zadd
    public func zadd(_ key: String, items: [(String, RedisData)], options: [String] = []) -> Future<Int> {
        var args = [RedisData(bulk: key)] + options.map { RedisData(bulk: $0) }
        for (score, member) in items {
            args.append(RedisData(bulk: score))
            args.append(member)
        }

        return command("ZADD", args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "zadd", reason: "Could not convert resp to int.")
            }
            return value
        }
    }

    /// Returns the number of elements in the sorted set at key with
    /// a score between min and max.
    ///
    /// https://redis.io/commands/zcount
    public func zcount(_ key: String, min: String, max: String) -> Future<Int> {
        let args = [RedisData(bulk: key), RedisData(bulk: min), RedisData(bulk: max)]

        return command("ZCOUNT", args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "zcount", reason: "Could not convert resp to int.")
            }
            return value
        }
    }

    /// Returns the specified range of elements in the sorted set stored
    /// at key.
    ///
    /// https://redis.io/commands/zrange
    public func zrange(_ key: String, start: Int, stop: Int, withScores: Bool = false) -> Future<[RedisData]> {
        var args = [RedisData(bulk: key), RedisData(bulk: String(start)), RedisData(bulk: String(stop))]
        if withScores { args.append(RedisData(bulk: "WITHSCORES")) }

        return command("ZRANGE", args).map(to: [RedisData].self) { data in
            guard let value = data.array else {
                throw RedisError(identifier: "zrange", reason: "Could not convert resp to array.")
            }
            return value
        }
    }

    /// Returns all the elements in the sorted set at key with a score between
    /// min and max (including elements with score equal to min or max)
    ///
    /// https://redis.io/commands/zrangebyscore
    public func zrangebyscore(_ key: String, min: String, max: String, withScores: Bool = false, limit: (Int, Int)?=nil) -> Future<[RedisData]> {
        var args = [RedisData(bulk: key), RedisData(bulk: min), RedisData(bulk: max)]
        if withScores { args.append(RedisData(bulk: "WITHSCORES")) }
        if let limit = limit { args += [RedisData(bulk: "LIMIT"), RedisData(bulk: String(limit.0)), RedisData(bulk: String(limit.1))] }

        return command("ZRANGEBYSCORE", args).map(to: [RedisData].self) { data in
            guard let value = data.array else {
                throw RedisError(identifier: "zrange", reason: "Could not convert resp to array.")
            }
            return value
        }
    }

    /// Removes the specified members from the sorted set stored at key. Non existing
    /// members are ignored.
    ///
    /// https://redis.io/commands/zrem
    public func zrem(_ key: String, members: [RedisData]) -> Future<Int> {
        let args = [RedisData(bulk: key)] + members
        return command("ZREM", args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "zrem", reason: "Could not convert resp to int.")
            }
            return value
        }
    }
}

