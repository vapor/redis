import Foundation

public extension RedisClient {
    /// Creates a new reference to a Redis Set of data that supports additional commands.
    /// - Parameter fromKey: The string identifiying key to reference in the Redis instance.
    /// - Parameter ofType: The `RedisDataConvertible` type to expect all data in this set to be.
    public func createSetReference<T>(fromKey key: String, ofType: T.Type) -> RedisSet<T> {
        return RedisSet(identifier: key, client: self)
    }

    /// Creates a new reference to a Redis Set of data that supports additional commands, with the elements treated
    /// as the same type as the collection `Element`.
    /// - Example
    ///
    ///     request.newConnection(to: .redis) { client in
    ///         let set = client.createSetReference(fromKey: "set_key", ofType: [Int].self) // Set.Element will be Int
    ///     }
    ///
    /// - Parameter fromKey: The string identifiying key to reference in the Redis instance.
    /// - Parameter ofType: The `Collection` type to base the `RedisSet.Element` from.
    public func createSetReference<C>(fromKey key: String, ofType: C.Type) -> RedisSet<C.Element>
        where C: Collection, C.Element: RedisDataConvertible
    {
        return RedisSet(identifier: key, client: self)
    }
}

/// A reference to a homgenous Redis Set of data.
/// - Seealso: https://redis.io/topics/data-types-intro#redis-sets
public struct RedisSet<Element: RedisDataConvertible> {
    private let id: RedisData
    private let client: RedisClient

    public init(identifier: String, client: RedisClient) {
        self.id = RedisData(bulk: identifier)
        self.client = client
    }

    /// Returns the full set as the expected `Element` type.
    public func getAll() -> Future<[Element]?> {
        return client.command("SMEMBERS", [id])
            .map { data in
                guard let set = data.array else { return nil }
                return try set.map { try Element.convertFromRedisData($0) }
            }
    }

    /// Checks if the set contains the single data element.
    public func contains(_ data: RedisData) -> Future<Bool> {
        return client.command("SISMEMBER", [id, data])
            .map {
                guard let result = $0.int else { return false }
                return result > 0
            }
    }

    /// Inserts the collection of `RedisData` into the Set.
    /// - Note: If the set already contains one of the items in the collection, it will not be inserted.
    /// - Important: The future will resolve `true` if at least one item was inserted.
    public func insert(_ data: [RedisData]) -> Future<Bool> {
        return client.command("SADD", [id] + data)
            .map {
                guard let count = $0.int else { return false }
                return count > 0
            }
    }

    /// Removes the collection of `RedisData` from the Set.
    /// - Important: The future will resolve `true` if at least one item was removed.
    public func remove(_ data: [RedisData]) -> Future<Bool> {
        return client.command("SREM", [id] + data)
            .map {
                guard let count = $0.int else { return false }
                return count > 0
            }
    }

}

extension RedisSet {
    /// Attempts to convert the provided element into a `RedisData` object before calling the non-generic `RedisSet.contains(_:)`.
    /// - Throws:
    ///     - `RedisError`
    public func contains<E: RedisDataConvertible>(_ element: E) throws -> Future<Bool> {
        let data = try convert(element)
        return self.contains(data)
    }

    /// Attempts to convert the provided element into a `RedisData` object before calling the non-generic `RedisSet.insert(_:)`.
    /// - Throws:
    ///     - `RedisError`
    public func insert<E: RedisDataConvertible>(_ elements: E...) throws -> Future<Bool> {
        let data = try convert(elements)
        return insert(data)
    }

    /// Attempts to convert the provided element into a `RedisData` object before calling the non-generic `RedisSet.remove(_:)`.
    /// - Throws:
    ///     - `RedisError`
    public func remove<E: RedisDataConvertible>(_ elements: E...) throws -> Future<Bool> {
        let data = try convert(elements)
        return remove(data)
    }

    private func convert<E: RedisDataConvertible>(_ element: E) throws -> RedisData {
        do {
            return try element.convertToRedisData()
        } catch {
            throw RedisError(identifier: "Set Element", reason: "Failed to convert element to RedisData: \(element)")
        }
    }

    private func convert<E: RedisDataConvertible>(_ elements: [E]) throws -> [RedisData] {
        return try elements.map { try convert($0) }
    }
}
