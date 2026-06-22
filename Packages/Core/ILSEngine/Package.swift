// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ILSEngine",
    platforms: [.visionOS(.v2), .iOS(.v17)],
    products: [
        .library(name: "ILSEngine", type: .static, targets: ["ILSEngine"]),
    ],
    dependencies: [
        .package(path: "../ILSFoundation"),
        .package(path: "../../RealityKitContent/ILSRealityAssets")
    ],
    targets: [
        .target(
            name: "ILSEngine",
            dependencies: [
                .product(name: "ILSFoundation", package: "ILSFoundation"),
                .product(name: "ILSRealityAssets", package: "ILSRealityAssets")
            ]
        )
    ]
)
