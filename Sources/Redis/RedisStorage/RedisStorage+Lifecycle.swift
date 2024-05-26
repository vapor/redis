import Vapor

extension RedisStorage {
    /// Lifecyle Handler for Redis Storage. On boot, it creates a RedisConnectionPool for each
    /// configurated `RedisID` on each `EventLoop`.
    final class Lifecycle: LifecycleHandler {
        unowned let redisStorage: RedisStorage
        init(redisStorage: RedisStorage) {
            self.redisStorage = redisStorage
        }

        /// Prepare each instance on each connection pool
        func didBoot(_ application: Application) throws {
            redisStorage.bootstrap(application: application)
        }

        /// Close each connection pool
        func shutdown(_ application: Application) {
            redisStorage.shutdown(application: application)
        }
    }
}
