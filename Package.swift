import PackageDescription

let package = Package(
  name: "Redbird",
  dependencies: [
  	.Package(url: "https://github.com/Zewo/Venice.git", majorVersion: 0, minor: 1)
  ]
)