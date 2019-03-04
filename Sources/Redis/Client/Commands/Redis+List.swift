// MARK: List commands
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

    /// Removes and returns the last element of the list stored at key.
    public func lpop(_ list: String) -> Future<RedisData> {
        return command("LPOP", [RedisData(bulk: list)])
    }

    /// Removes the first count occurrences of elements equal to value from the list
    /// stored at key.
    ///
    /// https://redis.io/commands/LREM
    public func lrem(_ list: String, count: Int, value: RedisData) -> Future<Int> {
        return command("LREM", [RedisData(bulk: list), RedisData(bulk: String(count)), value]).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "lrem", reason: "Could not convert resp to int.")
            }
            return value
        }
    }

    /// Atomically returns and removes the last element (tail) of the list stored at source,
    /// and pushes the element at the first element (head) of the list stored at destination.
    public func rpoplpush(source: String, destination: String) -> Future<RedisData> {
        return command("RPOPLPUSH", [RedisData(bulk: source), RedisData(bulk: destination)])
    }

    /// BLPOP is a blocking list pop primitive. It is the blocking version of LPOP because
    /// it blocks the connection when there are no elements to pop from any of the given lists
    ///
    /// https://redis.io/commands/blpop
    public func blpop(_ lists: [String], timeout: Int = 0) -> Future<(String, RedisData)?>{
        let args = lists.map { RedisData(bulk: $0) } + [RedisData(bulk: String(timeout))]

        return command("BLPOP", args).map(to: (String, RedisData)?.self) { data in
            if data.isNull {
                return nil
            }

            guard let value = data.array else {
                throw RedisError(identifier: "blpop", reason: "Could not convert resp to array.")
            }
            return (value[0].string ?? "", value[1])
        }
    }

    /// BRPOP is a blocking list pop primitive. It is the blocking version of RPOP because it
    /// blocks the connection when there are no elements to pop from any of the given lists.
    ///
    /// https://redis.io/commands/brpop
    public func brpop(_ lists: [String], timeout: Int = 0) -> Future<(String, RedisData)?>{
        let args = lists.map { RedisData(bulk: $0) } + [RedisData(bulk: String(timeout))]

        return command("BRPOP", args).map(to: (String, RedisData)?.self) { data in
            if data.isNull {
                return nil
            }

            guard let value = data.array else {
                throw RedisError(identifier: "brpop", reason: "Could not convert resp to array.")
            }
            return (value[0].string ?? "", value[1])
        }
    }

    /// BRPOPLPUSH is the blocking variant of RPOPLPUSH. When source contains elements, this
    /// command behaves exactly like RPOPLPUSH
    ///
    /// https://redis.io/commands/brpoplpush
    public func brpoplpush(_ source: String, _ dest: String, timeout: Int = 0) -> Future<RedisData>{
        let args = [RedisData(bulk: source), RedisData(bulk: dest), RedisData(bulk: String(timeout))]
        return command("BRPOPLPUSH", args)
    }


}
