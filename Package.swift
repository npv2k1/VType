// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VTypeCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "VTypeCore", targets: ["VTypeCore"])
    ],
    targets: [
        .target(
            name: "VTypeCore",
            path: "VType/Core"
        ),
        .testTarget(
            name: "VTypeCoreTests",
            dependencies: ["VTypeCore"],
            path: "VTypeTests/Core"
        )
    ]
)

