import Redis
import Vapor

extension RedisConfigurationFactory {
    struct RedisStub: RedisFactory {
        let client: ArrayTestRedisClient

        var configuration: RedisConfiguration {
            fatalError("A stub doesn't have a configuration.")
        }

        func makeClient(for eventLoop: EventLoop, logger: Logger) -> RediStack.RedisClient {
            let client = DummyRedis(client: client, eventLoop: eventLoop)
            return client
        }
    }

//    struct RedisPubSubStub: RedisFactory {
//        let client: ArrayTestRedisClient
//        
//        var configuration: RedisConfiguration {
//            fatalError("A stub doesn't have a configuration.")
//        }
//
//        func makeClient(for eventLoop: EventLoop, logger: Logger) -> RediStack.RedisClient {
//            let client = PubSubTestRedisClient(eventLoop: eventLoop)
//            return client
//        }
//    }

    public static func stub(client: ArrayTestRedisClient) -> Self {
        .init { RedisStub(client: client) }
    }

//    public static func pubSubStub(client: ArrayTestRedisClient) -> Self {
//        .init { RedisPubSubStub(client: client) }
//    }
}
