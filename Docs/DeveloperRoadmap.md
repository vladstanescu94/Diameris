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
| Test coverage expansion | 2025-12-28 | Added 217 tests across Onboarding (158) and Utilities (49) packages; Swift Testing framework patterns |
| Core/Domain package | 2025-12-28 | Extracted business logic from Onboarding: AccountType, AccountEntry, ExpenseEntry, SavingsAllocationEntry, RemainingMoneyDestination, TransferPlan, TransferCalculator |
| Dashboard package | 2025-12-28 | `Packages/Features/Dashboard/` with DashboardView, DashboardViewModel, NewMonthSheet, 3-step flow |
| Dashboard components | 2025-12-28 | SummaryCard, EmergencyProgressCard, AccountBalancesRow, ExpenseBreakdownCard |
| NewMonthFlow | 2025-12-28 | 3-step modal: SalaryEntryStep → ReconcileAccountsStep → TransferPlanStep |
| MonthlyRecord model | 2025-12-28 | SwiftData model for tracking monthly financial snapshots |
| Dashboard integration | 2025-12-28 | MainTabView updated to use real DashboardView; data bridging from SwiftData to Dashboard |
| Dashboard coding standards | 2025-12-28 | Fixed magic numbers, added balanceInputWidth constant, SpringPreset.responsive |
| CurrencyAmountField fix | 2025-12-28 | Fixed "RON" label wrapping with lineLimit(1) and fixedSize() |
| Dashboard Settings icon removed | 2025-12-28 | Removed non-functional gear icon from Dashboard toolbar |
| Expense transfer display | 2025-12-28 | Added "Transfer to Joint" rows for expense-linked accounts in both Dashboard and Onboarding |
| String.localized() extension | 2025-12-28 | Static function for interpolated strings: `String.localized("Hello \(name)")` |
| AccountBalancesSection redesign | 2025-12-28 | Primary account prominent with badge; other accounts in 2-column grid; emergency excluded |
| Auto-update balances on completion | 2025-12-28 | Onboarding completion auto-updates account balances based on transfer plan |
| Domain test migration | 2025-12-28 | Moved 4 test files (112 tests) from Onboarding to Domain package |
| iOS 26 TabBar enhancements | 2025-12-28 | Tab bar minimizes on scroll, "New Month" as tab accessory, Dev tools moved to Dashboard toolbar |
| Tab accessory button fix | 2025-12-28 | Fixed tap area with `.frame(maxWidth: .infinity)` + `.contentShape(.rect)` |
| Main app localization | 2025-12-28 | Added `Diameris/Utils/Localization.swift` and `Resources/Localizable.xcstrings` with "New Month" en/ro |
| Tab structure redesign | 2025-12-28 | Simplified from 4 tabs to 3: Dashboard, Expenses, Insights; removed Goals/Transfers (redundant with NewMonthFlow) |
| Settings sheet | 2025-12-28 | SettingsSheet accessible from Dashboard toolbar (gear icon); Profile, Savings, Accounts, Remaining Money sections |
| Settings coding standards | 2025-12-28 | Fixed magic numbers, removed duplicated AccountType extensions, fixed hardcoded currency |
| Hide scroll indicators | 2025-12-28 | Added `.scrollIndicators(.hidden)` to all ScrollViews/Forms app-wide; UIScrollView.appearance fallback |
| Settings→Dashboard refresh fix | 2025-12-28 | Added `onChange(of: showSettings)` to reload dashboard when settings sheet dismisses; fixes property mutations not triggering @Query onChange |
| Persistence package | 2025-12-29 | `Packages/Platform/Persistence/` with SwiftData models: Expense, Account, Income, UserProfile, SavingsAllocation, CustomCategory |
| Expenses feature | 2025-12-29 | Full Expenses management: category-based grouping, add/edit/delete expenses, frequency (monthly/annual), custom categories |
| Subcategory removal | 2025-12-29 | Simplified architecture from Category→Subcategory→Expense to Category→Expense; users define expenses within categories |
| Expenses haptics & animations | 2025-12-29 | HapticManager calls throughout Expenses feature; SpringPreset.snappy/responsive animations |
| Expense delete functionality | 2025-12-29 | Delete button in edit sheet with confirmation dialog; context menu as secondary option |
| Custom category search fix | 2025-12-29 | Search now finds expenses in custom categories by looking up from allCategories |
| Inline category creation | 2025-12-29 | "New Category..." button in AddExpenseSheet for creating categories without leaving expense form |
| Custom category display fix | 2025-12-29 | Fixed optimistic update race condition; loadExpensesData() now merges @Query with existing categories |
| Expense percentage fix | 2025-12-29 | Fixed 0% showing for all expenses; Decimal division issue resolved by converting to Double |
| Dashboard unit tests | 2025-12-29 | 55 tests covering DashboardViewModel and DashboardAccount: computed properties, account lookups, emergency fund calculations |
| Expenses unit tests | 2025-12-29 | 48 tests covering ExpensesViewModel: totals, search, CRUD, category toggle, UI state, custom categories |
| Expand/collapse all fix | 2025-12-29 | Fixed uncategorized expenses not responding to expand/collapse all; `ExpenseGroup` now uses stable `uncategorizedId` sentinel UUID instead of random `UUID()` |
| Dev tools JSON import | 2025-12-29 | Import expenses from Python script via JSON; `--export` flag saves to `Resources/expenses_import.json`, `ExpenseImportData` model in Domain, one-tap import in DevDebugView loads from bundle |
| Dashboard monthly amounts fix | 2025-12-29 | Fixed Dashboard showing annual totals instead of monthly; changed `expense.amount` → `expense.monthlyAmount` in MainTabView |
| Dashboard summary card redesign | 2025-12-29 | Renamed "Available This Month" → "Monthly Summary"; now shows Income, Expenses, Savings, and Personal Spending (true flexible money after savings) |
| JSON import with accounts | 2025-12-29 | Extended import to include accounts; matches by type, updates existing or creates new; exports 5 ING accounts (Primary, Joint, Emergency, Savings, Personal) |
| JSON import savings allocation | 2025-12-29 | Import now includes savings config (percentage, boostEnabled, boostMultiplier); fixed Dashboard showing wrong Personal Spending due to missing boost setting |
| JSON import balance reset | 2025-12-29 | Import now resets account balances to match JSON values (including 0); previously preserved non-zero existing balances which caused stale data |
| Expense-to-account linking in Expenses feature | 2025-12-29 | Added account picker to AddExpenseSheet; expenses can now be linked to specific accounts (like Joint) just like in onboarding |
| New Month flow completion | 2025-12-29 | Flow now actually persists changes! Recalculates transfer plan with entered income, updates account balances, updates income if changed |
| New Month UX fixes | 2025-12-29 | Fixed balance input width (now full-width), added tap-to-dismiss keyboard on SalaryEntryStep and ReconcileAccountsStep |
| Fix "Unknown Account" in transfer plan | 2025-12-29 | AccountEntry conversion was missing `id: account.id`, causing expense linkedAccountId lookup to fail |
| Fix stale data in New Month flow | 2025-12-29 | Added `loadDashboardData()` call before opening New Month flow; SwiftData @Query doesn't trigger onChange for property updates on existing objects |
| Data Inspector linkedAccountId display | 2025-12-29 | Added linked account name display (in blue) for expenses in Dev Tools Data Inspector |
| Centralized state management | 2025-12-29 | DataObserver class listens to ModelContext.didSave, replaces 5 scattered onChange handlers with single refreshAllData() call |
| Dashboard unit tests updated | 2025-12-29 | Added 5 tests for calculateTransferPlan(withIncome:) method; total 60 tests now covering transfer plan calculation with custom income |

