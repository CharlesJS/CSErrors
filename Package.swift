// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "CSErrors",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13)
    ],
    products: [
        .library(
            name: "CSErrors",
            targets: ["CSErrors"]
        ),
    ],
    traits: [
        "Foundation"
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CSErrors",
            dependencies: []
        ),
        .testTarget(
            name: "CSErrorsTests",
            dependencies: ["CSErrors"]
        ),
    ]
)
