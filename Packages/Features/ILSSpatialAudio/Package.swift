// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ILSSpatialAudio",
    platforms: [.visionOS(.v2)],
    products: [
        .library(name: "ILSSpatialAudio", targets: ["ILSSpatialAudio"]),
    ],
    dependencies: [
        .package(path: "../../Core/ILSEngine"),
        .package(path: "../../Core/ILSFoundation")
    ],
    targets: [
        .target(
            name: "ILSSpatialAudio",
            dependencies: [
                "ILSEngine",
                "ILSFoundation"
            ]
        )
    ]
)
