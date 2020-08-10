import Vapor

extension Request {
    public var redis: Redis {
        .init(request: self)
    }

    public struct Redis {
        let request: Request
    }
}

extension Request.Redis: RedisClient {
    public var eventLoop: EventLoop {
        self.request.eventLoop
    }

    public func logging(to logger: Logger) -> RedisClient {
        self.request.application.redis
            .pool(for: self.eventLoop)
            .logging(to: logger)
    }

    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.request.application.redis
            .pool(for: self.eventLoop)
            .logging(to: self.request.logger)
            .send(command: command, with: arguments)
            .hop(to: self.eventLoop)
    }
}