### In Progress

| Task | Notes |
|------|-------|
| - | - |

### Next Up

| Priority | Task | Reference |
|----------|------|-----------|
| 1 | Test full onboarding → Dashboard → Expenses flow | Verify data flows correctly through all features |
| 2 | Implement Insights feature | Stats, AI tips (Foundation Models), scenario analysis |

---

## MVP Feature Progress

Based on [MVP Overview](./MVP/00-MVP-Overview.md)

| # | Feature | Status | Spec | Notes |
|---|---------|--------|------|-------|
| 01 | Onboarding | Done | [01-Onboarding.md](./MVP/01-Onboarding.md) | Polished with animations, haptics, glass morphing |
| 02 | Income | In Progress | [02-Income.md](./MVP/02-Income.md) | Basic model + Dashboard display done |
| 03 | Expenses | Done | [03-Expenses.md](./MVP/03-Expenses.md) | Full CRUD, category grouping, frequency support, haptics |
| 04 | Categories | Done | [04-Categories.md](./MVP/04-Categories.md) | Default + custom categories; simplified (no subcategories) |
| 05 | Emergency Fund | In Progress | [05-EmergencyFund.md](./MVP/05-EmergencyFund.md) | Progress tracking in Dashboard |
| 06 | Loans | Not Started | [06-Loans.md](./MVP/06-Loans.md) | |
| 07 | Savings | In Progress | [07-Savings.md](./MVP/07-Savings.md) | Basic allocation + Dashboard display |
| 08 | Accounts | In Progress | [08-Accounts.md](./MVP/08-Accounts.md) | Account types with behavioral meaning; Dashboard display |
| 09 | Transfer Planning | In Progress | [09-TransferPlanning.md](./MVP/09-TransferPlanning.md) | TransferCalculator + NewMonthFlow |
| 10 | Budget Analysis | Not Started | [10-BudgetAnalysis.md](./MVP/10-BudgetAnalysis.md) | |
| 11 | Settings | Done | [11-Settings.md](./MVP/11-Settings.md) | Dashboard toolbar sheet; Profile, Savings, Accounts, Remaining Money |

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
| Core | Domain | Done | AccountType, AccountEntry, ExpenseEntry, ExpenseCategory, Frequency, SavingsAllocationEntry, RemainingMoneyDestination, TransferPlan, TransferCalculator |
| Domain | Repositories | Not Started | Protocol definitions |
| Platform | Persistence | Done | SwiftData models: Expense, Account, Income, UserProfile, SavingsAllocation, CustomCategory |
| Features | Onboarding | Done | 7-screen flow, SwiftData models, ViewModel, microinteractions, celebrations |
| Features | Dashboard | Done | DashboardView, NewMonthSheet, 3-step flow, MonthlyRecord model |
| Features | Expenses | Done | ExpenseListView, AddExpenseSheet, CategoryManagementView; category grouping, CRUD, haptics |
| Features | Insights | Not Started | Placeholder view; AI tips via Foundation Models, scenario analysis |
| Features | Settings | Done | SettingsSheet in Dashboard toolbar; Profile, Savings, Accounts, Remaining Money; coding standards compliant |

