// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Expenses",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Expenses",
            targets: ["Expenses"]
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
            name: "Expenses",
            dependencies: ["DesignSystem", "SharedUI", "Utilities", "Domain"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "ExpensesTests",
            dependencies: ["Expenses"]
        )
    ]
)
