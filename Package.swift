// swift-tools-version:5.2
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
        .package(url: "https://github.com/vapor/redis-kit.git", .branch("redistack-alpha-8")),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-beta.4"),
    ],
    targets: [
        .target(
            name: "Redis",
            dependencies: [
                .product(name: "RedisKit", package: "redis-kit"),
                .product(name: "Vapor", package: "vapor")
            ]
        ),
        .testTarget(name: "RedisTests", dependencies: ["Redis"])
    ]
)