### App Infrastructure

| Component | Status | Notes |
|-----------|--------|-------|
| DependencyContainer | Not Started | Manual DI composition root |
| AppRouter | Not Started | Navigation state management |
| MainTabView | Done | 3 tabs (Dashboard, Expenses, Insights) + NewMonth accessory |
| Onboarding flow | Done | Forward-only, UserDefaults flag, SwiftData persistence, polished UX |

---

## Technical Debt & Notes

- Animation constants in DesignSystem; well-organized for reuse across features
- Expenses feature needs unit tests (ExpensesViewModelTests.swift)
- Dashboard feature needs unit tests (DashboardViewModelTests.swift)
- Consider adding expense sorting/reordering within categories

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

### 2025-12-28 - Test Coverage Session

**Focus:** Comprehensive unit test coverage for Onboarding and Utilities packages using Swift Testing framework.

**Test Summary:**
- **Onboarding package:** 158 tests in 45 suites
- **Utilities package:** 49 tests in 14 suites
- **DesignSystem package:** 10 tests in 5 suites (existing)
- **Total:** 217 new tests

**New Test Files Created:**
1. `TransferCalculatorTests.swift` (~320 lines) - Core business logic tests
   - Basic calculations, priority-based allocation
   - Emergency account fills before savings
   - Boost mode (3x multiplier)
   - Expense distribution to linked accounts
   - Remaining money allocation
   - Real-world scenarios with typical Romanian salaries

2. `AccountEntryTests.swift` - Account model tests
   - Emergency target calculations (income × multiplier)
   - Progress tracking (current balance / target)
   - Factory methods (.primary(), .emergency(), .savings(), etc.)

3. `SavingsAllocationEntryTests.swift` - Savings configuration tests
   - Percentage calculations
   - Boost multiplier logic (effectivePercentage)
   - Validation rules (5%-50% range)
   - Display formatting

4. `AccountTypeTests.swift` - Enum behavior tests
   - Behavioral properties (canBeLinkedToExpenses, hasTarget)
   - Uniqueness rules (only one primary, one emergency)
   - Codable/Sendable conformance

5. `OnboardingViewModelTests.swift` (rewritten) - ViewModel tests
   - 7-screen flow navigation
   - Step validation (name, income, accounts)
   - Computed properties (progress, account helpers)
   - Transfer plan integration

6. `CurrencyTests.swift` - Currency enum tests
   - Raw values, symbols, display names
   - Locale detection
   - Sendable conformance

7. `AmountFormatterTests.swift` - Formatter tests
   - Display formatting (thousands separator, currency suffix)
   - Edit formatting (no grouping, preserves decimals)
   - Parsing (handles both . and , decimal separators)
   - Round-trip consistency

**Swift Testing Framework Patterns Used:**
```swift
@Suite("Feature Tests")
struct FeatureTests {
    @Test("Description", arguments: [...])
    func testName(param: Type) {
        #expect(result == expected)
    }
}
```

**Key Learnings:**
1. **`@MainActor` propagation:** Must add `@MainActor` to EVERY nested `@Suite` struct, not just parent
2. **Floating point comparisons:** Use `#expect(abs(a - b) < 0.0001)` for Decimal precision
3. **Locale-independent tests:** Check for presence of digits rather than exact formatted strings
4. **Type inference in arrays:** Explicit type needed: `let accounts: [AccountEntry] = [.primary()]`
5. **`Decimal(string:)` behavior:** Parses partial strings ("12abc" → 12), doesn't fail on mixed input

**Files Pattern:**
```
Package/Tests/PackageTests/
├── ModuleNameTests.swift       # Main test file for that module
└── FeatureNameTests.swift      # Feature-specific tests
```

### 2025-12-28 - Dashboard Feature Implementation Session

**Focus:** Build the Dashboard feature as the central hub for monthly financial flow.

**Architecture Changes:**
1. **Created Core/Domain package:** Extracted shared business logic from Onboarding to ensure Dashboard doesn't duplicate code
   - Moved: AccountType, AccountEntry, ExpenseEntry, SavingsAllocationEntry, RemainingMoneyDestination, TransferPlan, TransferCalculator
   - Updated Onboarding to depend on Domain
   - All 158 Onboarding tests still pass after extraction

2. **Created Features/Dashboard package:** New feature package with proper dependencies
   - Dependencies: Domain, DesignSystem, SharedUI, Utilities
   - Folder structure: Views, ViewModels, Components, Models, Utils, Resources

**Dashboard Components Created:**
- `DashboardView` - Main tab content with financial summary
- `DashboardViewModel` - State management and data bridging
- `SummaryCard` - Income/expenses/available breakdown
- `EmergencyProgressCard` - Progress ring + emergency fund info
- `AccountBalancesRow` - Compact account balance display
- `ExpenseBreakdownCard` - Expense category breakdown

**NewMonthFlow (3-step modal):**
- `NewMonthSheet` - Container with step navigation
- `SalaryEntryStep` - Enter monthly salary
- `ReconcileAccountsStep` - Update account balances (emergency, savings, personal)
- `TransferPlanStep` - Review and confirm transfers

