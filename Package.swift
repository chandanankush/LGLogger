// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "LGLogger",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "LGLogger",
            targets: ["LGLogger"]
        )
    ],
    targets: [
        .target(
            name: "LGLogger"
        ),
        .testTarget(
            name: "LGLoggerTests",
            dependencies: ["LGLogger"]
        )
    ]
)
