// swift-tools-version:5.6
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
        .library(name: "Redis", targets: ["Redis"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/RediStack.git", from: "1.4.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.77.1"),
    ],
    targets: [
        .target(
            name: "Redis",
            dependencies: [
                .product(name: "RediStack", package: "RediStack"),
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(name: "RedisTests", dependencies: [
            .target(name: "Redis"),
            .product(name: "XCTVapor", package: "vapor"),
        ])
    ]
)
