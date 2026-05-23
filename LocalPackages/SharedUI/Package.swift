// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SharedUI",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SharedUI", targets: ["SharedUI"]),
    ],
    targets: [
        .target(
            name: "SharedUI",
            path: "Sources/SharedUI"
        ),
    ]
)
