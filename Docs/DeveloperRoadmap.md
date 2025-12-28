# Diameris Developer Roadmap

This document tracks implementation progress. **Update this file after completing each task.**

---

## Current Phase: MVP Feature Development

### Completed

| Task | Date | Notes |
|------|------|-------|
| Project setup | 2025-12-22 | Xcode project created with SwiftData template |
| Documentation | 2025-12-22 | All MVP specs and architecture docs written |
| DesignSystem package | 2025-12-22 | `Packages/Core/DesignSystem/` with colors, spacing, corner radii, icon sizes, glass components |
| Brand colors | 2025-12-22 | AccentPrimary (magenta), AccentSecondary (teal) in Assets.xcassets |
| DesignSystem linked | 2025-12-22 | Package added to Xcode project, verified on device |
| Onboarding package | 2025-12-22 | `Packages/Features/Onboarding/` - 5-screen flow with SwiftData persistence |
| SwiftData models | 2025-12-22 | UserProfile, Income, Expense, Account models in Onboarding package |
| MainTabView | 2025-12-22 | Placeholder tab bar with Dashboard, Budget, Goals, Transfers tabs |
| DevDebugView | 2025-12-22 | DEBUG-only dev tools tab for resetting onboarding |
| Template cleanup | 2025-12-22 | Removed Item.swift, ContentView.swift; updated DiamerisApp.swift |
| Onboarding integrated | 2025-12-22 | Package added to Xcode, tested and working |
| Text truncation fixes | 2025-12-22 | Added `.fixedSize(horizontal: false, vertical: true)` to prevent text truncation |
| ExpenseRow layout fix | 2025-12-22 | Used `.minimumScaleFactor(0.8)` for consistent layout across currencies |
| Layout best practices docs | 2025-12-22 | Created `SwiftUI-Layout-Best-Practices.md` with ViewThatFits, truncation patterns |
| Onboarding code cleanup | 2025-12-22 | Extracted `OnboardingHeader`, `AmountFormatter`; moved models to `Models/` folder |
| Localization & a11y | 2025-12-22 | Added `String(localized:)` to all user-facing text, accessibility labels/hints |
| Menu glass effect fix | 2025-12-22 | Fixed currency picker dismiss glitch by using `.buttonStyle(.glass)` instead of manual effect |
| Liquid Glass troubleshooting | 2025-12-22 | Added troubleshooting section to `SwiftUI-Implementing-Liquid-Glass-Design.md` |
| Microinteractions docs | 2025-12-22 | Created `SwiftUI-Microinteractions-Onboarding.md` with animation patterns |
| DesignSystem Animation.swift | 2025-12-22 | Added animation durations, spring presets, stagger delays, scale/offset constants |
| HapticManager | 2025-12-22 | Centralized haptic feedback utility in Onboarding package |
| OnboardingProgressIndicator | 2025-12-22 | Animated gradient progress bar with pulsing dots |
| OnboardingButton | 2025-12-22 | Primary/secondary buttons with press scale, haptics, ripple effects |
| CelebrationEffect | 2025-12-22 | Confetti particles, ripple rings, animated checkmark for completion |
| Staggered animations | 2025-12-22 | OnboardingHeader with icon bounce → title slide → subtitle fade |
| Glass morphing transitions | 2025-12-22 | GlassEffectContainer + glassEffectID for screen transitions |
| Onboarding polish complete | 2025-12-22 | Full microinteraction pass with spring physics, haptics, celebrations |
| Glass button simplification | 2025-12-22 | Removed custom press states; `.buttonStyle(.glass)` has built-in interactivity |
| GlassEffectContainer removal | 2025-12-22 | Removed from OnboardingContainerView to prevent unwanted element morphing |
| Onboarding→Home transition | 2025-12-22 | Smooth fade transition with RootView state management |
| Tap-to-dismiss keyboard | 2025-12-22 | `.contentShape(Rectangle())` + `.onTapGesture` on OnboardingContainerView |
| Keyboard-aware transitions | 2025-12-22 | Dismiss keyboard + 150ms delay before screen transitions |
| Swift 6 concurrency fix | 2025-12-22 | `@MainActor` on ViewModel, `Task.sleep` instead of DispatchQueue |
| Onboarding redesign | 2025-12-27 | 7-screen flow: Welcome → Name → Income → Savings Goals → Accounts → Expenses → Transfer Plan |
| Onboarding flow simplification | 2025-12-28 | Reordered: Accounts before Expenses; removed expense-to-account linking from Accounts screen (linking now only on Expenses) |
| WelcomeScreen | 2025-12-27 | Hero icon with glow, value proposition bullets, animated entrance |
| SavingsGoalsScreen | 2025-12-27 | Goal cards with progress rings, savings percentage slider, boost toggle |
| TransferPlanScreen | 2025-12-27 | Personalized transfer plan with celebration effects, replaces CompleteScreen |
| New SwiftData models | 2025-12-27 | SavingsGoal, SavingsAllocation models for persistence |
| New onboarding models | 2025-12-27 | SavingsGoalEntry, SavingsAllocationEntry, AccountType enum |
| TransferCalculator | 2025-12-27 | Utility to calculate monthly transfer plan from income/expenses/goals |
| New UI components | 2025-12-27 | ProgressRing, GoalCard, TransferCard, SavingsSlider, GoalTargetPicker, AccountTypeSelector |
| Programmatic adaptive colors | 2025-12-27 | `Color(light:dark:)` initializer using `UIColor(dynamicProvider:)` - best practice for SPM |
| Colors.swift refactor | 2025-12-27 | Replaced asset catalog lookup (`bundle: .main`) with programmatic adaptive colors |
| Progress bar constants | 2025-12-27 | Added `progressBarMaxWidth`, `progressIndicatorHeight`, `progressBarWidthFraction`, `progressMinFillScale` |
| Toolbar progress indicator | 2025-12-27 | Moved progress indicator to NavigationStack toolbar for native scroll edge blur |
| Adaptive color migration | 2025-12-27 | Updated 16 onboarding files to use `accentPrimary`/`accentSecondary` instead of `*Light` variants |
| Clean code refactoring | 2025-12-27 | Extracted subviews, split files, applied SRP to TransferCalculator, views, and components |
| Clean body pattern | 2025-12-27 | All onboarding screens now have clean bodies with view props in private extensions |
| Core/Utilities package | 2025-12-27 | Created with HapticManager, AmountFormatter, Currency |
| Core/SharedUI package | 2025-12-27 | Created with CelebrationEffect, ProgressRing, CurrencyAmountField |
| SPM architecture alignment | 2025-12-27 | Moved shared components from Onboarding to proper Core layer packages |
| Localization infrastructure | 2025-12-27 | String Catalog (xcstrings), `.localized` extension, CFBundleAllowMixedLocalizations |
| GoalCard UX polish | 2025-12-27 | Added chevron affordance, styled input background, improved placeholder visibility |
| Opacity constants | 2025-12-27 | Added `Opacity.faint` (0.1), `Opacity.light` (0.15) to DesignSystem |
| Expense-to-account linking | 2025-12-27 | Bidirectional: ExpenseRow picker + AccountRow chips; flow: Expenses → Accounts; defaults to Main |
| Confetti scroll fix | 2025-12-27 | Timer now uses `.common` run loop mode to continue during scroll |
| Account system redesign | 2025-12-28 | Account types now drive transfer behavior; emergency fills first with income multiplier (3x-6x), primary savings fills after; user chooses remaining money destination |
| Liquid glass boost card | 2025-12-28 | GlassEffectContainer + glassEffectID on SavingsScreen boost toggle for smooth morphing animation |
| Race condition fix | 2025-12-28 | Fixed rapid tap bugs: ID-based mutations instead of index-based; guard clauses prevent duplicate accounts |
| Ghost tap fix | 2025-12-28 | Added `.disabled()` to Add buttons; moved haptic inside functions after guard checks |
| SavingsSlider boost fix | 2025-12-28 | Slider now shows boosted amount when Savings Boost enabled; added boostEnabled/boostMultiplier params |
| Onboarding flow reorder | 2025-12-28 | Expenses now comes BEFORE Savings (needed to calculate correct available income) |
| SavingsScreen messaging | 2025-12-28 | Updated subtitle: "Savings are calculated from your income after expenses" |
| ExpensesScreen title fix | 2025-12-28 | Changed "Almost there!" to "Where does your money go?" after flow reorder |
| Savings boost safeguard | 2025-12-28 | Prevent enabling 3x boost if boosted savings would exceed available income (>33.3%) |
| Romanian localization update | 2025-12-28 | Added 46 new Romanian translations for account system redesign strings; fixed "se umple" → "se completează" for consistency |

