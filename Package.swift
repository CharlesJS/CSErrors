// swift-tools-version:5.7

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
        .library(
            name: "CSErrors+Foundation",
            targets: ["CSErrors.Foundation"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CSErrors",
            dependencies: []
        ),
        .target(
            name: "CSErrors.Foundation",
            dependencies: ["CSErrors"]
        ),
        .testTarget(
            name: "CSErrorsTests",
            dependencies: ["CSErrors"]
        ),
        .testTarget(
            name: "CSErrors.FoundationTests",
            dependencies: ["CSErrors.Foundation"]
        )
    ]
)
