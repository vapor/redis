import Redis
import Vapor
import XCTest

// Common base for stubbing responses since at runtime we will have as many instances as many event loops.
public class ArrayTestRedisClient {
    public typealias Item = Result<RESPValue, Error>

    private(set) var results: [Item] = []
    private(set) var publishers: [String: RedisSubscriptionMessageReceiver] = [:]
    private(set) var unSubscriptions: [String: RedisSubscriptionChangeHandler] = [:]

    public init() {}

    public enum TestError: Swift.Error {
        case outOfResponses
        case unsupported
    }

    deinit {
        XCTAssert(results.isEmpty)
    }

    public func prepare(with item: Result<RESPValue, Error>) {
        results.append(item)
    }

    public func prepare(error: Error?) {
        switch error {
        case let .some(value):
            results.append(.failure(value))
        case .none:
            results.append(.success(.null))
        }
    }

    var next: Item {
        results.isEmpty ? .failure(TestError.outOfResponses) : results.removeFirst()
    }

    func subscribe(
        matching values: [String],
        publisher: @escaping RedisSubscriptionMessageReceiver,
        subHandler: RedisSubscriptionChangeHandler?,
        unSubHandler: RedisSubscriptionChangeHandler?
    ) {
        for value in values {
            publishers[value] = publisher
            unSubscriptions[value] = unSubHandler
            subHandler?(value, 1)
        }
    }

    func unsubscribe(
        matching values: [String]
    ) {
        for value in values {
            publishers[value] = nil
            unSubscriptions[value]?(value, 0)
            unSubscriptions[value] = nil
        }
    }

    func yield(with arguments: [RESPValue]) {
        let channel = arguments[0].string!
        let message = arguments[1]

        publishers[channel]?(.init(channel), message)
    }
}
