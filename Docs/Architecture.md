# Diameris - SPM Modular Architecture

## Overview

Diameris uses a **modular architecture** with local Swift Package Manager (SPM) packages, following Clean Architecture and SOLID principles. This enables faster builds, better code organization, and easier testing.

---

## Layer Overview

```
┌─────────────────────────────────────────────────────────┐
│                      App Target                          │
│            (DiamerisApp - composition root)              │
├─────────────────────────────────────────────────────────┤
│                    Features Layer                        │
│     Dashboard │ Budget │ Goals │ Transfers │ Settings   │
├─────────────────────────────────────────────────────────┤
│                    Domain Layer                          │
│        Entities │ UseCases │ RepositoryProtocols        │
├─────────────────────────────────────────────────────────┤
│                   Platform Layer                         │
│         SwiftDataRepository │ (Future: CloudKit)        │
├─────────────────────────────────────────────────────────┤
│                     Core Layer                           │
│      DesignSystem │ SharedUI │ Utilities │ Extensions   │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **App** | Composition root, DI container, navigation orchestration |
| **Features** | UI screens, ViewModels, feature-specific logic |
| **Domain** | Business entities, use cases, repository protocols |
| **Platform** | Concrete implementations (SwiftData, networking) |
| **Core** | Shared utilities, design system, reusable UI components |

---

## Folder Structure

```
Diameris/
├── Diameris.xcodeproj
├── DiamerisApp/                    # Main app target (thin shell)
│   ├── DiamerisApp.swift          # @main entry point
│   ├── AppCoordinator.swift       # Navigation orchestration
│   └── DependencyContainer.swift  # DI composition root
│
├── Packages/                       # Local SPM packages
│   ├── Core/
│   │   ├── DesignSystem/          # Colors, typography, Liquid Glass components
│   │   ├── SharedUI/              # Reusable views (cards, charts, forms)
│   │   └── Utilities/             # Extensions, helpers, formatters
│   │
│   ├── Domain/
│   │   ├── Entities/              # Business models (Income, Expense, Goal, etc.)
│   │   ├── UseCases/              # Business logic (BudgetCalculator, etc.)
│   │   └── Repositories/          # Protocol definitions only
│   │
│   ├── Platform/
│   │   └── Persistence/           # SwiftData repository implementations
│   │
│   └── Features/
│       ├── Dashboard/             # Dashboard feature module
│       ├── Budget/                # Budget management feature
│       ├── Goals/                 # Goals & emergency fund feature
│       ├── Transfers/             # Bank transfer planning feature
│       └── Settings/              # App settings feature
│
├── Docs/
└── Tests/
```

---

## Dependency Rules

```
                    ┌─────────────┐
                    │ DiamerisApp │
                    └──────┬──────┘
                           │ depends on all Features + Platform
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Features │    │ Platform │    │   Core   │
    └────┬─────┘    └────┬─────┘    └────┬─────┘
         │               │               │
         ▼               ▼               │
    ┌──────────┐    ┌──────────┐        │
    │  Domain  │◄───│  Domain  │        │
    │(protocols)    │(protocols)        │
    └────┬─────┘    └──────────┘        │
         │                              │
         └──────────────┬───────────────┘
                        ▼
                 ┌──────────┐
                 │   Core   │
                 └──────────┘
```

**Key Rules:**
- Features depend on Domain (protocols) + Core
- Platform depends on Domain (protocols) + Core
- Domain depends only on Core
- Core has no internal dependencies
- App composes everything

### As Built (2026-09-27)

The rules above hold today, with less machinery than the target design: there are no
repository protocols and no `DependencyContainer` yet, because no feature reads or writes
storage directly.

```
Diameris (app) ──► Onboarding, Dashboard, Expenses ──► Domain, DesignSystem, SharedUI, Utilities
      │
      └──────────► Persistence ──► Domain
