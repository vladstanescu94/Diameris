// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Utilities",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "Utilities", targets: ["Utilities"])
    ],
    targets: [
        .target(
            name: "Utilities",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "UtilitiesTests",
            dependencies: ["Utilities"]
        )
    ]
)
