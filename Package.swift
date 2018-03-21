// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Redis",
    products: [
        .library(name: "Redis", targets: ["Redis"])
    ],
    dependencies: [
        // Core extensions, type-aliases, and functions that facilitate common tasks.
      .package(url: "https://github.com/vapor/core.git", from: "3.0.0-rc.2"),

        // Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", from: "1.0.0-rc.2"),

        // Event-driven network application framework for high performance protocol servers & clients, non-blocking.
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0")
    ],
    targets: [
      .target(name: "Redis", dependencies: ["Async", "Bits", "DatabaseKit", "Debugging", "NIO", "COperatingSystem"]),
        .testTarget(name: "RedisTests", dependencies: ["Redis"])
    ]
)
