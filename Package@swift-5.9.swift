// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "redis",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
    ],
    products: [
        .library(name: "Redis", targets: ["Redis"]),
        .library(name: "XCTRedis", targets: ["XCTRedis"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/RediStack.git", from: "1.4.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.100.0"),
    ],
    targets: [
        .target(
            name: "Redis",
            dependencies: [
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "Vapor", package: "vapor"),
            ],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency=complete")]
        ),
        .target(
            name: "XCTRedis",
            dependencies: [
                .target(name: "Redis"),
            ],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency=complete")]
        ),
        .testTarget(
            name: "RedisTests",
            dependencies: [
                .target(name: "Redis"),
                .target(name: "XCTRedis"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: [.enableExperimentalFeature("StrictConcurrency=complete")]
        ),
    ]
)
