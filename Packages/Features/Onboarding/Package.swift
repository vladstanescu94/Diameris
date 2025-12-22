// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Onboarding",
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
        .package(path: "../../Core/DesignSystem")
    ],
    targets: [
        .target(
            name: "Onboarding",
            dependencies: ["DesignSystem"],
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
