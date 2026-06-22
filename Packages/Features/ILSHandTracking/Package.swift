// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ILSHandTracking",
    platforms: [.visionOS(.v2)],
    products: [
        .library(name: "ILSHandTracking", targets: ["ILSHandTracking"]),
    ],
    dependencies: [
        .package(path: "../../Core/ILSEngine"),
        .package(path: "../../Core/ILSFoundation")
    ],
    targets: [
        .target(
            name: "ILSHandTracking",
            dependencies: [
                "ILSEngine",
                "ILSFoundation"
            ]
        )
    ]
)
