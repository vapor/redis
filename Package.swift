// swift-tools-version:5.3
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
        .package(url: "https://gitlab.com/mordil/RediStack.git", .revisionItem("9da5773e7a45f3fc38293ae1d66849a3f9093f56")),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.50.0"),
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