### In Progress

| Task | Notes |
|------|-------|
| — | — |

### Next Up

| Priority | Task | Reference |
|----------|------|-----------|
| 1 | Implement Dashboard feature | Main summary view after onboarding |
| 3 | Implement Budget feature | Income/expense management |

---

## MVP Feature Progress

Based on [MVP Overview](./MVP/00-MVP-Overview.md)

| # | Feature | Status | Spec | Notes |
|---|---------|--------|------|-------|
| 01 | Onboarding | Done | [01-Onboarding.md](./MVP/01-Onboarding.md) | Polished with animations, haptics, glass morphing |
| 02 | Income | Not Started | [02-Income.md](./MVP/02-Income.md) | Basic model created in onboarding |
| 03 | Expenses | Not Started | [03-Expenses.md](./MVP/03-Expenses.md) | Basic model created in onboarding |
| 04 | Categories | Not Started | [04-Categories.md](./MVP/04-Categories.md) | |
| 05 | Emergency Fund | Not Started | [05-EmergencyFund.md](./MVP/05-EmergencyFund.md) | |
| 06 | Loans | Not Started | [06-Loans.md](./MVP/06-Loans.md) | |
| 07 | Savings | Not Started | [07-Savings.md](./MVP/07-Savings.md) | |
| 08 | Accounts | Not Started | [08-Accounts.md](./MVP/08-Accounts.md) | Basic model created in onboarding |
| 09 | Transfer Planning | Not Started | [09-TransferPlanning.md](./MVP/09-TransferPlanning.md) | |
| 10 | Budget Analysis | Not Started | [10-BudgetAnalysis.md](./MVP/10-BudgetAnalysis.md) | |
| 11 | Settings | Not Started | [11-Settings.md](./MVP/11-Settings.md) | |

