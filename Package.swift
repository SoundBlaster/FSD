// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "FSDTools",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "fsd-ios", targets: ["fsd-ios"]),
        .plugin(name: "FSDGeneratorPlugin", targets: ["FSDGeneratorPlugin"]),
    ],
    targets: [
        .executableTarget(
            name: "fsd-ios",
            path: "tools",
            exclude: [
                "fsd-harmonize.swift",
                "fsd-lint.swift",
                "fsd-template-create.swift",
                "fsd-template-validate.swift",
            ],
            sources: ["fsd-ios.swift"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
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
            ),
            dependencies: ["fsd-ios"]
        ),
    ]
)
