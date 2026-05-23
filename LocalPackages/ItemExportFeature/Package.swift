// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ItemExportFeature",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "ItemExportFeature", targets: ["ItemExportFeature"]),
    ],
    targets: [
        .target(
            name: "ItemExportFeature",
            path: "Sources/ItemExportFeature"
        ),
        .testTarget(
            name: "ItemExportFeatureTests",
            dependencies: ["ItemExportFeature"],
            path: "Tests/ItemExportFeatureTests"
        ),
    ]
)
