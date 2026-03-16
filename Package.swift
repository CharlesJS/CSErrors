// swift-tools-version:6.2

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
    dependencies: [
        .package(url: "https://github.com/apple/swift-system", from: "1.6.1"),
    ],
    targets: [
        .target(
            name: "CSErrors",
            dependencies: [
                .product(name: "SystemPackage", package: "swift-system", condition: .when(platforms: [.linux]))
            ]
        ),
        .testTarget(
            name: "CSErrorsTests",
            dependencies: ["CSErrors"]
        ),
    ]
)
