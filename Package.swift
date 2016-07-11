import PackageDescription

let package = Package(
  name: "Redbird",
  dependencies: [
    .Package(url: "https://github.com/czechboy0/Socks.git", majorVersion: 0, minor: 8)
  ],
  targets: [
    Target(name: "Redbird"),
    Target(name: "RedbirdExample", dependencies: ["Redbird"])
  ]
)