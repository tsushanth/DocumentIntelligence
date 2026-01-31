// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DocumentCore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "DocumentCore",
            targets: ["DocumentCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "DocumentCore",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "DocumentCoreTests",
            dependencies: ["DocumentCore"],
            path: "Tests"
        ),
    ]
)