```

- **Features never import Persistence or SwiftData.** They take plain values in and hand results
  out through closures: `OnboardingContainerView(onComplete: (OnboardingResult) -> Void)`,
  `NewMonthSheet`'s `NewMonthCompletionData`, and `ExpensesViewModel.onAddExpense` and its siblings.
- **The app target is the only place that touches `ModelContext`.** It reads with `@Query`, maps
  models to feature values, and writes through the operations in
  `Persistence/ModelContext+Writes.swift`: `saveOnboarding`, `insertExpense`, `updateExpense`,
  `deleteExpense`, `setExpenseEnabled`, `insertCustomCategory`, `deleteCustomCategory`,
  `applyNewMonth`, `saveSettings`, `updateAccount` and `deleteAllData`. Each saves once, rolls
  the context back if the save fails, and rethrows. Callers log the error with
  `Logger.persistence`, and show `saveFailedAlert` where the user would otherwise lose input.
- **Startup repair:** `ModelContext.repairDanglingExpenseLinks()` runs once per launch, before
  any view loads data. It relinks orphaned expense links only when the answer is unambiguous,
  and is a no-op on later runs.
- **Onboarding data safety:** `saveOnboarding` replaces all stored data. Two safeguards protect
  existing data. At launch, `restoreOnboardingFlag` sets the flag back to true when a
  `UserProfile` is stored, so a lost or accidentally reset flag is undone by relaunching. In
  DEBUG, "Reset Onboarding Flag" sits behind a destructive confirmation dialog.
- **Dashboard input:** `StoredDashboardData` maps the stored models into the Dashboard's
  `DashboardDataProvider`, which `DashboardViewModel.loadData(from:)` consumes.
- **`PersistenceSchema.models`** is the single list of `@Model` types. The app container, the
  tests and `deleteAllData()` all use it. Schema changes must be additive: new stored
  properties need a default, and entities and properties are never renamed or removed. The
  launch path calls `fatalError` if the store can't be opened.
- **Account and destination rules live in Domain** (`[AccountEntry].canAssign(_:toAccount:)`,
  `availableRemainingDestinations`, `resolvedRemainingDestination(_:)`,
  `SavingsAllocationEntry.withSafeBoost`). UIs use them to offer only valid choices, and
  `updateAccount` / `saveSettings` enforce them again: the primary account keeps its type, a
  second emergency account throws `PersistenceError.accountTypeNotAllowed`, an unsafe boost is
  switched off, and a destination with no account falls back to `.primary`.
- **Model ↔ entry mapping keeps ids.** `Account(from:)` and `Expense(from:)` keep the entry's
  `id`, because expenses reference accounts through `linkedAccountId`.
- Add repository protocols only when a feature must query or write storage itself (for example,
  paging a long history). Until then, closures are the boundary.

---

## Model Separation Strategy

Domain entities are **pure Swift structs** (no SwiftData dependency). SwiftData models live in Platform/Persistence with mapping functions.

```swift
// Domain/Entities - Pure Swift structs (framework-agnostic)
struct Expense: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var amount: Decimal
    var frequency: Frequency
    var categoryID: UUID?
    var isEnabled: Bool
}

// Platform/Persistence - SwiftData models
@Model
final class ExpenseEntity {
    var id: UUID
    var name: String
    var amount: Decimal
    var frequency: String  // stored as raw value
    var category: CategoryEntity?
    var isEnabled: Bool

    func toDomain() -> Expense {
        Expense(
            id: id,
            name: name,
            amount: amount,
            frequency: Frequency(rawValue: frequency) ?? .monthly,
            categoryID: category?.id,
            isEnabled: isEnabled
        )
    }

