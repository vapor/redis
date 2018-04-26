import Foundation
import DatabaseKit

extension RedisDatabase: KeyedCacheSupporting {
    public static func keyedCacheGet<D>(_ key: String, as decodable: D.Type, on conn: RedisClient) throws -> EventLoopFuture<D?> where D : Decodable {
        return conn.get(key, as: Data.self).map(to: D?.self) { data in
            guard let data = data, data.count > 0 else { return nil }
            let decoder = JSONDecoder()
            return try decoder.decode(decodable, from: data)
        }
    }

    public static func keyedCacheSet<E>(_ key: String, to encodable: E, on conn: RedisClient) throws -> EventLoopFuture<Void> where E : Encodable {
        let encoder = JSONEncoder()
        let data = try encoder.encode(encodable)
        return conn.set(key, to: data)
    }

    public static func keyedCacheRemove(_ key: String, on conn: RedisClient) throws -> EventLoopFuture<Void> {
        return conn.delete(key)
    }
}
