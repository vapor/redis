import Async
import DatabaseKit
import Foundation

extension RedisClient: KeyedCache {
    /// See `KeyedCache.get(_:forKey)`
    public func get<D>(_ type: D.Type, forKey key: String) throws -> Future<D?>
        where D: Decodable
    {
        return command("GET", [RedisData(bulk: key)]).map(to: D?.self) { data in
            let entity: D
            if let convertible = type as? RedisDataConvertible.Type {
                entity = try convertible.convertFromRedisData(data) as! D
            } else {
                switch data.storage {
                case .bulkString(let d): entity = try JSONDecoder().decode(D.self, from: d)
                default: throw RedisError(identifier: "jsonData", reason: "Data type required to decode JSON.")
                }
            }
            return entity
        }
    }

    /// See `KeyedCache.set(_:forKey)`
    public func set<E>(_ entity: E, forKey key: String) throws -> Future<Void>
        where E: Encodable
    {
        return Future.flatMap {
            let data: RedisData
            if let convertible = entity as? RedisDataConvertible {
                data = try convertible.convertToRedisData()
            } else {
                data = try .bulkString(JSONEncoder().encode(entity))
            }
            switch data.storage {
            case .bulkString: break
            default: throw RedisError(identifier: "setData", reason: "Set data must be of type bulkString")
            }
            return self.command("SET", [RedisData(bulk: key), data]).transform(to: ())
        }
    }

    /// See `KeyedCache.remove`
    public func remove(_ key: String) throws -> Future<Void> {
        return command("DEL", [RedisData(bulk: key)]).transform(to: ())
    }
}