**Status Legend:** Not Started → In Progress → Done

---

## Architecture Progress

Based on [Architecture.md](./Architecture.md)

### Packages

| Layer | Package | Status | Notes |
|-------|---------|--------|-------|
| Core | DesignSystem | Done | Colors, spacing, corner radii, icon sizes, glass helpers, animation constants |
| Core | Utilities | Done | HapticManager, AmountFormatter, Currency |
| Core | SharedUI | Done | CelebrationEffect, ProgressRing, CurrencyAmountField |
| Domain | Entities | Not Started | Pure Swift business models (may extract from Onboarding later) |
| Domain | UseCases | Not Started | Business logic |
| Domain | Repositories | Not Started | Protocol definitions |
| Platform | Persistence | Not Started | SwiftData implementations |
| Features | Onboarding | Done | 5-screen flow, SwiftData models, ViewModel, microinteractions, celebrations |
| Features | Dashboard | Not Started | Placeholder view created |
| Features | Budget | Not Started | Placeholder view created |
| Features | Goals | Not Started | Placeholder view created |
| Features | Transfers | Not Started | Placeholder view created |
| Features | Settings | Not Started | |

### App Infrastructure

| Component | Status | Notes |
|-----------|--------|-------|
| DependencyContainer | Not Started | Manual DI composition root |
| AppRouter | Not Started | Navigation state management |
| MainTabView | Done | 4 tabs + Dev tab (DEBUG only) |
| Onboarding flow | Done | Forward-only, UserDefaults flag, SwiftData persistence, polished UX |

---

## Technical Debt & Notes

- SwiftData models currently live in Onboarding package; may extract to Domain layer when patterns emerge
- Currency enum in Onboarding; may move to shared Utilities package later
- HapticManager in Onboarding package; consider moving to Core/Utilities when other features need it
- Animation constants in DesignSystem; well-organized for reuse across features

---

## Session Notes

### 2025-12-22 - Onboarding Polish Session

**Focus:** Transform bland onboarding into delightful experience with microinteractions and Liquid Glass animations.

**Key Learnings:**
1. **Menu + Glass Effect Bug:** Using manual `.glassEffect(.interactive())` on Menu labels causes dismiss animation glitches. Solution: Use `.buttonStyle(.glass)` instead.
2. **Text Truncation:** Use `.fixedSize(horizontal: false, vertical: true)` to prevent text from truncating with ellipsis.
3. **Consistent Layouts:** Prefer `.minimumScaleFactor(0.8)` over `ViewThatFits` for simple text scaling needs.
4. **Spring Physics:** `response: 0.3-0.5`, `dampingFraction: 0.6-0.8` feels natural for UI transitions.
5. **Stagger Timing:** 0.1s delays between sequential items, 0.3s initial delay before sequence starts.