**Data Models:**
- `MonthlyRecord` (SwiftData) - Tracks monthly financial snapshots
- `AccountSnapshot` (Codable) - Embedded in MonthlyRecord
- `DashboardAccount` / `DashboardExpense` - Simplified view models

**Integration:**
- MainTabView updated to use real DashboardView
- Data bridging: SwiftData models → DashboardViewModel via direct property assignment
- Dashboard package added to Xcode project

**Package Structure After Session:**
```
Packages/
├── Core/
│   ├── DesignSystem/     # Design tokens, glass effects
│   ├── SharedUI/         # Reusable view components
│   ├── Utilities/        # Haptics, formatters, value types
│   └── Domain/           # Business logic & entities (NEW)
└── Features/
    ├── Onboarding/       # Depends on Domain
    └── Dashboard/        # Depends on Domain (NEW)
```

**Remaining Step:**
- Add Dashboard framework to Diameris target in Xcode:
  1. Select Diameris target → General tab
  2. Scroll to "Frameworks, Libraries, and Embedded Content"
  3. Click "+" and add "Dashboard"

### 2025-12-28 - Dashboard Polish & Auto-Balance Session

**Focus:** Fix Dashboard UI issues, add expense transfer display, auto-update balances on onboarding completion.

**Issues Fixed:**

1. **CurrencyAmountField "RON" wrapping:** Currency label wrapped to two lines ("RO" / "N") when container too narrow
   - **Solution:** Added `.lineLimit(1)` and `.fixedSize(horizontal: true, vertical: false)` to currency text

2. **Non-functional Settings gear:** Dashboard had settings icon that did nothing
   - **Solution:** Removed toolbar button and unused localization

3. **Expense-linked transfers not shown:** Joint account transfers (for linked expenses like Food) weren't displayed
   - **Solution:** Added `expenseTransferRow` showing "Transfer to Joint" + "for Food" in both Dashboard and Onboarding

4. **Account balances UI issues:** Emergency shown twice, accounts crammed in one row, labels truncated
   - **Solution:** Redesigned `AccountBalancesSection`:
     - Primary account: prominent card with "Primary" badge
     - Other accounts: 2-column grid with `.minimumScaleFactor(0.8)`
     - Emergency excluded (already in EmergencyProgressCard)

**New Features:**

1. **String.localized() for interpolation:** Added static function to Localization.swift
   ```swift
   // Before (verbose)
   String(localized: "Transfer to \(name)", bundle: .module)

   // After (clean)
   String.localized("Transfer to \(name)")
   ```

2. **Auto-update balances on completion:** When onboarding finishes, account balances are updated assuming user made the transfers:
   - Emergency account: +allocation amount
   - Savings account: +allocation amount
   - Joint accounts: +expense transfer amounts
   - Primary account: set to remainsInPrimary
   - Remaining money destination: +remaining amount

**Coding Standards Applied:**
- Fixed magic numbers: `.font(.system(size: 48))` → `.iconXl()`
- Fixed magic spring: `.spring(response: 0.3)` → `SpringPreset.responsive`
- Added `ComponentSize.balanceInputWidth: 160` constant

**Files Modified:**
- `SharedUI/CurrencyAmountField.swift` - lineLimit fix
- `Dashboard/DashboardView.swift` - removed settings toolbar
- `Dashboard/TransferPlanStep.swift` - expense transfer rows
- `Dashboard/AccountBalancesRow.swift` → `AccountBalancesSection.swift` - complete redesign
- `Onboarding/TransferPlanScreen.swift` - clearer expense transfer text
- `Onboarding/OnboardingViewModel.swift` - auto-update balances in save()
- `Onboarding/Utils/Localization.swift` - String.localized() static function
- `Dashboard/Utils/Localization.swift` - String.localized() static function

### 2025-12-28 - Domain Test Migration Session

**Focus:** Move unit tests from Onboarding to Domain package to keep tests with the code they test.

**Tests Moved:**
| File | Tests | Description |
|------|-------|-------------|
| `TransferCalculatorTests.swift` | 33 | Core transfer calculation logic |
| `AccountEntryTests.swift` | 27 | Account model, emergency target/progress |
| `AccountTypeTests.swift` | 33 | Enum behavior, uniqueness, display properties |
| `SavingsAllocationEntryTests.swift` | 35 | Savings percentage, boost mode, validation |

**Test Counts After Migration:**
- **Domain:** 112 tests passed
- **Onboarding:** 46 tests passed (down from 158)
- **Total:** 158 tests (unchanged, just relocated)

**Changes Made:**
1. Created `Packages/Core/Domain/Tests/DomainTests/` directory
2. Wrote 4 test files with updated imports (`@testable import Domain` instead of `@testable import Onboarding`)
3. Deleted original files from `Packages/Features/Onboarding/Tests/OnboardingTests/`
4. Verified both packages' tests pass

**Principle Applied:** Tests should live with the code they test. Domain entities and calculators now have their tests in the Domain package.

### 2025-12-28 - Tab Structure Redesign Session

**Focus:** Simplify tab structure based on feature analysis vs Python script.

**Analysis:**
The Python script (`expensesScriptDetailed.py`) provides:
- Expense tracking with categories (auto, subscriptii, pisica, sala, lifestyle)
- Emergency fund tracking with 3x income target
- Savings with boost mode
- Transfer planning to sub-accounts (Joint, Emergency, Savings, Personal)
- Budget analysis and optimization tips (`analiza_optimizari()`)
- Scenario analysis and financial benchmarks

