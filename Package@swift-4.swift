// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Redis",
    products: [
        .library(name: "Redis", targets: ["Redis"]),
    ],
    dependencies: [
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .package(url: "https://github.com/vapor/core.git", from: "2.1.0"),

        // A formatted data encapsulation meant to facilitate the transformation from one object to another.
        .package(url: "https://github.com/vapor/node.git", from: "2.1.0"),

        // Pure-Swift Sockets: TCP, UDP; Client, Server; Linux, OS X.
        .package(url: "https://github.com/vapor/sockets.git", from: "2.1.0"),

        // Module for generating random bytes and numbers (for tests).
        .package(url: "https://github.com/vapor/random.git", from: "1.2.0"),

        // Secure sockets
        .package(url: "https://github.com/vapor/tls.git", from: "2.1.0")
    ],
    targets: [
        .target(name: "Redis", dependencies: ["Core", "Node", "Sockets", "Random", "TLS"]),
        .testTarget(name: "RedisTests", dependencies: ["Redis"])
    ]
)
