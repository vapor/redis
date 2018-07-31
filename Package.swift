// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Redis",
    products: [
        .library(name: "Redis", targets: ["Redis"])
    ],
    dependencies: [
      // 🌎 Utility package containing tools for byte manipulation, Codable, OS APIs, and debugging.
      .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),

        // Core services for creating database integrations.
        .package(url: "https://github.com/vapor/database-kit.git", from: "1.0.0")
    ],
    targets: [
      .target(name: "Redis", dependencies: ["Async", "Bits", "DatabaseKit", "Debugging", "COperatingSystem"]),
        .testTarget(name: "RedisTests", dependencies: ["Redis"])
    ]
)