    static func fromDomain(_ expense: Expense, category: CategoryEntity?) -> ExpenseEntity {
        ExpenseEntity(
            id: expense.id,
            name: expense.name,
            amount: expense.amount,
            frequency: expense.frequency.rawValue,
            category: category,
            isEnabled: expense.isEnabled
        )
    }
}
```

**Benefits:**
- Domain layer has no framework dependencies
- Easy to swap persistence (SwiftData → CloudKit)
- Pure domain models are easier to test
- Clear separation of concerns

---

## Localization Architecture

Each SPM package maintains **its own localization files** and extension. This is intentional and follows the recommended microapps architecture pattern.

### Why Not Centralize?

The `.localized` extension uses `Bundle.module`, which is resolved at **compile time** to the bundle where the code is defined:

```swift
// In Onboarding package - .module refers to Onboarding's bundle
extension String {
    var localized: String {
        String(localized: String.LocalizationValue(self), bundle: .module)
    }
}
```

If we centralized this to Utilities, `.module` would refer to Utilities' bundle—not the calling package's bundle. **This is a Swift compiler limitation, not a design choice.**

### Current Structure

Each package has:
```
FeaturePackage/
├── Sources/
│   └── Feature/
│       ├── Utils/
│       │   └── Localization.swift     # String extension with bundle: .module
│       └── Resources/
│           └── Localizable.xcstrings  # String Catalog (en/ro)
```

### Package Localization Files

| Package | Localization.swift | Localizable.xcstrings |
|---------|-------------------|----------------------|
| Domain | ✅ | ✅ |
| SharedUI | — (`String(localized:bundle: .module)`) | ✅ |
| Onboarding | ✅ | ✅ |
| Dashboard | ✅ | ✅ |
| Expenses | ✅ | ✅ |
| Main App | ✅ (bundle: .main) | ✅ |

Every package with a catalog declares `defaultLocalization: "en"` in `Package.swift`. That turns on
String Catalog symbol generation, so keys that differ only in case ("Account name" / "Account
Name") or contain no letters ("%lld×") fail the build — merge them, or use `Text(verbatim:)` for
strings that need no translation.

> ⚠️ **`.localized` keys are invisible to Xcode's extractor.** Keys used only through the
> `.localized` helper must be added to the catalog by hand (as manual keys, with `ro`), and Xcode
> marks existing ones **stale**. Their translations still work — **never run "Remove stale
> strings"** on these catalogs, it deletes working Romanian. New code may use
> `String(localized: "…", bundle: .module)` directly, which Xcode does extract.

### Key Differences

- **SPM packages**: Use `bundle: .module` to access their own strings
- **Main app**: Uses `bundle: .main` to access app-level strings

### Required App Configuration

The main app's `Info.plist` must include:
```xml
<key>CFBundleAllowMixedLocalizations</key>
<true/>
```

This allows package localizations to work even if the main app doesn't support all the same languages.

### References

- [Swift with Majid - Microapps Resources & Localization](https://swiftwithmajid.com/2022/01/26/microapps-architecture-in-swift-resources-and-localization/)
- [Daniel Saidi - Swift Package Localization (2025)](https://danielsaidi.com/blog/2025/12/02/a-better-way-to-localize-swift-packages-with-xcode-string-catalogs)

---

## Package.swift Examples

### Core/DesignSystem/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DesignSystem",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    targets: [
        .target(name: "DesignSystem"),
        .testTarget(name: "DesignSystemTests", dependencies: ["DesignSystem"])
    ]
)
```

### Domain/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Entities", targets: ["Entities"]),
        .library(name: "UseCases", targets: ["UseCases"]),
        .library(name: "RepositoryProtocols", targets: ["RepositoryProtocols"])
    ],
    dependencies: [
        .package(path: "../Core/Utilities")
    ],
    targets: [
        .target(name: "Entities"),
        .target(name: "RepositoryProtocols", dependencies: ["Entities"]),
        .target(name: "UseCases", dependencies: ["Entities", "RepositoryProtocols"]),
        .testTarget(name: "UseCasesTests", dependencies: ["UseCases"])
    ]
)
```

### Features/Dashboard/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DashboardFeature",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "DashboardFeature", targets: ["DashboardFeature"])
    ],
    dependencies: [
        .package(path: "../../Domain"),
        .package(path: "../../Core/DesignSystem"),
        .package(path: "../../Core/SharedUI")
    ],
    targets: [
        .target(
            name: "DashboardFeature",
            dependencies: [
                .product(name: "Entities", package: "Domain"),
                .product(name: "UseCases", package: "Domain"),
                .product(name: "RepositoryProtocols", package: "Domain"),
                "DesignSystem",
                "SharedUI"
            ]
        ),
        .testTarget(name: "DashboardFeatureTests", dependencies: ["DashboardFeature"])
    ]
)
```

### Platform/Persistence/Package.swift

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Persistence",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Persistence", targets: ["Persistence"])
    ],
    dependencies: [
        .package(path: "../../Domain")
    ],
    targets: [
        .target(
            name: "Persistence",
            dependencies: [
                .product(name: "Entities", package: "Domain"),
                .product(name: "RepositoryProtocols", package: "Domain")
            ]
        ),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence"])
    ]
)
```

---

## Dependency Injection

> **Planned, not implemented.** The code today uses closures plus `ModelContext` write
> operations (see *As Built* above). The sketch below is the target once a feature needs
> direct data access.

Using native Swift (no external frameworks):

```swift
// Domain/RepositoryProtocols
protocol ExpenseRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Expense]
    func save(_ expense: Expense) async throws
    func delete(_ expense: Expense) async throws
}

// Platform/Persistence
final class SwiftDataExpenseRepository: ExpenseRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Expense] {
        let descriptor = FetchDescriptor<ExpenseEntity>()
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toDomain() }
    }

    // ... other methods
}

