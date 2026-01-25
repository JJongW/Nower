// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NowerCore",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "NowerCore",
            targets: ["NowerCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NowerCore",
            dependencies: [],
            path: "Sources/NowerCore"
        ),
        .testTarget(
            name: "NowerCoreTests",
            dependencies: ["NowerCore"],
            path: "Tests/NowerCoreTests"
        ),
    ]
)
