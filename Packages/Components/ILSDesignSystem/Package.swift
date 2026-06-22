// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ILSDesignSystem",
    platforms: [.visionOS(.v2)],
    products: [
        .library(name: "ILSDesignSystem", targets: ["ILSDesignSystem"]),
    ],
    targets: [
        .target(name: "ILSDesignSystem")
    ]
)