**New Documentation:**
- `SwiftUI-Layout-Best-Practices.md` - Text truncation, ViewThatFits patterns
- `SwiftUI-Microinteractions-Onboarding.md` - Animation timing, spring presets, haptics
- Troubleshooting section in `SwiftUI-Implementing-Liquid-Glass-Design.md`

**New DesignSystem Constants:**
- `Animation.swift` - `AnimationDuration`, `SpringPreset`, `StaggerDelay`, `ScaleEffect`, `SlideOffset`
- `ComponentSize` additions - celebration and progress indicator sizes

### 2025-12-22 - Liquid Glass Fixes Session

**Focus:** Fix glass effect interaction bugs and add onboarding completion transition.

**Key Learnings:**
1. **GlassEffectContainer causes element morphing:** When multiple glass elements (buttons, inputs) are inside a `GlassEffectContainer`, they morph/interact with each other on touch. Solution: Only use `GlassEffectContainer` when you *want* elements to morph together.
2. **Glass button styles have built-in press states:** `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)` already handle interactive press feedback. Adding custom `simultaneousGesture` with `DragGesture(minimumDistance: 0)` causes flickering because it catches unrelated touches.
3. **Pre-render views for smooth transitions:** When transitioning between major app states (onboarding → main), keep the destination view in the hierarchy but invisible (`opacity: 0`, `allowsHitTesting: false`). This pre-renders layout so there's no "pop" during the transition.
4. **Spacing affects glass morphing:** The `spacing` parameter in `GlassEffectContainer` controls how close elements need to be to morph. Larger spacing = elements morph from further away.

**Changes Made:**
- Removed `GlassEffectContainer` and `glassEffectID` from `OnboardingContainerView`
- Simplified `OnboardingButton` and `OnboardingSecondaryButton` - removed custom press state handling
- Added `Opacity.medium` and `ComponentSize.buttonHeightSmall` to DesignSystem
- Updated `DiamerisApp.swift` with animated transition from onboarding to MainTabView
- MainTabView pre-rendered in background during onboarding for smooth transition

### 2025-12-22 - Keyboard & Transition Polish Session

**Focus:** Keyboard UX improvements and Swift 6 concurrency fixes.

**Key Learnings:**
1. **Tap-to-dismiss keyboard:** Use `.contentShape(Rectangle())` + `.onTapGesture` on the container to make the entire screen area tappable for dismissing keyboard.
2. **Wait for keyboard before transitions:** Dismiss keyboard first, then use `Task.sleep(for: .milliseconds(150))` before advancing screens to avoid jarring visual overlap.
3. **Swift 6 strict concurrency:** Use `@MainActor` on ViewModels and `Task` with `Task.sleep` instead of `DispatchQueue.main.asyncAfter` to avoid "Sending 'self' risks causing data races" errors.
4. **State sync on reset:** When using separate `@State` and `@AppStorage` for transitions, add `onChange` handler to sync states when the persisted value is reset externally (e.g., from Dev tools).
5. **Don't auto-focus text fields:** Remove `isNameFocused = true` on appear to let users see the screen before keyboard appears.

**Changes Made:**
- Added `@MainActor` to `OnboardingViewModel` for Swift 6 concurrency
- `advance()` now dismisses keyboard and waits 150ms before transitioning
- Added `dismissKeyboard()` method using `UIResponder.resignFirstResponder`
- Added tap-to-dismiss on `OnboardingContainerView`
- Removed auto-focus from `NameScreen`
- Added `RootView` in `DiamerisApp.swift` with proper state management for transitions
- Added `onChange` to sync `showMainTab` when onboarding is reset

### 2025-12-27 - Onboarding Redesign & Color System Session

**Focus:** Complete redesign of onboarding flow with savings goals, transfer planning, and proper SPM color handling.

