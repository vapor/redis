import Vapor
@preconcurrency import RediStack

extension Application.Redis {
    private struct PubSubKey: StorageKey, LockKey {
        typealias Value = [RedisID: RedisClient & Sendable]
    }

    var pubsubClient: RedisClient {
        if let existing = self.application.storage[PubSubKey.self]?[self.id] {
            return existing
        } else {
            let lock = self.application.locks.lock(for: PubSubKey.self)
            lock.lock()
            defer { lock.unlock() }

            let pool = self.pool(for: self.eventLoop.next())

            if let existingStorage = self.application.storage[PubSubKey.self] {
                var copy = existingStorage
                copy[self.id] = pool
                self.application.storage.set(PubSubKey.self, to: copy)
            } else {
                self.application.storage.set(PubSubKey.self, to: [self.id: pool])
            }
            return pool
        }
    }
}
