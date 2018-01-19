import Foundation

public protocol RedisDataConvertible {
    static func convertFromRedisData(_ data: RedisData) throws -> Self
    func convertToRedisData() throws -> RedisData
}

extension String: RedisDataConvertible {
    /// See `RedisDataConvertible.convertFromRedisData(_:)`
    public static func convertFromRedisData(_ data: RedisData) throws -> String {
        guard let string = data.string else {
            throw RedisError(identifier: "string", reason: "Could not convert to string: \(data)")
        }
        return string
    }

    /// See `RedisDataConvertible.convertToRedisData()`
    public func convertToRedisData() throws -> RedisData {
        return .bulkString(Data(self.utf8))
    }
}

extension FixedWidthInteger {
    /// See `RedisDataConvertible.convertFromRedisData(_:)`
    public static func convertFromRedisData(_ data: RedisData) throws -> Self {
        guard let int = data.int else {
            throw RedisError(identifier: "int", reason: "Could not convert to int: \(data)")
        }
        return Self(int)
    }

    /// See `RedisDataConvertible.convertToRedisData()`
    public func convertToRedisData() throws -> RedisData {
        return .bulkString(Data(self.description.utf8))
    }
}

extension Int: RedisDataConvertible {}
extension Int8: RedisDataConvertible {}
extension Int16: RedisDataConvertible {}
extension Int32: RedisDataConvertible {}
extension Int64: RedisDataConvertible {}
extension UInt: RedisDataConvertible {}
extension UInt8: RedisDataConvertible {}
extension UInt16: RedisDataConvertible {}
extension UInt32: RedisDataConvertible {}
extension UInt64: RedisDataConvertible {}

extension Double {
    /// See `RedisDataConvertible.convertFromRedisData(_:)`
    public static func convertFromRedisData(_ data: RedisData) throws -> Double {
        guard let string = data.string else {
            throw RedisError(identifier: "string", reason: "Could not convert to string: \(data)")
        }

        guard let float = Double(string) else {
            throw RedisError(identifier: "dobule", reason: "Could not convert to double: \(data)")
        }

        return float
    }

    /// See `RedisDataConvertible.convertToRedisData()`
    public func convertToRedisData() throws -> RedisData {
        return .bulkString(Data(self.description.utf8))
    }
}

extension Float {
    /// See `RedisDataConvertible.convertFromRedisData(_:)`
    public static func convertFromRedisData(_ data: RedisData) throws -> Float {
        guard let string = data.string else {
            throw RedisError(identifier: "string", reason: "Could not convert to string: \(data)")
        }

        guard let float = Float(string) else {
            throw RedisError(identifier: "float", reason: "Could not convert to float: \(data)")
        }

        return float
    }

    /// See `RedisDataConvertible.convertToRedisData()`
    public func convertToRedisData() throws -> RedisData {
        return .bulkString(Data(self.description.utf8))
    }
}

extension Data {
    /// See `RedisDataConvertible.convertFromRedisData(_:)`
    public static func convertFromRedisData(_ data: RedisData) throws -> Data {
        guard let d = data.data else {
            throw RedisError(identifier: "data", reason: "Could not convert to data: \(data)")
        }
        return d
    }

    /// See `RedisDataConvertible.convertToRedisData()`
    public func convertToRedisData() throws -> RedisData {
        return .bulkString(self)
    }
}