// App/DependencyContainer
@MainActor
final class DependencyContainer: ObservableObject {
    let modelContainer: ModelContainer

    init() throws {
        modelContainer = try ModelContainer(for: /* schemas */)
    }

    lazy var expenseRepository: ExpenseRepositoryProtocol = {
        SwiftDataExpenseRepository(modelContext: modelContainer.mainContext)
    }()

    lazy var incomeRepository: IncomeRepositoryProtocol = {
        SwiftDataIncomeRepository(modelContext: modelContainer.mainContext)
    }()

    lazy var budgetUseCase: BudgetCalculationUseCase = {
        BudgetCalculationUseCase(
            incomeRepository: incomeRepository,
            expenseRepository: expenseRepository
        )
    }()
}
```

---

## Navigation Architecture

Diameris uses a **Router pattern** with `NavigationStack` and `NavigationPath` for type-safe, testable navigation that follows SOLID principles.

### Core Principles

1. **Navigation is state** - Not imperative "push/pop", but declarative state mutations
2. **Type-safe routes** - Enums with associated values ensure compile-time safety
3. **Centralized routing** - Router class manages all navigation, views stay decoupled
4. **Feature isolation** - Each feature defines its own routes, App composes them

### Route Definition

Routes are defined as enums with `Hashable` conformance for use with `NavigationPath`:

```swift
// Core/Navigation/AppRoute.swift
enum AppRoute: Hashable {
    // Tab routes
    case dashboard
    case budget
    case goals
    case transfers
    case settings
}

// Features/Budget/BudgetRoute.swift
enum BudgetRoute: Hashable {
    case expenseList
    case expenseDetail(Expense)
    case addExpense
    case editExpense(Expense)
    case categoryList
    case categoryDetail(Category)
}

// Features/Goals/GoalsRoute.swift
enum GoalsRoute: Hashable {
    case emergencyFund
    case loanDetail(Loan)
    case addLoan
    case goalDetail(Goal)
    case addGoal
}
```

**SOLID Benefits:**
- **Single Responsibility**: Each feature owns its routes
- **Open/Closed**: Add new routes without modifying existing code
- **Type Safety**: Compiler enforces required data for each destination

### Router Implementation

The Router is an `@Observable` class that manages navigation state:

```swift
// App/Navigation/AppRouter.swift
import SwiftUI

@Observable
@MainActor
final class AppRouter {
    // MARK: - Navigation State

    var selectedTab: AppTab = .dashboard

    // Each tab has its own navigation path
    var dashboardPath = NavigationPath()
    var budgetPath = NavigationPath()
    var goalsPath = NavigationPath()
    var transfersPath = NavigationPath()
    var settingsPath = NavigationPath()

    // Sheet presentation
    var presentedSheet: SheetDestination?
    var presentedFullScreenCover: FullScreenDestination?

    // MARK: - Navigation Actions

    func push<R: Hashable>(_ route: R) {
        switch selectedTab {
        case .dashboard: dashboardPath.append(route)
        case .budget: budgetPath.append(route)
        case .goals: goalsPath.append(route)
        case .transfers: transfersPath.append(route)
        case .settings: settingsPath.append(route)
        }
    }

    func pop() {
        switch selectedTab {
        case .dashboard: if !dashboardPath.isEmpty { dashboardPath.removeLast() }
        case .budget: if !budgetPath.isEmpty { budgetPath.removeLast() }
        case .goals: if !goalsPath.isEmpty { goalsPath.removeLast() }
        case .transfers: if !transfersPath.isEmpty { transfersPath.removeLast() }
        case .settings: if !settingsPath.isEmpty { settingsPath.removeLast() }
        }
    }

    func popToRoot() {
        switch selectedTab {
        case .dashboard: dashboardPath = NavigationPath()
        case .budget: budgetPath = NavigationPath()
        case .goals: goalsPath = NavigationPath()
        case .transfers: transfersPath = NavigationPath()
        case .settings: settingsPath = NavigationPath()
        }
    }

    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}
