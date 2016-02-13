import PackageDescription

let package = Package(
  name: "Redbird",
  exclude: [],
  targets: [
    Target(
      name: "Redbird"
    ),
    Target(
      name: "RedbirdExample",
      dependencies: [
        .Target(name: "Redbird")
      ]
    )
  ]
)