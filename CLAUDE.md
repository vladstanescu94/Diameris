# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation

The `Docs/` directory at the project root contains `.md` files with feature specifications and project documentation.

**Before starting any change**, you MUST:
1. **Read the `Docs/` folder** — list its contents and read all relevant files for context
2. **Read `DeveloperRoadmap.md`** — understand current progress and what's been done

**After completing any feature or change**, you MUST:
1. **Update existing docs** — if the change affects a documented feature, update the relevant doc file
2. **Create new docs** — if the change introduces a new feature or pattern not yet documented, create a new `.md` file in `Docs/`
3. **Update `DeveloperRoadmap.md`** — add completed tasks with date and notes

### Required Reading

**Always read first:**

| File | Purpose |
|------|---------|
| `DeveloperRoadmap.md` | **Read every session** - Current progress, completed tasks, next steps |

Before implementing features, **read the relevant API documentation**:

| File | When to Read |
|------|--------------|
| `ProjectDefinition.md` | Start here - contains app scope, data model, UI structure |
| `Architecture.md` | **Required** - SPM modular architecture, layer rules, dependency injection |
| `DesignGuidelines.md` | **Required** - Visual identity, colors, typography, SF Symbols, responsive design, microinteractions |
| `SwiftUI-Implementing-Liquid-Glass-Design.md` | Any UI work - `.glassEffect()`, `GlassEffectContainer`, morphing |
| `SwiftUI-Microinteractions-Onboarding.md` | Animations - microinteractions, spring physics, haptics, `glassEffectID` |
| `SwiftUI-Layout-Best-Practices.md` | Layout issues - `ViewThatFits`, text truncation, adaptive layouts |
| `SwiftData-Class-Inheritance.md` | Data model changes - inheritance, polymorphic queries |
| `SwiftUI-New-Toolbar-Features.md` | Navigation/toolbar work - customizable toolbars, search |
| `Swift-Concurrency-Updates.md` | Async code - Swift 6.2 `@concurrent`, MainActor patterns |
| `Swift-Testing-Framework.md` | Writing tests - `@Test`, `@Suite`, `#expect`, parameterized tests |
| `XcodeBuildMCP-Simulator-Workflow.md` | **Required** - Building, running, and driving the iOS Simulator via XcodeBuildMCP |
| `Swift-Charts-3D-Visualization.md` | Data visualization - `Chart3D`, `SurfacePlot` |
| `FoundationModels-Using-on-device-LLM.md` | AI features - on-device LLM, `@Generable`, guided generation |
| `Diameris-AI-Features.md` | Pre-MVP AI feature ideas (brainstorming) |
| `Audit-2026-09-27.md` | Before tackling audit follow-ups, or touching money logic, persistence or Settings — bug ledger + open follow-ups |
| `Performance-Audit-2026-09-27.md` | Performance or bundle-size work — benchmarks, measured sizes, Observation pitfalls, what was rejected |

**Important:** This project targets iOS 26+ with Liquid Glass design. Always use the new APIs documented above rather than deprecated patterns.

## Running the App & Simulator (XcodeBuildMCP)

**ALWAYS use the XcodeBuildMCP tools to build, run, and interact with the iOS Simulator.**
Do not shell out to `xcodebuild` or `xcrun simctl` for these — the MCP tools capture runtime logs,
carry the project's session defaults, and are the only way to actually drive the UI.

**Read `Docs/XcodeBuildMCP-Simulator-Workflow.md` before any simulator work.**

Non-negotiables:

1. **Build & run** with `simulator_build_and_run` (boots + installs + launches + captures logs).
   Defaults are preconfigured in `.mcp.json`: scheme `Diameris`, `Debug`, iPhone 17 Pro, latest OS.
2. **Never tap by coordinates.** Call `snapshot_ui` first, act on the returned `elementRef`s.
3. **Re-snapshot after every UI change** — navigation, scroll, sheet present/dismiss, layout shift.
4. **Verify UI changes in the running app.** After a SwiftUI change, run it, drive to the affected
   screen, and take a `screenshot`. Compiling is not the same as working.
5. **Check both appearances** for Liquid Glass work — `set_appearance` to flip light/dark.

