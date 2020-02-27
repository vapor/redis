// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "redis",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(name: "Redis", targets: ["Redis"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/redis-kit.git", from: "1.0.0-beta.3"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.4"),
    ],
    targets: [
      .target(name: "Redis", dependencies: ["RedisKit", "Vapor"]),
        .testTarget(name: "RedisTests", dependencies: ["Redis"])
    ]
)
