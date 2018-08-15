import Foundation
import DatabaseKit

extension RedisDatabase: KeyedCacheSupporting {
    /// See `KeyedCacheSupporting`.
    public static func keyedCacheGet<D>(_ key: String, as decodable: D.Type, on conn: RedisClient) throws -> EventLoopFuture<D?> where D : Decodable {
        return conn.jsonGet(key, as: decodable)
    }

    /// See `KeyedCacheSupporting`.
    public static func keyedCacheSet<E>(_ key: String, to encodable: E, on conn: RedisClient) throws -> EventLoopFuture<Void> where E : Encodable {
        return conn.jsonSet(key, to: encodable)
    }

    /// See `KeyedCacheSupporting`.
    public static func keyedCacheRemove(_ key: String, on conn: RedisClient) throws -> EventLoopFuture<Void> {
        return conn.delete(key)
    }
}
