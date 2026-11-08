// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Onboarding",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(
            name: "Onboarding",
            targets: ["Onboarding"]
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
            name: "Onboarding",
            dependencies: ["DesignSystem", "SharedUI", "Utilities", "Domain"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "OnboardingTests",
            dependencies: ["Onboarding"]
        )
    ]
)
