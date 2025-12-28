// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Dashboard",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "Dashboard",
            targets: ["Dashboard"]
        )
    ],
    dependencies: [
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/SharedUI"),
        .package(path: "../../Core/Utilities"),
        .package(path: "../../Core/Domain")
    ],
    targets: [
        .target(
            name: "Dashboard",
            dependencies: [
                "DesignSystem",
                "SharedUI",
                "Utilities",
                "Domain"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "DashboardTests",
            dependencies: ["Dashboard"]
        )
    ]
)
