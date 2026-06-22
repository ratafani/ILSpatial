// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ILSFoundation",
    platforms: [.visionOS(.v2), .iOS(.v17)],
    products: [
        .library(name: "ILSFoundation", type: .static, targets: ["ILSFoundation"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ILSFoundation",
            dependencies: []
        )
    ]
)
