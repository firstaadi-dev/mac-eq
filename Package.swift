import PackageDescription

let package = Package(
    name: "mac-eq",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "mac-eq",
            targets: ["mac-eq"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "mac-eq",
            dependencies: [],
            path: "Sources/mac-eq"
        )
    ]
)