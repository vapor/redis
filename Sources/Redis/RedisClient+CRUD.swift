import Async

extension RedisClient {
    /// Stores the `value` at the key `key`
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/redis/basics/#creating-a-record)
    public func set(_ value: RedisData, forKey key: String) -> Future<RedisData> {
        return command("SET", [RedisData(bulk: key), value])
    }
    
    /// Removes the value at the key `key`
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/redis/basics/#deleting-a-record)
    @discardableResult
    public func delete(keys: [String]) -> Future<RedisData> {
        return command("DEL", keys.map { RedisData(bulk: $0) })
    }
    
    /// Fetches the value at the key `key`
    ///
    /// [Learn More →](https://docs.vapor.codes/3.0/redis/basics/#reading-a-record)
    public func get(forKey key: String) -> Future<RedisData> {
        return command("GET", [RedisData(bulk: key)])
    }
}
