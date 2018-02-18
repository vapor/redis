// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "Redis",
  products: [
    .library(name: "Redis", targets: ["Redis"]),
  ],
  dependencies: [
    // Swift Promises, Futures, and Streams.
    .package(url: "https://github.com/vapor/async.git",  "1.0.0-beta.1"..<"1.0.0-beta.1.1"),

    // Core extensions, type-aliases, and functions that facilitate common tasks.
    .package(url: "https://github.com/vapor/core.git", "3.0.0-beta.1"..<"3.0.0-beta.1.1"),

    // Non-blocking networking for Swift.
    .package(url: "https://github.com/vapor/sockets.git", "3.0.0-beta.1"..<"3.0.0-beta.2.1"),

    // Core services for creating database integrations.
    .package(url: "https://github.com/vapor/database-kit.git", "1.0.0-beta.1"..<"1.0.0-beta.3"),
  ],
  targets: [
    .target(name: "Redis", dependencies: ["Async", "Bits", "DatabaseKit", "Debugging", "TCP"]),
    .testTarget(name: "RedisTests", dependencies: ["Redis"]),
  ]
)
