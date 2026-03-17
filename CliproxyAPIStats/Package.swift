// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CliproxyAPIStats",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "CliproxyAPIStats",
            path: "Sources"
        )
    ]
)
