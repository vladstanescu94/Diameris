// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SharedUI",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "SharedUI", targets: ["SharedUI"])
    ],
    dependencies: [
        .package(path: "../DesignSystem"),
        .package(path: "../Utilities"),
        .package(path: "../Domain")
    ],
    targets: [
        .target(
            name: "SharedUI",
            dependencies: ["DesignSystem", "Utilities", "Domain"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SharedUITests",
            dependencies: ["SharedUI"]
        )
    ]
)
