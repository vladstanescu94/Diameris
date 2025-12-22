# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation

The `Docs/` directory at the project root contains `.md` files with feature specifications and project documentation. **Always check this directory** for context before implementing or modifying features.

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

### Project Structure

```
Diameris/
├── AppDelegate/          # App entry point (DiamerisApp.swift)
├── Features/
│   └── Home/
│       ├── Model/        # SwiftData models (Item.swift)
│       └── View/         # SwiftUI views (ContentView.swift)
└── Resources/
    └── Assets.xcassets/  # Asset catalog
```

### Key Patterns

- **Feature-based organization**: Code organized under `Features/<FeatureName>/{Model,View}/`
- **SwiftData**: Uses `@Model` macro for persistence with `ModelContainer` configured in app entry point
- **Swift 6 concurrency**: Project uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- **Testing framework**: Uses Swift Testing (`import Testing`) for unit tests, XCTest for UI tests
