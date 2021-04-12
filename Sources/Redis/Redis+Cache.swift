import Vapor

extension Application.Caches {
    public var redis: Cache {
        self.redis(.default)
    }
  
    public func redis(_ id: RedisID) -> Cache {
        RedisCache(client: self.application.redis(id))
    }
}

extension Application.Caches.Provider {
    public static var redis: Self {
        self.redis(.default)
    }

    public static func redis(_ id: RedisID) -> Self {
        .init {
            $0.caches.use { $0.caches.redis(id) }
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

    func set<T>(_ key: String, to value: T?, expiresIn expirationTime: CacheExpirationTime?) -> EventLoopFuture<Void>
        where T: Encodable
    {
        if let value = value {
            if let expirationTime = expirationTime {
                return self.client.setex(RedisKey(key), toJSON: value, expirationInSeconds: expirationTime.seconds)
            } else {
                return self.client.set(RedisKey(key), toJSON: value)
            }
        } else {
            return self.client.delete(RedisKey(key))
                .transform(to: ())
        }
    }
    
    func set<T>(_ key: String, to value: T?) -> EventLoopFuture<Void> where T : Encodable {
        self.set(key, to: value, expiresIn: nil)
    }
    
    func `for`(_ request: Request) -> Self {
        .init(client: request.redis)
    }
}
