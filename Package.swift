// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Redis",
    products: [
        .library(name: "Redis", targets: ["Redis"]),
    ],
    dependencies: [
        // Swift Promises, Futures, and Streams.
        .package(url: "https://github.com/vapor/async.git", .branch("beta")),

        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", .branch("beta")),

        // Non-blocking networking for Swift (HTTP and WebSockets).
        .package(url: "https://github.com/vapor/engine.git", .branch("beta")),

        // Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", .branch("keyed-cache")),
    ],
    targets: [
        .target(name: "Redis", dependencies: ["Async", "Bits", "DatabaseKit", "Debugging", "TCP"]),
        .testTarget(name: "RedisTests", dependencies: ["Redis"]),
    ]
)
