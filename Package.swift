// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Redis",
    products: [
        .library(name: "Redis", targets: ["Redis"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", .exact("1.0.0-beta.1")),

        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", .exact("3.0.0-beta.1")),

        // Non-blocking networking for Swift.
        .package(url: "https://github.com/vapor/sockets.git", .exact("3.0.0-beta.1")),

        // Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", .exact("1.0.0-beta.1")),
    ],
    targets: [
        .target(name: "Redis", dependencies: ["Async", "Bits", "DatabaseKit", "Debugging", "TCP"]),
        .testTarget(name: "RedisTests", dependencies: ["Redis"]),
    ]
)