**Finding:** With Onboarding capturing initial data and NewMonthSheet handling monthly transfers, the original 4-tab structure had redundancy:
- Goals tab → Emergency fund already on Dashboard
- Transfers tab → NewMonthSheet already handles this

**New Tab Structure:**
| Tab | Purpose |
|-----|---------|
| **Dashboard** | Overview, emergency progress, quick actions, NewMonth trigger |
| **Expenses** | CRUD for expenses with categories/subcategories |
| **Insights** | Deep stats, AI-powered tips (Foundation Models), scenario analysis |

**Key Decisions:**
1. **Loans = Expenses**: Loans tracked as recurring expenses, not separate feature
2. **Settings in toolbar**: Not a separate tab, accessible from Dashboard
3. **AI-enhanced Insights**: Foundation Models for personalized tips when available, with fallback to rule-based tips

**Files Modified:**
- `Docs/ProjectDefinition.md` - Updated UI Structure section
- `Diameris/Features/Main/MainTabView.swift` - 3 tabs, renamed placeholders
- `Diameris/Resources/Localizable.xcstrings` - Added Dashboard, Expenses, Insights, Coming soon translations

**Romanian Translations:**
- Dashboard → Panou
- Expenses → Cheltuieli
- Insights → Analize
- Coming soon → În curând

### 2025-12-28 - Settings Sheet Implementation

**Focus:** Add settings accessible from Dashboard toolbar to edit configuration values.

**Decision:** Option B chosen - gear icon in Dashboard toolbar opens a settings sheet. Keeps 3-tab simplicity while providing full access to configuration.

**Settings Sections:**
1. **Profile** - Name, Currency
2. **Savings** - Percentage slider (5-50%), Boost toggle, Boost multiplier (2×/3×)
3. **Accounts** - List of accounts with tap-to-edit; AccountEditorSheet for type, name, balance, emergency multiplier
4. **Remaining Money** - Destination picker (Primary Savings, Personal, Primary)

**Architecture:**
- `DashboardView` receives `onSettingsTapped` callback (like `onDevToolsTapped`)
- `SettingsSheet` lives in main app (`Diameris/Features/Settings/`) where SwiftData is available
- Changes save directly to SwiftData models

**Files Created:**
- `Diameris/Features/Settings/SettingsSheet.swift` - Main settings with AccountEditorSheet

**Files Modified:**
- `Dashboard/DashboardView.swift` - Added `onSettingsTapped` parameter and toolbar button
- `Diameris/Features/Main/MainTabView.swift` - Wired up settings sheet
- `Diameris/Resources/Localizable.xcstrings` - 40+ new localized strings for settings UI

### 2025-12-28 - Settings Coding Standards Session

**Focus:** Ensure SettingsSheet follows project coding standards from CLAUDE.md.

**Issues Found & Fixed:**

1. **Magic numbers:**
   - `spacing: 2` → `Spacing.xxs` (4pt grid system)
   - `.frame(width: 100)` → `ComponentSize.segmentedControlCompact`
   - `.frame(width: 120)` → `ComponentSize.mediumInputWidth`

2. **New constant added to DesignSystem:**
   - `ComponentSize.segmentedControlCompact: CGFloat = 100` - for compact 2-option segmented controls

3. **Duplicated extensions removed:**
   - AccountType.icon and AccountType.displayName already exist in Domain
   - Removed duplicates from SettingsSheet, kept only `.color` (SwiftUI-specific, not in Domain)

4. **Hardcoded currency fixed:**
   - AccountEditorSheet was hardcoded to "RON" for emergency target display
   - Added `currency: Currency` parameter to AccountEditorSheet
   - Now uses user's selected currency from SettingsSheet

**Key Principles Applied:**
- No magic numbers: Use constants from DesignSystem (Spacing, ComponentSize)
- No duplication: Domain package is source of truth for AccountType properties
- Leverage SPM: Check existing packages before adding code

**Files Modified:**
- `DesignSystem/ComponentSize.swift` - Added segmentedControlCompact
- `Diameris/Features/Settings/SettingsSheet.swift` - All fixes applied

### 2025-12-29 - Expenses Feature & Subcategory Removal Session

**Focus:** Complete Expenses feature implementation and simplify category architecture by removing subcategories.

**Major Changes:**

1. **Platform/Persistence Package Created:**
   - SwiftData models: Expense, Account, Income, UserProfile, SavingsAllocation, CustomCategory
   - Public typealiases for entity access from main app
   - Unit tests for all models

2. **Expenses Feature Package:**
   - `ExpenseListView` - Main list with category grouping, collapsible sections, monthly/annual toggle
   - `AddExpenseSheet` - Form for creating/editing expenses with category picker, icon picker, frequency
   - `CategoryManagementView` - Default categories (non-deletable) + custom categories (editable)
   - `ExpensesViewModel` - Observable state with callback-based persistence
   - Components: `ExpenseCategoryCard`, `ExpenseItemRow`, `CategoryPicker`, `FrequencyPicker`

3. **Subcategory Removal (Architecture Simplification):**
   - **Before:** Category → Subcategory → Expense (too complex, felt unnatural)
   - **After:** Category → Expense (users define any expense within a category)
   - User's philosophy: "For Food, add Groceries, Takeout, etc. For Auto, add Gas, Insurance, Car Wash, etc."

