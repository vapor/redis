#if canImport(_Concurrency)
import NIOCore
import Vapor

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension Application.Redis {
    public func send<CommandResult>(
        _ command: RedisCommand<CommandResult>,
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil
    ) async throws -> CommandResult {
        try await self.application.redis(self.id)
            .pool(for: self.eventLoop)
            .logging(to: self.application.logger)
            .send(command, eventLoop: eventLoop, logger: logger)
            .get()
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil,
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscribeHandler?,
        onUnsubscribe unsubscribeHandler: RedisUnsubscribeHandler?
    ) async throws {
        try await self.application.redis(self.id)
            .pubsubClient
            .logging(to: self.application.logger)
            .subscribe(to: channels, eventLoop: eventLoop, logger: logger, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
            .get()
    }
    
    public func unsubscribe(from channels: [RedisChannelName], eventLoop: EventLoop?, logger: Logger?) async throws {
        try await self.application.redis(self.id)
            .pubsubClient
            .logging(to: self.application.logger)
            .unsubscribe(from: channels, eventLoop: eventLoop, logger: logger)
            .get()
    }
    
    public func psubscribe(
        to patterns: [String],
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil,
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscribeHandler?,
        onUnsubscribe unsubscribeHandler: RedisUnsubscribeHandler?
    ) async throws {
        try await self.application.redis(self.id)
            .pubsubClient
            .logging(to: self.application.logger)
            .psubscribe(to: patterns, eventLoop: eventLoop, logger: logger, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
            .get()
    }
    
    public func punsubscribe(from patterns: [String], eventLoop: EventLoop? = nil, logger: Logger? = nil) async throws {
        try await self.application.redis(self.id)
            .pubsubClient
            .logging(to: self.application.logger)
            .punsubscribe(from: patterns, eventLoop: eventLoop, logger: logger)
            .get()
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension RedisClient {
    /// Gets the provided key as a decodable type.
    public func get<D>(_ key: RedisKey, asJSON type: D.Type) async throws -> D?
        where D: Decodable
    {
        let data = try await self.get(key, as: Data.self).get()
        return try data.flatMap { try JSONDecoder().decode(D.self, from: $0) }
    }

    /// Sets key to an encodable item.
    public func set<E>(_ key: RedisKey, toJSON entity: E) async throws
        where E: Encodable
    {
        try await self.set(key, to: JSONEncoder().encode(entity)).get()
    }
    
    /// Sets key to an encodable item with an expiration time.
    public func setex<E>(_ key: RedisKey, toJSON entity: E, expirationInSeconds expiration: Int) async throws
        where E: Encodable
    {
        try await self.send(.setex(key, to: JSONEncoder().encode(entity), expirationInSeconds: expiration), eventLoop: nil, logger: nil).get()
    }
}

@available(macOS 12, iOS 15, watchOS 8, tvOS 15, *)
extension Request.Redis {
    public func send<CommandResult>(
        _ command: RedisCommand<CommandResult>,
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil
    ) async throws -> CommandResult {
        try await self.request.application.redis(self.id)
            .pool(for: self.eventLoop)
            .logging(to: self.request.logger)
            .send(command, eventLoop: eventLoop, logger: logger)
            .get()
    }
    
    public func subscribe(
        to channels: [RedisChannelName],
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil,
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscribeHandler?,
        onUnsubscribe unsubscribeHandler: RedisUnsubscribeHandler?
    ) async throws {
        try await self.request.application.redis(self.id)
            .pubsubClient
            .logging(to: self.request.logger)
            .subscribe(to: channels, eventLoop: eventLoop, logger: logger, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
            .get()
    }
    
    public func unsubscribe(from channels: [RedisChannelName], eventLoop: EventLoop? = nil, logger: Logger? = nil) async throws {
        try await self.request.application.redis(self.id)
            .pubsubClient
            .logging(to: self.request.logger)
            .unsubscribe(from: channels, eventLoop: eventLoop, logger: logger)
            .get()
    }
    
    public func psubscribe(
        to patterns: [String],
        eventLoop: EventLoop? = nil,
        logger: Logger? = nil,
        messageReceiver receiver: @escaping RedisSubscriptionMessageReceiver,
        onSubscribe subscribeHandler: RedisSubscribeHandler?,
        onUnsubscribe unsubscribeHandler: RedisUnsubscribeHandler?
    ) async throws {
        try await self.request.application.redis(self.id)
            .pubsubClient
            .logging(to: self.request.logger)
            .psubscribe(to: patterns, eventLoop: eventLoop, logger: logger, messageReceiver: receiver, onSubscribe: subscribeHandler, onUnsubscribe: unsubscribeHandler)
            .get()
    }
    
    public func punsubscribe(from patterns: [String], eventLoop: EventLoop? = nil, logger: Logger? = nil) async throws {
        try await self.request.application.redis(self.id)
            .pubsubClient
            .logging(to: self.request.logger)
            .punsubscribe(from: patterns, eventLoop: eventLoop, logger: logger)
            .get()
    }
}

#endif
