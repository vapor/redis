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
            do {
                try redisStorage.shutdown(application: application).wait()
            } catch {
                application.logger.error("Error shutting down redis connection pools, possibly because the pool never connected to the Redis server: \(error)")
            }
        }

        func shutdownAsync(_ application: Application) async {
            do {
                try await redisStorage.shutdown(application: application).get()
            } catch {
                application.logger.error("Error shutting down redis connection pools, possibly because the pool never connected to the Redis server: \(error)")
            }
        }
    }
}
