import Async
import DatabaseKit

extension RedisClient: KeyedCache {
    /// See `KeyedCache.get(_:forKey)`
    public func get<D>(_ type: D.Type, forKey key: String) throws -> Future<D?>
        where D: Decodable
    {
        return self.get(forKey: key)
    }

    /// See `KeyedCache.set(_:forKey)`
    public func set(_ entity: Encodable, forKey key: String) throws -> Future<Void> {
        <#code#>
    }

    /// See `KeyedCache.remove`
    public func remove(_ key: String) throws -> Future<Void> {
        <#code#>
    }
}
