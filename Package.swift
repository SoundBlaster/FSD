// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FSDTools",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "FSDToolingSupport", targets: ["FSDToolingSupport"]),
        .plugin(name: "FSDGeneratorPlugin", targets: ["FSDGeneratorPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "FSDToolingSupport",
            path: "Sources/FSDToolingSupport"
        ),
        .plugin(
            name: "FSDGeneratorPlugin",
            capability: .command(
                intent: .custom(
                    verb: "fsd-generate",
                    description: "Generate FSD slices and module islands with fsd-ios"
                ),
                permissions: [
                    .writeToPackageDirectory(
                        reason: "Generate FSD slice/module files in the selected package directory."
                    ),
                ]
            )
        ),
    ]
)
