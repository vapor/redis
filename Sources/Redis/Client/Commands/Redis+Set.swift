// MARK: Set commands
extension RedisClient {
    /// Returns the all of the elements of the set stored at key.
    ///
    /// https://redis.io/commands/smembers
    public func smembers(_ key: String) -> Future<RedisData> {
        return command("SMEMBERS", [RedisData(bulk: key)])
    }

    /// Checks if the provided item is included in the set stored at key.
    ///
    /// https://redis.io/commands/sismember
    public func sismember(_ key: String, item: RedisData) -> Future<Bool> {
        return command("SISMEMBER", [RedisData(bulk: key), item])
            .map {
                guard let result = $0.int else {
                    throw RedisError(identifier: #function, reason: "Failed to convert resp to int.")
                }
                return result > 0
            }
    }

    /// Returns the total count of elements in the set stored at key.
    ///
    /// https://redis.io/commands/scard
    public func scard(_ key: String) -> Future<Int> {
        return command("SCARD", [RedisData(bulk: key)])
            .map {
                guard let count = $0.int else {
                    throw RedisError(identifier: #function, reason: "Failed to convert resp to int.")
                }
                return count
            }
    }

    /// Adds the provided items to the set stored at key, returning the count of items added.
    ///
    /// https://redis.io/commands/sadd
    public func sadd(_ key: String, items: [RedisData]) -> Future<Int> {
        return command("SADD", [RedisData(bulk: key)] + items)
            .map {
                guard let result = $0.int else {
                    throw RedisError(identifier: #function, reason: "Failed to convert resp to int.")
                }
                return result
            }
    }

    /// Removes the provided items from the set stored at key, returning the count of items removed.
    ///
    /// https://redis.io/commands/srem
    public func srem(_ key: String, items: [RedisData]) -> Future<Int> {
        return command("SREM", [RedisData(bulk: key)] + items)
            .map {
                guard let result = $0.int else { 
                    throw RedisError(identifier: #function, reason: "Failed to convert resp to int.")
                }
                return result
            }
    }

    /// Randomly selects an item from the set stored at key, and removes it.
    ///
    /// https://redis.io/commands/spop
    public func spop(_ key: String) -> Future<RedisData> {
        return command("SPOP", [RedisData(bulk: key)])
    }

    /// Randomly selects elements from the set stored at string, up to the `count` provided.
    ///  Use the `array` property to access the underlying values.
    ///
    ///     redis.srandmember("vapor") // pulls just one random element
    ///     redis.srandmember("vapor", max: -3) // pulls up to 3 elements, possibly duplicates
    ///     redis.srandmember("vapor", max: 3) // pulls up to 3 elements, guaranteed unique
    ///
    /// https://redis.io/commands/srem
    public func srandmember(_ key: String, max count: Int = 1) -> Future<RedisData> {
        precondition(count != 0, "A count of zero is a nonsense noop for selecting a random element")
        return command("SRANDMEMBER", [RedisData(bulk: key), RedisData(bulk: count.description)])
    }
}