**Major Changes:**
1. **7-screen onboarding flow:** Welcome → Name → Income → Savings Goals → Accounts → Expenses → Transfer Plan
2. **New SwiftData models:** `SavingsGoal`, `SavingsAllocation` for persisting user's savings configuration
3. **Transfer Calculator:** Computes personalized monthly transfer plan based on income, expenses, and goals
4. **Programmatic adaptive colors:** Replaced `Color("Name", bundle: .main)` with `Color(light:dark:)` using `UIColor(dynamicProvider:)` - works in both app and SPM previews

**New Components:**
- `ProgressRing` - Circular progress with animated fill
- `GoalCard` - Displays savings goal with progress and balance input
- `TransferCard` - Shows individual transfer in the plan
- `SavingsSlider` - Custom slider for savings percentage (5-50%)
- `GoalTargetPicker` - Multiplier selector for income-based targets
- `AccountTypeSelector` - Compact/full picker for account types

**Key Learnings:**
1. **SPM + Asset Catalog colors:** `bundle: .main` works at runtime but fails in SPM previews. Best practice is programmatic adaptive colors via `UIColor(dynamicProvider:)`.
2. **containerRelativeFrame in toolbars:** Doesn't work - toolbars don't provide a container context. Use fixed widths for toolbar items.
3. **NavigationStack toolbar for scroll blur:** Placing progress indicator in `.toolbar(.principal)` gives native iOS 26 scroll edge blur effect.

**Files Added:**
- Views: `WelcomeScreen`, `SavingsGoalsScreen`, `TransferPlanScreen`
- Components: `ProgressRing`, `GoalCard`, `TransferCard`, `SavingsSlider`, `GoalTargetPicker`, `AccountTypeSelector`
- Models: `SavingsGoal`, `SavingsAllocation`, `SavingsGoalEntry`, `SavingsAllocationEntry`, `AccountType`
- Utils: `TransferCalculator`

**Files Removed:**
- `CompleteScreen.swift` - Replaced by `TransferPlanScreen`

### 2025-12-27 - Clean Code Refactoring Session

**Focus:** Apply SOLID principles and clean code practices to onboarding files without changing functionality.

**Refactoring Applied:**
1. **Single Responsibility Principle:** Extracted types to their own files
2. **Private Extensions with MARK:** Organized large views into logical sections
3. **Smaller Files:** Split complex files into focused components

**Files Created:**
- `Models/TransferPlan.swift` - Extracted from TransferCalculator (TransferPlan struct, GoalAllocation, ProgressInfo)
- `Models/TargetType.swift` - Extracted from SavingsGoalEntry (enum for goal target types)
- `Components/AccountRow.swift` - Extracted from AccountsScreen (reusable account row with type selector)

**Files Refactored:**
- `TransferCalculator.swift` - Now only contains calculator logic; private extension with helpers (`distributeToGoals`, `calculateAllocation`, etc.)
- `TransferPlanScreen.swift` - Organized with private extensions: Main Content, Header Section, Income Hero Card, Transfer Cards Section, Verification & Tip, Complete Button, Animations
- `SavingsGoalsScreen.swift` - Organized with private extensions: Header, Goals Section, Divider, Allocation Section, Savings Preview, Action Buttons, Animations
- `WelcomeScreen.swift` - Organized with private extensions: Hero Icon, Content Section, Value Bullets, CTA Button, Animations
- `AccountsScreen.swift` - Removed AccountRow (now in separate file), cleaned up structure

**Key Patterns:**
- Use `private extension` to group related computed properties and methods
- Use `// MARK: -` comments for clear section navigation in Xcode
- Extract nested structs/enums to separate files when they represent distinct concepts
- Keep convenience initializers and static factory methods in extensions

### 2025-12-27 - Clean Body Pattern Session

**Focus:** Apply clean body pattern to all SwiftUI views - extract subviews as view props, move larger components to own files.

**Pattern Applied:**
```swift
var body: some View {
    VStack {
        header           // View prop
        contentSection   // View prop
        actionButtons    // View prop
    }
    .onAppear { triggerAnimations() }
}
```

**Files Refactored:**
- `NameScreen.swift` - Extracted `header`, `nameTextField`, `continueButton`
- `IncomeScreen.swift` - Extracted `header`, `incomeInputSection`, `helperText`, `continueButton`
- `ExpensesScreen.swift` - Extracted `header`, `expensesList`, `impactDisplay`, `impactHeader`, `impactAmount`, `helperText`, `actionButtons`
- `AccountsScreen.swift` - Extracted `header`, `accountsSection`, `sectionTitle`, `accountsList`, `addAccountButton`, `helperText`, `continueButton`
- `OnboardingContainerView.swift` - Extracted `screenContainer`, `currentScreen`, `progressToolbarItem`, `showsProgressIndicator`, `toolbarVisibility`, `screenTransition`

