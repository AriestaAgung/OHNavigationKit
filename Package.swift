// swift-tools-version: 5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OHNavigationKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "OHNavigationKit",
            targets: ["OHNavigationKit"]
        ),
    ],
    targets: [
        .target(
            name: "OHNavigationKit"
        ),
        .testTarget(name: "OHNavigationKitTests", dependencies: ["OHNavigationKit"])
    ]
)
