// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "redis",
    products: [
        .library(name: "Redis", targets: ["Redis"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/redis-kit.git", .branch("nio-kit")),
        .package(url: "https://github.com/vapor/vapor.git", .branch("master")),
    ],
    targets: [
        .target(name: "Redis", dependencies: ["RedisKit", "Vapor"]),
        .testTarget(name: "RedisTests", dependencies: ["Redis"])
    ]
)
