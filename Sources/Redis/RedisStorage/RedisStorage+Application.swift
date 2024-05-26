import Vapor

extension Application {
    private struct RedisStorageKey: StorageKey {
        typealias Value = RedisStorage
    }

    var redisStorage: RedisStorage {
        if let existing = storage[RedisStorageKey.self] {
            return existing
        }

        let redisStorage = RedisStorage()
        storage[RedisStorageKey.self] = redisStorage
        lifecycle.use(RedisStorage.Lifecycle(redisStorage: redisStorage))
        return redisStorage
    }
}
