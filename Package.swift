import PackageDescription

let package = Package(
	name: "Redbird",
	targets: [
		Target(name: "Redbird"),
		// Target(name: "RedbirdExample", dependencies: ["Redbird"])
	],
	dependencies: [
		.Package(url: "https://github.com/vapor/socks.git", majorVersion: 1)
	],
	exclude: [
        "Sources/RedbirdExample"
	]
)
