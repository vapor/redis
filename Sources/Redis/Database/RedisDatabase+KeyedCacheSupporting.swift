import Foundation
import DatabaseKit

extension RedisDatabase: KeyedCacheSupporting {
    /// See `KeyedCacheSupporting`.
    public static func keyedCacheGet<D>(_ key: String, as decodable: D.Type, on conn: RedisClient) throws -> EventLoopFuture<D?> where D : Decodable {
        return conn.jsonGet(key, as: _DWrapper<D>.self).map { $0?.data }
    }

    /// See `KeyedCacheSupporting`.
    public static func keyedCacheSet<E>(_ key: String, to encodable: E, on conn: RedisClient) throws -> EventLoopFuture<Void> where E : Encodable {
        return conn.jsonSet(key, to: _EWrapper(encodable))
    }

    /// See `KeyedCacheSupporting`.
    public static func keyedCacheRemove(_ key: String, on conn: RedisClient) throws -> EventLoopFuture<Void> {
        return conn.delete(key)
    }
}


private struct _EWrapper<T>: Encodable where T: Encodable {
    var data: T
    init(_ data: T) { self.data = data }
}
private struct _DWrapper<T>: Decodable where T: Decodable {
    var data: T
    init(_ data: T) { self.data = data }
}
