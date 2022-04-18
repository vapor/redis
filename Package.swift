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
        .package(url: "https://gitlab.com/mordil/RediStack.git", .revision("7ed140732ef579674529b439b87f5cd7f39bdbc7")),
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