Interaction tools: `snapshot_ui`, `wait_for_ui`, `tap`, `batch`, `swipe`, `drag`, `long_press`,
`type_text`, `key_press`, `button`, `gesture`, `screenshot`, `record_video`.

Requires AXe on `PATH` (`brew install axe` from the `cameroncooke/axe` tap) — already installed.

Xcode's own MCP bridge (`xcrun mcpbridge`, the `xcode` server in `.mcp.json`) is also registered —
use it for Xcode-only capabilities (SwiftUI previews, per-file diagnostics, String Catalog edits,
documentation search). It needs a UI Xcode with the project open or headless mode with this folder
permitted; `xcrun mcp-server status` says which.

## Apple Skills & Official Docs (MANDATORY)

Xcode ships Apple-authored skills as the `xcode-integration` plugin. The user's `claude` shell
function loads it via `--plugin-dir "$(xcrun agent plugin path --plugin-format claude)"`, only when
launched inside this repo (listed in `CLAUDE_XCODE_PLUGIN_PROJECTS` in `~/.zshrc`).
**If no `xcode-integration:*` skills appear in your skill list, stop and tell the user to relaunch
with the `claude` wrapper** — don't silently continue without them.

### Invoke these skills before the matching work

| Work | Skill(s) |
|------|----------|
| Writing or reviewing any SwiftUI code | `xcode-integration:swiftui-specialist` |
| Using an API introduced in iOS 26/27, or asked "what's new" | `xcode-integration:swiftui-whats-new-27` |
| New or changed screen (before calling UI done) | `xcode-integration:accessibility-voiceover-specialist`, `xcode-integration:accessibility-dynamic-type-specialist`, `xcode-integration:accessibility-sufficient-contrast-specialist` |
| Adding/editing strings or `.xcstrings` (English + Romanian) | `xcode-integration:translation-coordinator` (it drives `translation`; the bridge's String Catalog tools refuse to run without it) |
| Migrating or modernising **unit** tests | `xcode-integration:modernize-tests` (UI tests stay XCTest) |
| App Intents / Shortcuts / widgets intents | `xcode-integration:app-intents-specialist` |
| Verifying behaviour via the Xcode bridge's device tools | `xcode-integration:device-interaction` |

Apple's skills are authoritative on **API correctness and platform behaviour**; they supersede
training data and the older `swiftui-pro` / `swiftui-skills` guidance where they conflict. Project
conventions below (DesignSystem constants, localization, layering) still govern **structure and style**.

### Check official Apple docs — don't guess

- Before using an Apple API you haven't seen used in this codebase, or whenever unsure of a
  signature, availability, or behaviour, query **`DocumentationSearch`** on the `xcode` MCP server
  (pass `frameworks`, e.g. `["SwiftUI"]`, to narrow results).
- Prefer it over web search and over memory. Fall back to web search only if it returns nothing useful.
- If it contradicts a file in `Docs/`, follow Apple's documentation and update the `Docs/` file.

## Build Commands

Prefer the MCP tools above for anything simulator-related. These raw commands are a fallback for
CI or when the MCP server is unavailable.

```bash
# Build the project
xcodebuild -project Diameris.xcodeproj -scheme Diameris -configuration Debug build

# Run unit tests (SPM packages - preferred)
cd Packages/Core/Domain && swift test          # Domain and Utilities also build on macOS
cd Packages/Features/Onboarding && xcodebuild test -scheme Onboarding -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5'

# Run UI tests
xcodebuild -project Diameris.xcodeproj -scheme Diameris -configuration Debug test -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -only-testing:DiamerisUITests
```

- **Always pin `OS=`** (or use `id=<udid>` from `xcrun simctl list devices`). A name alone resolves
  to `OS:latest`; with Xcode 27 installed that is iOS 27, where only iPhone 18 simulators exist, so
  `name=iPhone 17 Pro` fails with exit 70 ("Unable to find a device matching…").
- **Parallel runs** (e.g. several agents): give each its own simulator and its own
  `-derivedDataPath`, otherwise builds of the same package collide on "database is locked".

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

## iOS 26 Liquid Glass Design

**ALWAYS leverage Liquid Glass** for UI components in this project. Before implementing any UI:

1. **Read `Docs/SwiftUI-Implementing-Liquid-Glass-Design.md`** - Contains patterns, troubleshooting, and examples
2. **Use glass modifiers**: `.glassEffect()`, `.buttonStyle(.glass)`, `.buttonStyle(.glassProminent)`, `GlassEffectContainer`
3. **Check Apple docs when unsure**: `DocumentationSearch` on the `xcode` MCP server first (e.g. "glassEffect GlassEffectContainer"); web search only as a fallback

**Quick Reference:**
- Buttons: `.buttonStyle(.glass)` or `.buttonStyle(.glassProminent)`
- Cards/containers: `.glassEffect()` or use `.glassCard()` from DesignSystem
- Interactive elements: `.glassEffect(.regular.interactive())`
- Menus: Use native Menu with `.buttonStyle(.glass)` - avoid manual glass on Menu labels
- Toolbars: Native toolbar items get glass automatically

**Common Pitfalls:**
- Don't use `GlassEffectContainer` when you don't want elements to morph together
- Menu + manual `.glassEffect()` causes dismiss animation glitches
- `.buttonStyle(.glass)` already has built-in press states - don't add custom ones

## Code Standards

### No Magic Numbers
All numeric values (sizes, durations, thresholds) must use named constants from DesignSystem:
- `Spacing.xs`, `Spacing.sm`, `Spacing.md`, `Spacing.lg`, `Spacing.xl`
- `CornerRadius.small`, `CornerRadius.medium`, `CornerRadius.large`
- `AnimationDuration.fast`, `AnimationDuration.standard`, `AnimationDuration.slow`
- `ComponentSize.buttonHeight`, `ComponentSize.iconMedium`, etc.

### All Strings Must Be Localized
Every user-facing string must use localization:
- In SPM packages: `"String".localized` (uses the `.localized` extension with `bundle: .module`)
- For interpolation: `String(localized: "Hello, \(name)!", bundle: .module)`
- Never hardcode user-visible text directly

### Leverage SPM Packages - No Duplication
Before creating new components or utilities:
1. **Check DesignSystem** - Colors, spacing, typography, glass effects, animation constants
2. **Check SharedUI** - Reusable view components (ProgressRing, CelebrationEffect, CurrencyAmountField)
3. **Check Utilities** - Helpers (HapticManager, AmountFormatter, Currency)

If a component could be reused across features, add it to the appropriate Core package rather than duplicating in feature packages.

### Business Logic Lives in Domain Only
**NEVER duplicate business logic across layers.** All calculations and business rules must live in the Domain layer (e.g., `AccountEntry`, `TransferCalculator`).

Other layers must **delegate** to Domain, not reimplement:
- `Account` (Persistence) → use `toEntry().someCalculation()`
- `DashboardAccount` (Features) → use `toAccountEntry().someCalculation()`

**Example - Emergency Fund Target:**
```swift
// ✅ CORRECT: Domain has the logic, others delegate
// Domain/AccountEntry.swift
public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
    guard accountType == .emergency, let multiplier = emergencyMultiplier else { return nil }
    let calculated = monthlyIncome * Decimal(multiplier)
    return emergencyHardCap.map { min(calculated, $0) } ?? calculated
}

// Persistence/Account.swift - DELEGATES
public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
    toEntry().emergencyTarget(monthlyIncome: monthlyIncome)
}

// Dashboard/DashboardAccount.swift - DELEGATES
public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
    toAccountEntry().emergencyTarget(monthlyIncome: monthlyIncome)
}
```

```swift
// ❌ WRONG: Duplicating the calculation in multiple files
// This breaks when logic changes (e.g., adding hard cap)
```

When adding new features that involve calculations, **only modify Domain** and ensure other layers delegate.

## After Deep Changes

After completing significant refactoring, feature implementation, or architectural changes:

1. **Update `Docs/DeveloperRoadmap.md`** - Add completed tasks to the "Completed" table with date and notes
2. **Add session notes** - Document key learnings, patterns discovered, and files added/modified
3. **Update relevant docs** - If you learned something new about APIs or patterns, update the relevant documentation file
