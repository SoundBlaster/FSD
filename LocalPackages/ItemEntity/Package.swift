// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ItemEntity",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ItemEntity", targets: ["ItemEntity"]),
    ],
    targets: [
        .target(
            name: "ItemEntity",
            path: "Sources/ItemEntity"
        ),
    ]
)
