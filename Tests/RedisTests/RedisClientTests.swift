import Foundation
@testable import Redis
import TCP
import XCTest

class RedisClientTests: XCTestCase {

    func testClientConfigParsesWithNoAuth() throws {
        let connectionString = "redis://pub-redis-redis.aws-compas-1-4.3.ec2.someEc2Thing.com:55595"

        let config = try RedisClientConfig(connectionString: connectionString)

        XCTAssertEqual(config.port, UInt16(55595))
        XCTAssertEqual(config.hostname, "pub-redis-redis.aws-compas-1-4.3.ec2.someEc2Thing.com")
    }

    func testClientConfigParsesWithUsername() throws {
        let connectionString = "redis://myUser:@pub-redis-redis.aws-compas-1-4.3.ec2.someEc2Thing.com:55595"

        let config = try RedisClientConfig(connectionString: connectionString)

        XCTAssertEqual(config.port, UInt16(55595))
        XCTAssertEqual(config.hostname, "myUser:@pub-redis-redis.aws-compas-1-4.3.ec2.someEc2Thing.com")
    }

    func testClientConfigParsesWithPassword() throws {
        let connectionString = "redis://:myPassword@pub-redis-redis.aws-compas-1-4.3.ec2.someEc2Thing.com:55595"

        let config = try RedisClientConfig(connectionString: connectionString)

        XCTAssertEqual(config.port, UInt16(55595))
        XCTAssertEqual(config.hostname, ":myPassword@pub-redis-redis.aws-compas-1-4.3.ec2.someEc2Thing.com")
    }

    func testClientConfigParsesWithAuth() throws {
        let connectionString = "redis://myUser:myPassword@pub-redis-redis.aws-compas-1-4.3.ec2.someEc2Thing.com:55595"

        let config = try RedisClientConfig(connectionString: connectionString)

        XCTAssertEqual(config.port, UInt16(55595))
        XCTAssertEqual(config.hostname, "myUser:myPassword@pub-redis-redis.aws-compas-1-4.3.ec2.someEc2Thing.com")
    }
}
