import Redis
import Vapor

final class DummyRedis: Sendable {
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
        if command == "PUBLISH" {
            client.yield(with: arguments)
        }

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
        psubscribe(
            to: channels.map(\.rawValue),
            messageReceiver: receiver,
            onSubscribe: subscribeHandler,
            onUnsubscribe: unsubscribeHandler
        )
    }

    func psubscribe(
        to patterns: [String],
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscriptionChangeHandler?,
        onUnsubscribe unsubscribeHandler: RedisSubscriptionChangeHandler?
    ) -> EventLoopFuture<Void> {
        client.subscribe(
            matching: patterns,
            publisher: receiver,
            subHandler: subscribeHandler,
            unSubHandler: unsubscribeHandler
        )

        switch client.next {
        case .success:
            return eventLoop.makeSucceededVoidFuture()
        case let .failure(error):
            return eventLoop.makeFailedFuture(error)
        }
    }

    func unsubscribe(from channels: [RedisChannelName]) -> EventLoopFuture<Void> {
        punsubscribe(from: channels.map(\.rawValue))
    }

    func punsubscribe(from patterns: [String]) -> EventLoopFuture<Void> {
        client.unsubscribe(matching: patterns)
        switch client.next {
        case .success:
            return eventLoop.makeSucceededVoidFuture()
        case let .failure(error):
            return eventLoop.makeFailedFuture(error)
        }
    }

    func logging(to logger: Logging.Logger) -> RediStack.RedisClient { return self }
}
