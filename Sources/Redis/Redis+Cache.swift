import Vapor

extension Application.Caches {
    public var redis: Cache {
        RedisCache(client: self.application.redis)
    }
}

extension Application.Caches.Provider {
    public static var redis: Self {
        .init {
            $0.caches.use { $0.caches.redis }
        }
    }
}

private struct RedisCache: Cache {
    let client: RedisClient
    
    init(client: RedisClient) {
        self.client = client
    }
    
    func get<T>(_ key: String, as type: T.Type) -> EventLoopFuture<T?>
        where T: Decodable
    {
        self.client.get(RedisKey(key), asJSON: T.self)
    }
    
    func set<T>(_ key: String, to value: T?) -> EventLoopFuture<Void>
        where T: Encodable
    
    {
        if let value = value {
            return self.client.set(RedisKey(key), toJSON: value)
        } else {
            return self.client.delete(RedisKey(key))
                .transform(to: ())
        }
    }
    
    func `for`(_ request: Request) -> Self {
        .init(client: request.redis)
    }
}
