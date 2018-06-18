// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Citron",
    products: [
        .executable(
            name: "citron",
            targets: ["citron"]),
        .library(
            name: "CitronKit",
            targets: ["CitronKit"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "citron",
            dependencies: []),
        .target(
            name: "CitronKit",
            dependencies: []),
        .testTarget(
            name: "CitronKitTests",
            dependencies: ["CitronKit"])
    ]
)
