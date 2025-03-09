import NIOConcurrencyHelpers
import Redis
import Vapor
import XCTest

// Common base for stubbing responses since at runtime we will have as many instances as many event loops.
public final class ArrayTestRedisClient: Sendable {
    public typealias Item = Result<RESPValue, Error>

    fileprivate struct StorageBox: @unchecked Sendable {
        var results: [Item] = []
        var publishers: [String: RedisSubscriptionMessageReceiver] = [:]
        var unSubscriptions: [String: RedisSubscriptionChangeHandler] = [:]
    }

    private let box: NIOLockedValueBox<StorageBox> = .init(.init())

    public init() {}

    public enum TestError: Swift.Error {
        case outOfResponses
        case unsupported
    }

    deinit {
        box.withLockedValue {
            XCTAssert($0.results.isEmpty)
        }
    }

    public func prepare(with item: Result<RESPValue, Error>) {
        box.withLockedValue {
            $0.results.append(item)
        }
    }

    public func prepare(error: Error?) {
        box.withLockedValue {
            switch error {
            case let .some(value):
                $0.results.append(.failure(value))
            case .none:
                $0.results.append(.success(.null))
            }
        }
    }

    var next: Item {
        box.withLockedValue {
            $0.results.isEmpty ? .failure(TestError.outOfResponses) : $0.results.removeFirst()
        }
    }

    func subscribe(
        matching values: [String],
        publisher: @escaping RedisSubscriptionMessageReceiver,
        subHandler: RedisSubscriptionChangeHandler?,
        unSubHandler: RedisSubscriptionChangeHandler?
    ) {
        box.withLockedValue {
            for value in values {
                $0.publishers[value] = publisher
                $0.unSubscriptions[value] = unSubHandler
            }
        }
        values.forEach({ subHandler?($0, 1) })
    }

    func unsubscribe(
        matching values: [String]
    ) {
        var unSubscriptions: [String: RedisSubscriptionChangeHandler] = [:]

        box.withLockedValue {
            for value in values {
                $0.publishers[value] = nil
                if let unSubscription = $0.unSubscriptions[value] {
                    unSubscriptions[value] = unSubscription
                }
                $0.unSubscriptions[value] = nil
            }
        }
        unSubscriptions.forEach({ $0.value($0.key, 0) })
    }

    func yield(with arguments: [RESPValue]) {
        let channel = arguments[0].string!
        let message = arguments[1]

        box.withLockedValue {
            $0.publishers[channel]
        }?(.init(channel), message)
    }
}
