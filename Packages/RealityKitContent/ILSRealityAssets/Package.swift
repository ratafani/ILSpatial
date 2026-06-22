// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ILSRealityAssets",
    platforms: [.visionOS(.v2)],
    products: [
        .library(name: "ILSRealityAssets", targets: ["ILSRealityAssets"]),
    ],
    targets: [
        .target(name: "ILSRealityAssets", resources: [.process("ILSRealityAssets.rkassets")])
    ]
)
