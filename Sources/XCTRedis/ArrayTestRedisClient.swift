import Redis
import Vapor
import XCTest

// Common base for stubbing responses
public class ArrayTestRedisClient {
    public typealias Item = Result<RESPValue, TestError>
    private(set) var results: [Item] // if necessary we can place it under mutex lock

    public enum TestError: Swift.Error {
        case outOfResponses
        case unsupported
    }

    public init(results: [Item] = []) {
        self.results = results
    }

    deinit {
        XCTAssert(results.isEmpty)
    }

    public func prepare(with item: Result<RESPValue, TestError>) {
        results.append(item)
    }

    public var next: Item {
        results.isEmpty ? .failure(TestError.outOfResponses) : results.removeFirst()
    }
}
