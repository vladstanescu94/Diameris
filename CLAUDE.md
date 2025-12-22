# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation

The `Docs/` directory at the project root contains `.md` files with feature specifications and project documentation. **Always check this directory** for context before implementing or modifying features.

### Required Reading

Before implementing features, **read the relevant API documentation**:

| File | When to Read |
|------|--------------|
| `ProjectDefinition.md` | Start here - contains app scope, data model, UI structure |
| `Architecture.md` | **Required** - SPM modular architecture, layer rules, dependency injection |
| `DesignGuidelines.md` | **Required** - Visual identity, colors, typography, SF Symbols, responsive design, microinteractions |
| `SwiftUI-Implementing-Liquid-Glass-Design.md` | Any UI work - `.glassEffect()`, `GlassEffectContainer`, morphing |
| `SwiftData-Class-Inheritance.md` | Data model changes - inheritance, polymorphic queries |
| `SwiftUI-New-Toolbar-Features.md` | Navigation/toolbar work - customizable toolbars, search |
| `Swift-Concurrency-Updates.md` | Async code - Swift 6.2 `@concurrent`, MainActor patterns |
| `Swift-Charts-3D-Visualization.md` | Data visualization - `Chart3D`, `SurfacePlot` |

**Important:** This project targets iOS 26+ with Liquid Glass design. Always use the new APIs documented above rather than deprecated patterns.

## Build Commands

```bash
# Build the project
xcodebuild -project Diameris.xcodeproj -scheme Diameris -configuration Debug build

# Run unit tests
xcodebuild -project Diameris.xcodeproj -scheme Diameris -configuration Debug test -destination 'platform=iOS Simulator,name=iPhone 16'

# Run UI tests
xcodebuild -project Diameris.xcodeproj -scheme Diameris -configuration Debug test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:DiamerisUITests
```

## Architecture

**iOS SwiftUI app** targeting iOS 26.2+ with SwiftData for persistence. The app category is Finance (`public.app-category.finance`).

**See `Docs/Architecture.md` for full details on the modular SPM architecture.**

### Project Structure (Modular SPM)

```
Diameris/
├── DiamerisApp/              # Main app target (thin shell)
│   ├── DiamerisApp.swift     # @main entry point
│   └── DependencyContainer.swift
│
├── Packages/                  # Local SPM packages
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
│       └── ...
└── Docs/
```

### Key Patterns

- **SPM Modular Architecture**: Local packages in `Packages/` directory (see `Architecture.md`)
- **Clean Architecture Layers**: App → Features → Domain → Platform → Core
- **Pure Domain Models**: Business entities are plain Swift structs, SwiftData models in Platform
- **Protocol-based Repositories**: Features depend on abstractions, Platform provides implementations
- **Native DI**: Manual `DependencyContainer` class, no external frameworks
- **Swift 6 concurrency**: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- **Testing**: Swift Testing (`import Testing`) for unit tests, XCTest for UI tests
- **Localization**: English + Romanian (use `String(localized:)` for all user-facing text)
- **Design**: iOS 26 Liquid Glass - use `.glassEffect()`, `GlassEffectContainer`, `.buttonStyle(.glass)`
