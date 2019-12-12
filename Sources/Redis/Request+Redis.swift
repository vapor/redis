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
    public var logger: Logger? {
        self.request.logger
    }

    public var eventLoop: EventLoop {
        self.request.eventLoop
    }

    public func send(command: String, with arguments: [RESPValue]) -> EventLoopFuture<RESPValue> {
        self.request.application.redis.pool.withConnection(
            logger: logger,
            on: self.eventLoop
        ) {
            $0.send(command: command, with: arguments)
        }
    }
    
}