**Files Created:**
- `Components/AddAccountSheet.swift` - Extracted large sheet from AccountsScreen (60+ lines)

**Key Learnings:**
- Bodies should read like an outline of the view's structure
- Use `@ViewBuilder` for conditional content (`impactDisplay`)
- Use `@ToolbarContentBuilder` for conditional toolbar items
- Extract sheets >40 lines to own files
- Computed properties go in their own MARK section (`// MARK: - Computed Properties`)

### 2025-12-27 - SPM Architecture Alignment Session

**Focus:** Align package structure with Architecture.md - create Core/Utilities and Core/SharedUI, move shared components from Onboarding.

**Packages Created:**
1. `Core/Utilities` - Framework-agnostic utilities
   - `HapticManager` - Centralized haptic feedback
   - `AmountFormatter` - Monetary amount formatting
   - `Currency` - Currency enum (RON, EUR, USD)

2. `Core/SharedUI` - Reusable view components (depends on DesignSystem + Utilities)
   - `CelebrationEffect` - Confetti, rings, checkmark animations
   - `ProgressRing` - Circular progress with animated fill
   - `CurrencyAmountField` - Money input with currency picker

**Key Changes:**
- Updated Onboarding to depend on SharedUI + Utilities
- Removed duplicate files from Onboarding
- Added `import Utilities` and `import SharedUI` to 17 files

**Architecture Principle Applied:**
- "Don't make multiple packages that have the same role"
- "Make a package as soon as a new feature demands it"
- Reusable UI → SharedUI, Framework-agnostic helpers → Utilities

**Package Structure Now:**
```
Packages/
├── Core/
│   ├── DesignSystem/     # Design tokens, glass effects
│   ├── SharedUI/         # Reusable view components
│   └── Utilities/        # Haptics, formatters, value types
└── Features/
    └── Onboarding/       # Feature-specific views & models
```

### 2025-12-27 - Localization Session

**Focus:** Implement proper localization for SPM packages with English and Romanian translations.

**Infrastructure Created:**
1. **String Catalog (`Localizable.xcstrings`)** - JSON-based localization with 95+ strings, explicit en/ro translations
2. **`.localized` extension** - Clean syntax: `"Continue".localized` instead of `String(localized:bundle:.module)`
3. **`CFBundleAllowMixedLocalizations`** - Required for package localizations when main app isn't fully localized

**Key Learnings:**
1. **SPM localization requires `bundle: .module`:** Default `String(localized:)` looks in `Bundle.main`, not package bundle
2. **`LocalizedStringKey` won't work:** SwiftUI's `LocalizedStringKey` type always looks in `Bundle.main`. Must use `String` with explicit bundle
3. **Both en.lproj and ro.lproj needed:** String Catalog must have explicit translations for both languages, not just target
4. **`knownRegions` in project.pbxproj:** Target language must be in project's `knownRegions` array
5. **`CFBundleAllowMixedLocalizations`:** Without this, iOS may ignore package localizations if main app isn't localized

**Files Created:**
- `Onboarding/Utils/Localization.swift` - String extension for clean localization syntax
- `Onboarding/Resources/Localizable.xcstrings` - String Catalog with en/ro translations
- `Supporting/Info.plist` - App Info.plist with `CFBundleAllowMixedLocalizations = true`

**Files Updated:**
- 20+ files converted from `String(localized:bundle:.module)` to `.localized`
- `project.pbxproj` - Added `ro` to `knownRegions`, configured `INFOPLIST_FILE`

**Pattern for SPM Localization:**
```swift
// Utils/Localization.swift
extension String {
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .module)
    }
}

// Usage in views
Text("Continue".localized)
OnboardingButton("Let's Go".localized, ...)

// For interpolation (can't use .localized)
String(localized: "Hello, \(name)!", bundle: .module)
```

### 2025-12-27 - Expense-to-Account Linking Session

**Focus:** Allow users to optionally link expenses to specific accounts during onboarding.

**Design Principle:** Optional, not forced. All expenses default to Main/Primary account. Users can optionally change which account an expense is paid from.

