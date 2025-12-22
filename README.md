# Diameris

A personal finance and budget management app for iOS, iPadOS, and macOS built with SwiftUI and the iOS 26 Liquid Glass design language.

## Overview

Diameris helps users take control of their finances by tracking income and expenses, managing savings goals, monitoring loan payments, and planning bank transfers. The app provides actionable insights and recommendations to improve financial health.

## Features

- **Income Management** - Track salary and multiple income sources
- **Expense Tracking** - Manage monthly and annual expenses with custom categories
- **Emergency Fund** - Set targets, track progress, and prioritize saving
- **Loan/Debt Tracking** - Monitor balances, payments, and payoff timelines
- **Savings System** - Configurable savings goals with intelligent allocation
- **Bank Transfer Planning** - Calculate and plan post-payday transfers
- **Budget Analysis** - Spending breakdowns, category analysis, and financial health scoring

## Tech Stack

| Technology | Purpose |
|------------|---------|
| SwiftUI | User interface |
| SwiftData | Local persistence |
| Swift 6 | Concurrency with MainActor isolation |
| Swift Charts | Data visualization |
| Swift Testing | Unit tests |

## Architecture

Diameris uses a modular SPM (Swift Package Manager) architecture following Clean Architecture principles:

```
Diameris/
├── DiamerisApp/              # Main app target
├── Packages/
│   ├── Core/
│   │   ├── DesignSystem/     # Liquid Glass, colors, typography
│   │   └── Utilities/        # Extensions, formatters
│   ├── Domain/
│   │   ├── Entities/         # Pure Swift business models
│   │   ├── UseCases/         # Business logic
│   │   └── Repositories/     # Protocol definitions
│   ├── Platform/
│   │   └── Persistence/      # SwiftData implementations
│   └── Features/
│       ├── Dashboard/
│       ├── Budget/
│       ├── Goals/
│       ├── Transfers/
│       └── Settings/
└── Docs/                     # Feature specs and documentation
```

### Key Patterns

- **Clean Architecture Layers**: App → Features → Domain → Platform → Core
- **Protocol-based Repositories**: Features depend on abstractions
- **Native Dependency Injection**: Manual `DependencyContainer`, no external frameworks
- **Type-safe Navigation**: Router pattern with `NavigationStack` and `NavigationPath`

## Requirements

- iOS 26.0+ / iPadOS 26.0+ / macOS Tahoe (future)
- Xcode 26+
- Swift 6.0+

## Building

```bash
# Build the project
xcodebuild -project Diameris.xcodeproj -scheme Diameris -configuration Debug build

# Run unit tests
xcodebuild -project Diameris.xcodeproj -scheme Diameris -configuration Debug test \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild -project Diameris.xcodeproj -scheme Diameris -configuration Debug test \
  -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DiamerisUITests
```

## Design

Diameris adopts Apple's Liquid Glass design language introduced at WWDC 2025:

- **Liquid Glass effects** on cards and containers
- **Glass-style buttons** for primary and secondary actions
- **Morphing transitions** between screens
- **Collapsing tab bar** on scroll

### Brand Colors

| Color | Light | Dark |
|-------|-------|------|
| Primary (Magenta) | `#D946EF` | `#E879F9` |
| Secondary (Teal) | `#06B6D4` | `#22D3EE` |

## Localization

- English
- Romanian

## Status

This project is in active development. See `Docs/ProjectDefinition.md` for the implementation roadmap.

## License

All rights reserved.
