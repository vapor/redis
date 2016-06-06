import PackageDescription

let package = Package(
  name: "Redbird",
  dependencies: [
<<<<<<< HEAD
    .Package(url: "https://github.com/czechboy0/Socks.git", majorVersion: 0, minor: 4)
=======
    .Package(url: "https://github.com/czechboy0/Socks.git", majorVersion: 0, minor: 3)
>>>>>>> master
  ],
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