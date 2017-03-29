import PackageDescription

let package = Package(
	name: "Redis",
	dependencies: [
        // Core extensions, type-aliases, and functions that facilitate common tasks.
        .Package(url: "https://github.com/vapor/core.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),

        // A formatted data encapsulation meant to facilitate the transformation from one object to another.
        .Package(url: "https://github.com/vapor/node.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),

        // Pure-Swift Sockets: TCP, UDP; Client, Server; Linux, OS X.
		.Package(url: "https://github.com/vapor/socks.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
		
		// Module for generating random bytes and numbers (for tests).
        .Package(url: "https://github.com/vapor/random.git", majorVersion: 0)
	]
)
