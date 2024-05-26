import Redis
import Vapor

final class DummyRedis {
    typealias TestError = ArrayTestRedisClient.TestError

    private let client: ArrayTestRedisClient
    let eventLoop: EventLoop

    init(client: ArrayTestRedisClient, eventLoop: EventLoop) {
        self.client = client
        self.eventLoop = eventLoop
    }
}

extension DummyRedis: RedisClient {
    func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        switch client.next {
        case let .success(value):
            return eventLoop.makeSucceededFuture(value)
        case let .failure(error):
            return eventLoop.makeFailedFuture(error)
        }
    }

    func subscribe(
        to channels: [RedisChannelName],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        eventLoop.makeFailedFuture(TestError.unsupported)
    }

    func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        eventLoop.makeFailedFuture(TestError.unsupported)
    }

    func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        eventLoop.makeFailedFuture(TestError.unsupported)
    }

    func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        eventLoop.makeFailedFuture(TestError.unsupported)
    }

    func logging(to logger: Logging.Logger) -> RediStack.RedisClient { return self }
}