**Changes Made:**
1. **ExpenseEntry/Expense models:** Added `linkedAccountId: UUID?` (nil = Primary account)
2. **ExpenseRow:** Added account picker Menu on left side with `.buttonStyle(.glass)`
3. **TransferCalculator:** Added `distributeExpenses()` for expense-aware transfer planning
4. **Localization:** Added "From:", "Main" strings in en/ro

**Key Learnings:**
1. **Menu glass glitch:** Manual `.glassEffect(.interactive())` on Menu labels causes dismiss animation glitch. Solution: Use `.buttonStyle(.glass)` per `SwiftUI-Implementing-Liquid-Glass-Design.md` troubleshooting section.

### 2025-12-28 - Onboarding Flow Simplification

**Focus:** Simplify onboarding by reordering screens and removing bidirectional expense linking.

**Rationale:** The original flow (Expenses → Accounts) with bidirectional linking was too complex. Simpler approach: create accounts first, then link expenses to them on the Expenses screen.

**Changes Made:**
1. **Screen reorder:** Accounts now comes before Expenses in `OnboardingStep` enum
2. **AccountRow:** Removed `linkedExpenses` parameter and chips display
3. **AccountsScreen:** Removed `linkedExpenses(for:)` helper function
4. **AddAccountSheet:** Removed expense linking section, simplified to just name + type + suggestions

**New Flow:** Welcome → Name → Income → Savings Goals → **Accounts** → **Expenses** → Transfer Plan

**Key Principle:** Linking happens in one place only (Expenses screen), not bidirectionally.

### 2025-12-28 - Account System Redesign Session

**Focus:** Make account types meaningful - they should drive transfer behavior, not just be cosmetic labels.

**Problem Statement:** The previous implementation treated account types (checking, savings, personal) as cosmetic labels with no functional meaning. The transfer calculator didn't know that an "Emergency" account should fill first, or that "Savings" should fill after.

**Solution:** Account types now have semantic/behavioral meaning:

| Type | Behavior | Target | Fills When |
|------|----------|--------|------------|
| **Primary** | Where salary lands | N/A | Salary arrives here |
| **Emergency** | Has income multiplier target | 3x-6x income | First (until target reached) |
| **Savings** | One can be "primary savings" | Unlimited | After emergency full |
| **Personal** | Discretionary spending | N/A | Gets remaining money (if selected) |
| **Joint** | Shared expenses | N/A | Linked expenses transfer here |

**Major Changes:**

1. **AccountType enum:** Renamed `checking` → `primary`, added behavioral meaning
2. **AccountEntry model:** Added `isPrimarySavings`, `emergencyMultiplier` (3.0-6.0), `currentBalance`
3. **RemainingMoneyDestination enum:** User chooses where remaining money goes (primarySavings, personal, primary)
4. **TransferCalculator rewrite:** Account-type-aware priority logic (emergency → savings → remaining)
5. **TransferPlan model:** New `AccountAllocation` struct replaces `GoalAllocation`
6. **Screen flow:** Renamed SavingsGoals → Savings; reordered to Accounts → Expenses → Savings → TransferPlan

**Files Created:**
- `SavingsScreen.swift` - Simplified savings configuration (slider + boost)
- `EmergencyMultiplierPicker.swift` - 3x-6x income multiplier selector
- `RemainingMoneyPicker.swift` - Destination selector for remaining money

**Files Completely Rewritten:**
- `TransferCalculator.swift` - New priority-based allocation algorithm
- `TransferPlan.swift` - New AccountAllocation struct
- `AccountRow.swift` - Expandable content for emergency/savings accounts

**Files Updated:**
- `OnboardingViewModel.swift` - Added remainingMoneyDestination, computed helpers for account types
- `UserProfile.swift` - Added remainingMoneyDestination persistence
- `Account.swift` - Added behavioral properties (isPrimarySavings, emergencyMultiplier, currentBalance)
- `AccountsScreen.swift` - Guided prompts for emergency + savings accounts
- `TransferPlanScreen.swift` - Remaining money destination picker
- `AccountTypeSelector.swift` - disableEmergency parameter

**Files Removed:**
- `SavingsGoalEntry.swift` - Replaced by account types
- `TargetType.swift` - Emergency multiplier now on AccountEntry
- `GoalCard.swift` - No longer needed
- `GoalTargetPicker.swift` - Replaced by EmergencyMultiplierPicker
- `SavingsGoalsScreen.swift` - Replaced by SavingsScreen
- `TransferCard.swift` - Inline cards in TransferPlanScreen
- `SavingsGoal.swift` - Removed from SwiftData schema