```

### Tab Structure

Each tab maintains its own `NavigationStack` for independent navigation:

```swift
// App/Views/MainTabView.swift
struct MainTabView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab("Dashboard", systemImage: "chart.pie", value: .dashboard) {
                NavigationStack(path: $router.dashboardPath) {
                    DashboardView()
                        .navigationDestination(for: DashboardRoute.self) { route in
                            destinationView(for: route)
                        }
                }
            }

            Tab("Budget", systemImage: "list.bullet.rectangle", value: .budget) {
                NavigationStack(path: $router.budgetPath) {
                    BudgetView()
                        .navigationDestination(for: BudgetRoute.self) { route in
                            destinationView(for: route)
                        }
                }
            }

            Tab("Goals", systemImage: "target", value: .goals) {
                NavigationStack(path: $router.goalsPath) {
                    GoalsView()
                        .navigationDestination(for: GoalsRoute.self) { route in
                            destinationView(for: route)
                        }
                }
            }

            Tab("Transfers", systemImage: "arrow.left.arrow.right", value: .transfers) {
                NavigationStack(path: $router.transfersPath) {
                    TransfersView()
                        .navigationDestination(for: TransfersRoute.self) { route in
                            destinationView(for: route)
                        }
                }
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack(path: $router.settingsPath) {
                    SettingsView()
                        .navigationDestination(for: SettingsRoute.self) { route in
                            destinationView(for: route)
                        }
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown) // iOS 26: Collapsing tab bar
    }
}
```

### Destination Factory

A factory pattern maps routes to views (respects Open/Closed principle):

```swift
// App/Navigation/NavigationDestinations.swift
@MainActor
struct NavigationDestinations {

    @ViewBuilder
    static func view(for route: BudgetRoute) -> some View {
        switch route {
        case .expenseList:
            ExpenseListView()
        case .expenseDetail(let expense):
            ExpenseDetailView(expense: expense)
        case .addExpense:
            AddExpenseView()
        case .editExpense(let expense):
            EditExpenseView(expense: expense)
        case .categoryList:
            CategoryListView()
        case .categoryDetail(let category):
            CategoryDetailView(category: category)
        }
    }

    @ViewBuilder
    static func view(for route: GoalsRoute) -> some View {
        switch route {
        case .emergencyFund:
            EmergencyFundView()
        case .loanDetail(let loan):
            LoanDetailView(loan: loan)
        case .addLoan:
            AddLoanView()
        case .goalDetail(let goal):
            GoalDetailView(goal: goal)
        case .addGoal:
            AddGoalView()
        }
    }
}
```

### Sheet & Full-Screen Destinations

Modal presentations use separate enums:

```swift
// App/Navigation/SheetDestination.swift
enum SheetDestination: Identifiable {
    case addExpense
    case addIncome
    case editExpense(Expense)
    case filterOptions

    var id: String {
        switch self {
        case .addExpense: return "addExpense"
        case .addIncome: return "addIncome"
        case .editExpense(let e): return "editExpense-\(e.id)"
        case .filterOptions: return "filterOptions"
        }
    }
}

enum FullScreenDestination: Identifiable {
    case onboarding
    case currencyPicker

    var id: String {
        switch self {
        case .onboarding: return "onboarding"
        case .currencyPicker: return "currencyPicker"
        }
    }
}
```

Usage in views:

```swift
.sheet(item: $router.presentedSheet) { destination in
    switch destination {
    case .addExpense:
        AddExpenseView()
            .presentationDetents([.medium, .large])
    case .addIncome:
        AddIncomeView()
            .presentationDetents([.medium])
    // ...
    }
}
```

### Deep Linking

The Router handles deep links by mapping URLs to routes:

```swift
// App/Navigation/DeepLinkHandler.swift
extension AppRouter {
    func handle(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let host = components.host else { return }

        switch host {
        case "expense":
            if let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let id = UUID(uuidString: idString) {
                selectedTab = .budget
                // Load expense and navigate
            }
        case "goal":
            selectedTab = .goals
            // Handle goal deep link
        default:
            break
        }
    }
}

// In App entry point
@main
struct DiamerisApp: App {
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(router)
                .onOpenURL { url in
                    router.handle(url: url)
                }
        }
    }
}
```

### Navigation in Feature Views

Views use the Router via environment, keeping navigation decoupled:

```swift
// Features/Budget/Views/ExpenseListView.swift
struct ExpenseListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: ExpenseListViewModel

    var body: some View {
        List(viewModel.expenses) { expense in
            ExpenseRow(expense: expense)
                .onTapGesture {
                    router.push(BudgetRoute.expenseDetail(expense))
                }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    router.presentSheet(.addExpense)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationTitle("Expenses")
    }
}
```

### iOS 26 Navigation Features

Leverage new iOS 26 APIs:

```swift
// Collapsing tab bar on scroll
.tabBarMinimizeBehavior(.onScrollDown)

