import Vapor

extension Application.Redis {
    /// The Redis configuration to use to communicate with a Redis instance.
    ///
    /// See `Application.Redis.id`
    public var configuration: RedisConfiguration? {
        get {
            self.application.redisStorage.configuration(for: self.id)
        }
        nonmutating set {
            guard let newConfig = newValue else {
                fatalError("Modifying configuration is not supported")
            }
            self.application.redisStorage.use(newConfig, as: self.id)
        }
    }

    /// Attempts to resolve any pending hostname resolutions.
    /// This can be used if hostname resolution failed during initial configuration
    /// and you want to retry after DNS becomes available
    ///
    /// This only updates the configuration and any existing connection pools are not affected.
    public func retryHostnameResolution() throws {
        try self.application.redisStorage.retryHostnameResolution(for: self.id)
    }

    /// Indicates whether this Redis configuration has unresolved hostnames
    public var hasUnresolvedHostname: Bool {
        return self.configuration?.hasUnresolvedHostname ?? false
    }
}