**Files Deleted:**
- `Domain/Entities/Subcategory.swift`
- `Domain/Tests/SubcategoryTests.swift`
- `Persistence/Models/CustomSubcategory.swift`
- `Expenses/Components/SubcategoryPicker.swift`

**Files Modified for Subcategory Removal:**
- `Domain/Entities/ExpenseEntry.swift` - Removed subcategoryId
- `Persistence/Models/Expense.swift` - Removed subcategoryId
- `Expenses/ViewModels/ExpensesViewModel.swift` - Removed subcategory handling
- `Expenses/Views/AddExpenseSheet.swift` - Removed SubcategoryPicker
- `Expenses/Components/ExpenseItemRow.swift` - Removed subcategory display
- `Expenses/Views/CategoryManagementView.swift` - Removed subcategory management
- `MainTabView.swift` - Removed subcategory callbacks and loading
- `OnboardingViewModel.swift` - Removed subcategoryId from expense creation
- Test files updated to remove subcategory references

**Haptics & Animations Added:**
- `HapticManager.lightTap()` on buttons, row taps, icon/color selection
- `HapticManager.selectionChanged()` on toggles, pickers
- `HapticManager.success()` on save actions
- `HapticManager.warning()` on delete actions
- `SpringPreset.snappy` for expand/collapse animations
- `SpringPreset.responsive` for toolbar actions
- Numeric text transition for total amount display

**Optimistic UI Updates:**
- `saveExpense()` updates local state immediately before persisting
- `deleteExpense()` removes from array immediately
- `toggleExpenseEnabled()` toggles immediately
- Fixes "edit doesn't reflect until restart" issue

**Key Design Decisions:**
1. **No subcategories:** Users define their own expense items within categories
2. **Default categories immutable:** Auto/Transport, Subscriptions, Lifestyle, Housing, Pets, Health/Fitness, Food
3. **Custom categories:** Users can add their own with custom icon and color
4. **Callback-based persistence:** ViewModel uses closures injected by MainTabView for CRUD operations
5. **Frequency support:** Monthly or Annual with automatic conversion for display

**Files Created:**
```
Packages/Platform/Persistence/
├── Sources/Persistence/
│   ├── Persistence.swift
│   └── Models/
│       ├── Expense.swift
│       ├── Account.swift
│       ├── Income.swift
│       ├── UserProfile.swift
│       ├── SavingsAllocation.swift
│       └── CustomCategory.swift
└── Tests/PersistenceTests/
    └── PersistenceTests.swift

Packages/Features/Expenses/
├── Sources/Expenses/
│   ├── Expenses.swift
│   ├── Views/
│   │   ├── ExpenseListView.swift
│   │   ├── AddExpenseSheet.swift
│   │   └── CategoryManagementView.swift
│   ├── ViewModels/
│   │   └── ExpensesViewModel.swift
│   ├── Components/
│   │   ├── ExpenseCategoryCard.swift
│   │   ├── ExpenseItemRow.swift
│   │   ├── CategoryPicker.swift
│   │   └── FrequencyPicker.swift
│   ├── Utils/
│   │   └── Localization.swift
│   └── Resources/
│       └── Localizable.xcstrings
└── Tests/ExpensesTests/
```

**Domain Package Updates:**
- `ExpenseCategory.swift` - Default categories with stable UUIDs
- `Frequency.swift` - Monthly/Annual with multipliers

**Delete Expense Feature:**
- **Problem:** `.swipeActions` only works inside `List`, but expenses are in `LazyVStack` within custom glass cards
- **Solution:** Two deletion methods implemented:
  1. **Edit Sheet (Primary):** Red "Delete Expense" button at bottom of edit form with confirmation dialog
  2. **Context Menu (Secondary):** Long-press reveals Edit/Delete options for power users
- **UX Pattern:** Follows iOS conventions (like editing contacts/calendar events)
- **Files Modified:** `AddExpenseSheet.swift`, `ExpenseItemRow.swift`, `Localizable.xcstrings`

### 2025-12-29 - Expenses Bug Fixes Session

**Focus:** Fix various bugs discovered during expenses feature testing.

**Issues Fixed:**

1. **Search not finding custom categories:**
   - **Problem:** Searching for an expense by its custom category name didn't work
   - **Root cause:** `filteredExpenses` was using `expense.category` computed property which only checked defaults
   - **Solution:** Changed to look up from `allCategories` (defaults + customCategories) by expense.categoryId
   - **File:** `ExpensesViewModel.swift`

2. **Category creation too obfuscated:**
   - **Problem:** Users had to go through Categories menu to create custom categories
   - **Solution:** Added "New Category..." button directly in CategoryPicker section of AddExpenseSheet
   - **UX:** Category is automatically selected for the expense after creation
   - **Files:** `AddExpenseSheet.swift`, `CategoryManagementView.swift` (AddCategorySheet onCategoryCreated callback)

