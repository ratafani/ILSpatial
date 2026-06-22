// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ILSSpatialDraw",
    platforms: [.visionOS(.v2)],
    products: [
        .library(name: "ILSSpatialDraw", targets: ["ILSSpatialDraw"]),
    ],
    dependencies: [
        .package(path: "../../Core/ILSEngine"),
        .package(path: "../../Core/ILSFoundation"),
        .package(path: "../ILSHandTracking")
    ],
    targets: [
        .target(
            name: "ILSSpatialDraw",
            dependencies: [
                "ILSEngine",
                "ILSFoundation",
                "ILSHandTracking"
            ]
        )
    ]
)