**Key Design Decisions:**
1. **One emergency account allowed** (enforced by disabling type in selector)
2. **Multiple savings accounts** but only ONE is "primary savings" for auto-allocation
3. **User chooses remaining money destination** on TransferPlanScreen
4. **Guided prompts** recommend emergency + savings but don't force

### 2025-12-28 - Bug Fixes & Flow Corrections Session

**Focus:** Fix critical bugs and ensure savings calculations match Python script logic.

**Critical Bugs Fixed:**

1. **Race condition on rapid taps:** Rapidly tapping "Add" on recommended accounts created multiple emergency accounts. Rapidly tapping delete crashed with index out of bounds.
   - **Root cause:** Index-based array mutations with captured indices became stale during animations
   - **Solution:** Changed to ID-based mutations (`removeAll { $0.id == id }`, `firstIndex(where: { $0.id == id })`)
   - **Prevention:** Added guard clauses to prevent duplicate emergency/primary savings accounts

2. **Ghost tap on invisible buttons:** Haptic feedback fired on Add buttons even when hidden during animation
   - **Solution:** Added `.disabled(viewModel.hasEmergencyAccount)` to buttons; moved haptic inside functions after guard check

3. **SavingsSlider not reflecting boost:** When Savings Boost enabled, slider showed base percentage amount instead of boosted (3x) amount
   - **Root cause:** `savingsAmount` used `percentage` directly instead of `effectivePercentage`
   - **Solution:** Added `boostEnabled` and `boostMultiplier` parameters to SavingsSlider

4. **Misleading savings screen:** Savings screen showed amounts before expenses were entered
   - **Root cause:** Flow order was Accounts → Savings → Expenses, but savings calculation needs expenses
   - **Solution:** Reordered to Accounts → Expenses → Savings; updated subtitle to clarify "from income after expenses"

5. **Savings boost could exceed income:** User could enable 3x boost at high savings rates (e.g., 40% × 3 = 120%)
   - **Solution:** Added `canEnableBoost` check (percentage × boostMultiplier ≤ 1.0); disabled toggle when invalid; auto-disable boost if user increases percentage past threshold; show orange warning "Lower your savings rate to enable boost"

**Files Modified:**
- `AccountsScreen.swift` - ID-based mutations, guard clauses, disabled buttons
- `SavingsSlider.swift` - Added boost parameters, effectivePercentage calculation
- `SavingsScreen.swift` - Pass boost state to slider, updated subtitle, boost safeguard with auto-disable
- `ExpensesScreen.swift` - Updated title from "Almost there!" to "Where does your money go?"
- `OnboardingViewModel.swift` - Swapped expenses/savings order in OnboardingStep enum

**Liquid Glass Enhancement:**
- Added `GlassEffectContainer` + `glassEffectID` to boost toggle card in SavingsScreen
- Warning text now morphs smoothly when boost is toggled (same pattern as AccountRow expand)

**Key Learnings:**
1. **ID-based mutations are safer:** Never capture array indices in closures for async/animated operations
2. **`.disabled()` prevents ghost interactions:** Use on buttons that animate away to prevent taps during transition
3. **Haptic placement matters:** Put haptic feedback after guard checks, not in button action
4. **Flow order affects data accuracy:** Screens that depend on previous data must come after that data is collected
5. **Cross-check with reference implementations:** Python script served as source of truth for calculation logic

**Verification Against Python Script:**
```python
# Python (correct)
baniLuna = monthlySalary - monthlyExpenses  # Available after expenses
savingsMultiplier = SAVINGS_PERCENTAGE * (SAVINGS_BOOST_MULTIPLIER if SAVINGS_BOOST else 1)
total_savings_potential = baniLuna * savingsMultiplier

# Swift (now matches)
availableIncome = monthlyIncome - expenses
effectivePercentage = boostEnabled ? percentage * boostMultiplier : percentage
savingsAmount = availableIncome * effectivePercentage
```

---

## How to Update This File

After completing a task:
1. Move it from "Next Up" or "In Progress" to "Completed" with date
2. Update the relevant status in MVP Feature Progress or Architecture Progress
3. Add any technical debt or notes discovered during implementation