3. **Custom categories showing as "Uncategorized":**
   - **Problem:** After creating a custom category and saving an expense with it, the expense appeared under "Uncategorized"
   - **Root cause:** Race condition between @Query updates and optimistic UI updates
   - **Sequence:**
     1. User creates category → optimistic update to `customCategories`
     2. User saves expense with that categoryId
     3. `onChange(of: expenses)` fires before `onChange(of: customCategories)`
     4. `loadExpensesData()` overwrites `customCategories` with stale @Query result
     5. Category not found → expense shows as "Uncategorized"
   - **Solution:** Modified `loadExpensesData()` to merge @Query results with existing optimistic updates instead of replacing:
     ```swift
     let queriedCategories = customCategories.map { $0.toCategory() }
     let queriedIds = Set(queriedCategories.map { $0.id })
     let existingOptimistic = expensesViewModel.customCategories.filter { !queriedIds.contains($0.id) }
     expensesViewModel.customCategories = queriedCategories + existingOptimistic
     ```
   - **File:** `MainTabView.swift`

4. **"New Category" button not tappable:**
   - **Problem:** Button was inside VStack with Picker, Picker captured all taps
   - **Solution:** Moved button to separate row in Form section
   - **File:** `AddExpenseSheet.swift`

**Key Learnings:**
1. **@Query timing is non-deterministic:** Different @Query properties may update in different order after SwiftData changes
2. **Merge vs Replace for optimistic updates:** When loading data from persistence, merge with existing local state instead of replacing
3. **Picker captures container taps:** Interactive elements in same container as Picker need separate Form rows
4. **Decimal division quirks:** Swift's Decimal division can produce unexpected results; convert to Double for percentage calculations
5. **Single source of truth:** Computed values like `totalExpenses` should be computed once and passed down, not recomputed in child views

**Files Modified:**
- `MainTabView.swift` - Merge logic for customCategories
- `ExpensesViewModel.swift` - Search across allCategories
- `AddExpenseSheet.swift` - Inline category creation button
- `CategoryManagementView.swift` - AddCategorySheet onCategoryCreated callback

5. **Expense breakdown percentages showing 0%:**
   - **Problem:** All expenses in Dashboard's ExpenseBreakdownCard showed "0%" despite having correct amounts
   - **Root cause:** Decimal arithmetic producing unexpected results when dividing `expense.amount / totalExpenses * 100`
   - **Investigation:** Added debug output showing `totalExpenses` was correct (5,150), but percentage still 0%
   - **Solution:** Convert Decimal to Double before division:
     ```swift
     let amount = NSDecimalNumber(decimal: expense.amount).doubleValue
     let total = NSDecimalNumber(decimal: totalExpenses).doubleValue
     return Int((amount / total) * 100)
     ```
   - **Also applied:** Single source of truth - `totalExpenses` now passed from `DashboardViewModel` instead of computed locally in `ExpenseBreakdownCard`
   - **Files:** `ExpenseBreakdownCard.swift`, `DashboardView.swift`

### 2025-12-29 - JSON Import Fixes Session

**Focus:** Fix JSON import to properly update all data including savings allocation and account balances.

**Issues Fixed:**

1. **Dashboard showing wrong Personal Spending (7500 RON):**
   - **Problem:** After import, Dashboard showed ~7500 RON personal spending instead of ~1599 RON
   - **Root cause:** Import didn't update SavingsAllocation model; app used default `boostEnabled: false` (25% savings) instead of user's `boostEnabled: true` (75% savings with 3x boost)
   - **Solution:** Added savings allocation import to DevDebugView - creates or updates SavingsAllocation with percentage, boostEnabled, boostMultiplier from JSON
   - **File:** `DevDebugView.swift`

2. **Account balances not resetting:**
   - **Problem:** Existing account balances persisted after import even when JSON had 0 values
   - **Root cause:** Import logic had `if accountData.currentBalance > 0` guard that skipped 0 balances
   - **Rationale (original):** "preserve manual balances" - but this caused stale data on fresh imports
   - **Solution:** Removed the guard; import now always sets balance to JSON value
   - **File:** `DevDebugView.swift`

**Import Now Handles:**
- Expenses (delete existing, create new)
- Accounts (match by type, update or create)
- Savings allocation (update or create)
- All balances reset to JSON values

**Files Modified:**
- `Diameris/Features/Dev/DevDebugView.swift` - Added savings import, removed balance guard, added SavingsAllocation to clearAllData() and preview

### 2025-12-29 - Expense-to-Account Linking Session

**Focus:** Add missing expense-to-account linking functionality to Expenses feature (was only in Onboarding).

**Problem:** Onboarding allowed linking expenses to specific accounts (e.g., "Food" paid from "Joint"), but the Expenses feature's AddExpenseSheet didn't have this capability.

**Changes Made:**

1. **ExpensesViewModel** (`ExpensesViewModel.swift`):
   - Added `ExpenseAccount` struct for simplified account representation
   - Added `accounts: [ExpenseAccount]` property

2. **AddExpenseSheet** (`AddExpenseSheet.swift`):
   - Added "Account" section with Picker for linking expense to account
   - Shows "Primary" option (nil = main account) plus all non-primary accounts
   - Footer explains purpose: "Choose which account this expense is paid from"

3. **MainTabView** (`MainTabView.swift`):
   - Added account loading in `loadExpensesData()` - converts SwiftData Account models to `ExpenseAccount`

4. **Localization** (`Localizable.xcstrings`):
   - Added: "Pay From", "Primary", "Account", "Choose which account this expense is paid from"
   - Romanian translations included

