import PackageDescription

let package = Package(
    name: "Redis",
    dependencies: [
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .Package(url: "https://github.com/vapor/core.git", majorVersion: 2),

        // A formatted data encapsulation meant to facilitate the transformation from one object to another.
        .Package(url: "https://github.com/vapor/node.git", majorVersion: 2),

        // Pure-Swift Sockets: TCP, UDP; Client, Server; Linux, OS X.
        .Package(url: "https://github.com/vapor/sockets.git", majorVersion: 2),

        // Module for generating random bytes and numbers (for tests).
        .Package(url: "https://github.com/vapor/random.git", majorVersion: 1),

		// Secure sockets
		.Package(url: "https://github.com/vapor/tls.git", majorVersion: 2)
    ]
)
