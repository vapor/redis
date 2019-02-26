

/// Hash commands
extension RedisClient {
    
    
    /// Returns all field names in the hash stored at key.
    /// - Returns: Array reply: list of fields in the hash, or an empty list when key does not exist.
    public func hkeys(_ key: String) -> Future<[String]> {
        // HKEYS key
        let args = [RedisData(bulk: key)]
        // first get array of fields
        return command("HKEYS", args)
            .map(to: [RedisData].self, { data in
                guard let array = data.array else {
                    throw RedisError(identifier: "hkeys", reason: "Could not convert resp to array.")
                }
                return array
            })
            // then convert to strings
            .map({ array in
                try array.map({ try String.convertFromRedisData($0) })
            })
    }
    
    /// Returns the value associated with field in the hash stored at key as a `RedisDataConvertible` type.
    /// - Returns: the value associated with field, or nil when field is not present in the hash or key does not exist.
    public func hget<D>(_ key: String, field: String, as type: D.Type) -> Future<D?> where D: RedisDataConvertible {
        return hget(key, field: field).map(to: D?.self) { data in
            if data.isNull {
                return nil
            } else {
                return try D.convertFromRedisData(data)
            }
        }
    }
    
    /// Returns the value associated with field in the hash stored at key.
    /// - Returns: the value associated with field, or nil when field is not present in the hash or key does not exist.
    public func hget(_ key: String, field: String) -> Future<RedisData> {
        // HGET key field
        let args = [RedisData(bulk: key), RedisData(bulk: field)]
        return command("HGET", args)
    }
    
    /// Returns all values in the hash stored at key.
    /// - Returns: Dictionary of fields/values in the hash
    public func hgetall(_ key: String) -> Future<[String:RedisData]> {
        // HGETALL key
        let args = [RedisData(bulk: key)]
        
        return command("HGETALL", args)
            // Returns all fields and values of the hash stored at key. In the returned value, every field name is followed by its value, so the length of the reply is twice the size of the hash.
            .map(to: [RedisData].self, { data in
                guard let array = data.array else {
                    throw RedisError(identifier: "hgetall", reason: "Could not convert resp to array.")
                }
                return array
            })
            // transform to dictionary key:value
            .map({ array -> [String:RedisData] in
                var dictionary = Dictionary<String, RedisData>()
                var array = array
                
                // while at least 2 elements
                while array.count > 1 {
                    // first element is the key
                    let key = try String.convertFromRedisData(array.remove(at: 0))
                    let value = array.remove(at: 0)
                    dictionary[key] = value
                }
                
                return dictionary
            })
    }
    
    
    /// Sets field in the hash stored at key to a value. If key does not exist, a new key holding a hash is created. If field already exists in the hash, it is overwritten.
    /// - Returns: 1 if field is a new field in the hash and value was set, 0 if field already exists in the hash and the value was updated.
    public func hset<E>(_ key: String, field: String, to data: E) -> Future<Int> where E: RedisDataConvertible {
        do {
            let data = try data.convertToRedisData()
            return hset(key, field: field, to: data)
        } catch {
            return eventLoop.newFailedFuture(error: error)
        }
    }
    
    /// Sets field in the hash stored at key to a `RedisData` type. If key does not exist, a new key holding a hash is created. If field already exists in the hash, it is overwritten.
    /// - Returns: 1 if field is a new field in the hash and value was set, 0 if field already exists in the hash and the value was updated.
    public func hset(_ key: String, field: String, to data: RedisData) -> Future<Int> {
        // HSET key field value
        let args = [RedisData(bulk: key), RedisData(bulk: field), data]
        return command("HSET", args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "hset", reason: "Could not convert resp to int.")
            }
            return value
        }
    }
    
    
    /// Removes the specified fields from the hash stored at key. Specified fields that do not exist within this hash are ignored.
    public func hdel(_ key: String, fields: String...) -> Future<Int> {
        // HDEL key field [field ...]
        return hdel(key, fields: fields)
    }
    
    /// Removes the specified fields from the hash stored at key. Specified fields that do not exist within this hash are ignored.
    /// - Returns: Integer reply: the number of fields that were removed from the hash, not including specified but non existing fields. If key does not exist, it is treated as an empty hash and this command returns 0.
    public func hdel(_ key: String, fields: [String]) -> Future<Int> {
        // HDEL key field [field ...]
        var args = [RedisData(bulk: key)]
        args.append(contentsOf: fields.map(RedisData.init(bulk:)))
        
        let resp = command("HDEL", args).map(to: Int.self) { data in
            guard let value = data.int else {
                throw RedisError(identifier: "hdel", reason: "Could not convert resp to int.")
            }
            return value
        }
        return resp
    }
    
    
    /// Returns if field is an existing field in the hash stored at key.
    /// - Returns: 1 if the hash contains field. 0 if the hash does not contain field, or key does not exist.
    public func hexists(_ key: String, field: String) -> Future<Bool> {
        // HEXISTS key field
        let args = [RedisData(bulk: key), RedisData(bulk: field)]
        return command("HEXISTS", args)
            .map(to: Bool.self) { data in
                guard let value = data.int else {
                    throw RedisError(identifier: "hexists", reason: "Could not convert resp to int.")
                }
                return value != 0
        }
    }
    
}
