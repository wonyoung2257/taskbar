// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "tbar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "TBarCore",
            targets: ["TBarCore"]
        ),
        .executable(
            name: "tbar",
            targets: ["tbar"]
        ),
        .executable(
            name: "TBarApp",
            targets: ["TBarApp"]
        )
    ],
    targets: [
        .target(
            name: "TBarCore"
        ),
        .executableTarget(
            name: "tbar",
            dependencies: [
                "TBarCore"
            ]
        ),
        .executableTarget(
            name: "TBarApp",
            dependencies: ["TBarCore"]
        ),
        .testTarget(
            name: "TBarCoreTests",
            dependencies: ["TBarCore"]
        )
    ]
)
