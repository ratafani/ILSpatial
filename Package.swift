// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "ILSpatial",
    platforms: [.visionOS("2.0"), .iOS(.v17)],
    products: [
        .library(name: "ILSFoundation", targets: ["ILSFoundation"]),
        .library(name: "ILSEngine", targets: ["ILSEngine"]),
        .library(name: "ILSRealityAssets", targets: ["ILSRealityAssets"]),
        .library(name: "ILSHandTracking", targets: ["ILSHandTracking"]),
        .library(name: "ILSSpatialAudio", targets: ["ILSSpatialAudio"]),
        .library(name: "ILSSpatialDraw", targets: ["ILSSpatialDraw"]),
        .library(name: "ILSDesignSystem", targets: ["ILSDesignSystem"]),
    ],
    targets: [
        .target(
            name: "ILSFoundation",
            path: "Packages/Core/ILSFoundation/Sources/ILSFoundation"
        ),
        .target(
            name: "ILSEngine",
            dependencies: ["ILSFoundation", "ILSRealityAssets"],
            path: "Packages/Core/ILSEngine/Sources/ILSEngine"
        ),
        .target(
            name: "ILSRealityAssets",
            path: "Packages/RealityKitContent/ILSRealityAssets/Sources/ILSRealityAssets",
            resources: [.process("../../../ILSRealityAssets/Sources/ILSRealityAssets/ILSRealityAssets.rkassets")] 
            // Wait, resources path is relative to the target's path, but the bundle is at Packages/RealityKitContent/ILSRealityAssets/Sources/ILSRealityAssets/ILSRealityAssets.rkassets, so .process("ILSRealityAssets.rkassets") should work.
        ),
        .target(
            name: "ILSHandTracking",
            dependencies: ["ILSFoundation", "ILSEngine"],
            path: "Packages/Features/ILSHandTracking/Sources/ILSHandTracking"
        ),
        .target(
            name: "ILSSpatialAudio",
            dependencies: ["ILSFoundation", "ILSEngine"],
            path: "Packages/Features/ILSSpatialAudio/Sources/ILSSpatialAudio"
        ),
        .target(
            name: "ILSSpatialDraw",
            dependencies: ["ILSFoundation", "ILSEngine", "ILSHandTracking"],
            path: "Packages/Features/ILSSpatialDraw/Sources/ILSSpatialDraw"
        ),
        .target(
            name: "ILSDesignSystem",
            path: "Packages/Components/ILSDesignSystem/Sources/ILSDesignSystem"
        )
    ]
)