**Files Modified:**
- `Packages/Features/Expenses/Sources/Expenses/ViewModels/ExpensesViewModel.swift`
- `Packages/Features/Expenses/Sources/Expenses/Views/AddExpenseSheet.swift`
- `Diameris/Features/Main/MainTabView.swift`
- `Packages/Features/Expenses/Sources/Expenses/Resources/Localizable.xcstrings`

### 2025-12-29 - New Month Flow Completion Session

**Focus:** Make the New Month flow actually work - persist changes, recalculate transfer plan, update account balances.

**Problem:** The New Month flow had `// TODO: Save MonthlyRecord and update account balances` in `completeFlow()` - it just dismissed without doing anything!

**What Now Works:**

1. **Dynamic Transfer Plan:**
   - Transfer plan recalculates when user enters different income in Step 1
   - `DashboardViewModel.calculateTransferPlan(withIncome:)` method added
   - Step 3 shows the plan based on the NEW income, not the stored one

2. **Completion Callback:**
   - `NewMonthCompletionData` struct holds income, transfer plan, reconciled balances
   - `NewMonthSheet` takes `onComplete` callback
   - Data passed back to MainTabView for SwiftData persistence

3. **Account Balance Updates:**
   - Emergency account: +allocation amount
   - Savings account: +allocation amount
   - Joint/linked accounts: +expense transfer amounts
   - Remaining money destination (Savings/Personal): +remaining amount
   - Primary account: Set to `remainsInPrimary` (what stays for expenses)

4. **Income Update:**
   - If user enters different income than stored, it updates the Income record

**Architecture:**
```
NewMonthSheet                    MainTabView
     │                               │
     │ Step 1: Enter income          │
     │ Step 2: Reconcile balances    │
     │ Step 3: Review plan           │
     │                               │
     │──── onComplete(data) ────────▶│
     │                               │
                              handleNewMonthCompletion()
                                     │
                              updateAccountBalances()
                                     │
                              modelContext.save()
```

**Files Modified:**
- `Packages/Features/Dashboard/Sources/Dashboard/ViewModels/DashboardViewModel.swift`
  - Added `calculateTransferPlan(withIncome:)` method
  - Added `NewMonthCompletionData` struct

- `Packages/Features/Dashboard/Sources/Dashboard/Views/NewMonthSheet.swift`
  - Added `onComplete` callback parameter
  - Added `calculatedPlan` state for dynamic recalculation
  - `completeFlow()` now creates completion data and calls callback

- `Diameris/Features/Main/MainTabView.swift`
  - Added `handleNewMonthCompletion(_:)` method
  - Added `updateAccountBalances(from:)` method
  - Updated sheet presentation to provide completion callback

**Key Design Decisions:**
1. Balance updates are ADDITIVE (+=) for transfers, not replacements
2. Primary account balance is SET (=) to `remainsInPrimary`, not added
3. Transfer plan recalculates on step advance, not on every keystroke
4. Haptic feedback on successful completion

### 2025-12-29 - Centralized State Management Session

**Focus:** Replace scattered `loadDashboardData()` and `loadExpensesData()` calls with a centralized notification-based approach.

**Problem:** MainTabView had 5+ separate `onChange` handlers that each called reload methods. This was:
- Hard to maintain (logic scattered across file)
- Error-prone (easy to forget adding a handler for new @Query)
- Redundant (same data often loaded multiple times)

**Solution:** Created `DataObserver` class that listens to `ModelContext.didSave` notifications.

**Implementation:**

1. **DataObserver.swift** (new file):
   ```swift
   @Observable
   @MainActor
   final class DataObserver {
       var onDataChanged: (() -> Void)?
       private var notificationTask: Task<Void, Never>?

       func startObserving(modelContext: ModelContext) {
           notificationTask = Task { @MainActor [weak self] in
               let notifications = NotificationCenter.default.notifications(
                   named: ModelContext.didSave
               )
               for await _ in notifications {
                   guard !Task.isCancelled else { break }
                   self?.onDataChanged?()
               }
           }
       }

       func stopObserving() {
           notificationTask?.cancel()
           notificationTask = nil
       }
   }
   ```

2. **MainTabView changes:**
   - Added `@State private var dataObserver = DataObserver()`
   - Removed 5 separate `onChange(of:)` handlers for userProfiles, accounts, expenses, savingsAllocations, customCategories
   - Added single `refreshAllData()` method
   - Setup DataObserver on `onAppear`, cleanup on `onDisappear`

**Benefits:**
- Single source of data refresh logic
- Automatic refresh when ANY SwiftData model changes
- Cleaner code (90→65 lines in body section)
- No missed updates from forgotten onChange handlers

**Key Learnings:**
1. **Swift 6 concurrency:** Use `@MainActor` annotation on Task closure to access MainActor properties from async context
2. **deinit not needed:** For `@Observable` classes with `@MainActor`, rely on `stopObserving()` in `onDisappear` rather than deinit (which can't access MainActor properties)
3. **NotificationCenter.notifications():** Modern async/await API for observing notifications

**Files Created:**
- `Diameris/Features/Main/DataObserver.swift`

**Files Modified:**
- `Diameris/Features/Main/MainTabView.swift` - Replaced onChange handlers with DataObserver

---

## How to Update This File

After completing a task:
1. Move it from "Next Up" or "In Progress" to "Completed" with date
2. Update the relevant status in MVP Feature Progress or Architecture Progress
3. Add any technical debt or notes discovered during implementation
