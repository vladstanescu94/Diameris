// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DiamerisServer",
    platforms: [.macOS(.v26)],
    products: [
        .executable(name: "DiamerisServer", targets: ["DiamerisServer"]),
        .library(name: "DiamerisServerCore", targets: ["DiamerisServerCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.122.0"),
        .package(path: "../../Packages/Core/Domain"),
        .package(path: "../../Packages/Core/Utilities")
    ],
    targets: [
        // Everything lives in the library so the tests can exercise it directly.
        .target(
            name: "DiamerisServerCore",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Domain", package: "Domain"),
                .product(name: "Utilities", package: "Utilities")
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "DiamerisServer",
            dependencies: ["DiamerisServerCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DiamerisServerTests",
            dependencies: ["DiamerisServerCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        )
    ]
)
