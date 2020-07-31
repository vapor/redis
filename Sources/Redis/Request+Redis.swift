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
    public var isConnected: Bool { true }
    
    public var logger: Logger {
        self.request.logger
    }

    public var eventLoop: EventLoop {
        self.request.eventLoop
    }

    public func setLogging(to logger: Logger) {
        // cannot set logger
    }

    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.request.application.redis
            .pool(for: self.eventLoop)
            .logging(to: self.logger)
            .send(command: command, with: arguments)
            .hop(to: self.eventLoop)
    }
}
