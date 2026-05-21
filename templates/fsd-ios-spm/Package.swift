// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "AppNameModules",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "AppNameCoreUI", targets: ["AppNameCoreUI"]),
        .library(name: "AppNameProductDomain", targets: ["AppNameProductDomain"]),
        .library(name: "AppNameCreateSampleFeature", targets: ["AppNameCreateSampleFeature"]),
        .library(name: "AppNameProductListScreen", targets: ["AppNameProductListScreen"]),
    ],
    targets: [
        .target(name: "AppNameCoreUI"),
        .target(
            name: "AppNameProductDomain",
            dependencies: []
        ),
        .target(
            name: "AppNameCreateSampleFeature",
            dependencies: [
                "AppNameProductDomain",
                "AppNameCoreUI",
            ]
        ),
        .target(
            name: "AppNameProductListScreen",
            dependencies: [
                "AppNameCreateSampleFeature",
                "AppNameProductDomain",
                "AppNameCoreUI",
            ]
        ),
        .testTarget(
            name: "AppNameCreateSampleFeatureTests",
            dependencies: [
                "AppNameCreateSampleFeature",
                "AppNameProductDomain",
            ]
        ),
    ]
)