// Toolbar spacers for grouped actions
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Edit") { }
    }
    ToolbarSpacer(.fixed)
    ToolbarItem(placement: .primaryAction) {
        Button("Delete") { }
    }
}

// Minimized search in toolbar
.searchable(text: $searchText)
.searchToolbarBehavior(.minimize)

// Sheet detents with Liquid Glass
.sheet(item: $selectedItem) { item in
    DetailView(item: item)
        .presentationDetents([.medium, .large])
        // iOS 26: Sheets automatically get Liquid Glass background
}
```

### Navigation SOLID Summary

| Principle | Implementation |
|-----------|----------------|
| **Single Responsibility** | Router handles navigation only, Views handle UI only |
| **Open/Closed** | Add routes without modifying Router, use factory for destinations |
| **Liskov Substitution** | Any `Hashable` route works with `NavigationPath` |
| **Interface Segregation** | Features define only their own routes |
| **Dependency Inversion** | Views depend on Router abstraction via Environment |

---

## SOLID Principles

### Single Responsibility (S)
- Each module has one reason to change
- `DesignSystem` only changes for design updates
- `UseCases` only changes for business logic

### Open/Closed (O)
- Features are open for extension via new modules
- Closed for modification (add new feature = add new package)

### Liskov Substitution (L)
- Repository protocols allow swapping implementations
- `SwiftDataRepository` can be replaced with `CloudKitRepository`

### Interface Segregation (I)
- Split protocols: `IncomeRepository`, `ExpenseRepository`, `GoalRepository`
- Features only depend on protocols they use

### Dependency Inversion (D)
- Features depend on `RepositoryProtocols` (abstractions)
- `Persistence` implements those protocols
- App injects concrete implementations at startup

---

## Build Benefits

| Benefit | How |
|---------|-----|
| **Faster builds** | Only changed modules recompile |
| **Parallel compilation** | Independent modules build concurrently |
| **Better previews** | Feature modules have minimal dependencies |
| **Isolated testing** | Each module has its own test target |
| **Code ownership** | Clear boundaries for team collaboration |

---

## Adding a New Feature

1. Create package in `Packages/Features/NewFeature/`
2. Add `Package.swift` with dependencies on Domain + Core
3. Implement views and ViewModels
4. Add package to main app target
5. Wire up in `DependencyContainer`

---

## Incremental Setup

Start with these packages:

```
Packages/
├── Core/
│   ├── DesignSystem/    # Liquid Glass components, colors, typography
│   └── Utilities/       # Extensions, formatters, Currency type
│
└── Domain/
    ├── Entities/        # Pure Swift business models
    ├── UseCases/        # Business logic protocols + implementations
    └── Repositories/    # Repository protocol definitions
```

Add as needed:
- `Platform/Persistence/` - when implementing data layer
- `Features/Dashboard/` - when building dashboard UI
- Additional features as development progresses

---

## References

### Architecture & Modularization
- [Nimble - Modularizing iOS with SwiftUI and SPM](https://nimblehq.co/blog/modern-approach-modularize-ios-swiftui-spm)
- [ModernCleanArchitectureSwiftUI](https://github.com/sergdort/ModernCleanArchitectureSwiftUI)
- [Swift by Sundell - Managing Dependencies](https://www.swiftbysundell.com/articles/managing-dependencies-using-the-swift-package-manager/)
- [SPM Syntax Cheatsheet](https://www.swifttoolkit.dev/posts/spm-cheatsheet)
- [Swift Package Manager Traits (2025)](https://theswiftdev.com/2025/all-about-swift-package-manager-traits/)

### Navigation
- [Modern Navigation in SwiftUI (2025)](https://dev.to/sebastienlato/modern-navigation-in-swiftui-1c8g)
- [SwiftUICoordinator - Coordinator Pattern Library](https://github.com/erikdrobne/SwiftUICoordinator)
- [SwiftUI Navigation Internals](https://dev.to/sebastienlato/swiftui-navigation-internals-how-navigationstack-really-works-1g4m)
- [NavigationPath in SwiftUI](https://tanaschita.com/swiftui-navigationpath/)
- [SwiftUI in iOS 26 - WWDC 2025](https://swiftwithmajid.com/2025/06/10/what-is-new-in-swiftui-after-wwdc25/)
