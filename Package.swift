// swift-tools-version:5.9

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
    dependencies: [
        .package(url: "https://github.com/mattgallagher/CwlPreconditionTesting.git", from: Version("2.0.0")),
    ],
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
            dependencies: ["CSErrors", "CwlPreconditionTesting"]
        ),
        .testTarget(
            name: "CSErrors.FoundationTests",
            dependencies: ["CSErrors.Foundation", "CwlPreconditionTesting"]
        )
    ]
)
