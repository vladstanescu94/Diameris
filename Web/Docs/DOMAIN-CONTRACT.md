# DOMAIN CONTRACT — Diameris

Authoritative, field-exact specification of the Diameris business layer, extracted from source.
Every value below is quoted from code with a `file:line` reference.

**Purity verdict (critical for the Vapor plan) — VERIFIED BY BUILD, not just by inspection:**

| Package | Imports found | Pure? |
|---|---|---|
| `Domain` | **`Foundation` only** (all 11 source files) | ✅ Yes — no SwiftUI, no UIKit, no SwiftData |
| `Utilities` → `AmountFormatter`, `Currency`, `DateFormatters` | `Foundation` | ✅ Yes |
| `Utilities` → `HapticManager`, `KeyboardHelper` | `UIKit`, now behind `#if canImport(UIKit)` | ⚠️ compiles, but **absent** on macOS |
| `DesignSystem` | `SwiftUI`, and `UIKit` in `Colors.swift` | ❌ No — tokens must be transcribed, not compiled |
| `Persistence` | `Foundation`, `SwiftData`, `Domain` | ❌ No — SwiftData, replace wholesale |
| `SharedUI` | `SwiftUI` + DesignSystem/Utilities/Domain | ❌ No |

### Verified macOS build results

Both packages now declare `platforms: [.iOS(.v26), .macOS(.v26)]` and **build clean for
`arm64-apple-macosx26.0`** against `MacOSX26.5.sdk` (Swift 6.3.3 / Xcode 26.6):

```
Packages/Core/Domain     → swift build → Build complete! (5.03s)   13 files, 0 warnings
Packages/Core/Utilities  → swift build → Build complete! (3.17s)   5 files,  0 warnings
```

**Important caveat, confirmed by inspecting the emitted objects:** `UIKit` is *not* available for
native macOS — it exists in the SDK only under `System/iOSSupport/` (Mac Catalyst). A direct
`import UIKit` at `-target arm64-apple-macosx26.0` fails with `no such module 'UIKit'`. `Utilities`
builds anyway because `HapticManager.swift` and `KeyboardHelper.swift` are wrapped in
`#if canImport(UIKit)`, so on macOS they compile to **empty objects**:

| Object file | Size | `Utilities`-mangled symbols emitted |
|---|---|---|
| `HapticManager.swift.o` | 6,368 B | **0** |
| `KeyboardHelper.swift.o` | 6,376 B | **0** |
| `AmountFormatter.swift.o` | 25,984 B | 11 |
| `DateFormatters.swift.o` | 18,656 B | 36 |
| `Currency.swift.o` | 29,672 B | 67 |

**Consequence for server-side code:** `HapticManager` and `KeyboardHelper` **do not exist** in the
macOS build of `Utilities`. Any shared code that references them must be guarded the same way.
`Domain` never touches them, and the three pure utilities (`AmountFormatter`, `Currency`,
`DateFormatters`) are fully available — which is everything the server actually needs for formatting
parity.

So: **`Domain` + `Utilities` are both usable from Vapor as-is.** No source changes beyond the
`platforms:` declarations and the two `#if canImport(UIKit)` guards already in place.

`Domain` does have one non-Foundation runtime dependency: `Bundle.module` string localization
(`Packages/Core/Domain/Sources/Domain/Utils/Localization.swift:1-8`). Display names/descriptions on
enums go through `.localized`; on a non-bundle platform these must be re-implemented (see
`LOCALIZATION.md` for the 29 Domain keys).

> ### ⚠️ SwiftPM does not compile `.xcstrings` — so server-side `.localized` ALWAYS returns English
>
> Verified two ways. The built resource bundle
> `Packages/Core/Domain/.build/arm64-apple-macosx/debug/Domain_Domain.bundle` contains the **raw
> `Localizable.xcstrings`** and nothing else — no `.lproj` directories, no compiled `.strings`.
> Compiling `.xcstrings` is an Xcode build step (`xcstringstool`) that plain SwiftPM does not run.
> A probe executable linking Domain confirmed it: `AccountType.other.displayName` returns
> **`"Other"`**, not `"Altul"`, even with `-AppleLanguages '(ro)'`.
>
> Confirmed against the live server — every `displayName` it serves is English regardless of language:
> `accountTypeDisplayName: "Emergency"`, `allocationModes[0].displayName: "Priority"`,
> `frequencies[0].displayName: "Monthly"`, `remainingMoneyDestinationDisplayName: "Primary Savings"`.
>
> **This is not a bug to fix and it does not break parity — but it changes what those fields mean.**
> Every `*DisplayName` in an API response is an **English lookup key**, not a display string. The client
> must translate it through the `domain` namespace (`tDomain`) using the generated bundle, which *does*
> carry the Romanian. Treating a `displayName` as ready-to-render text ships English into Romanian.
>
> Two useful consequences:
> - It is the root cause behind the "enum displayNames render raw" defect class — the server *cannot*
>   serve Romanian here, so client-side translation is mandatory, not optional tidying.
> - It is *why* `Frequency.displayName` returns `"Monthly"` on iOS too, though for a different reason
>   there: on iOS the catalog **is** compiled, but `Monthly`/`Annual` are simply absent from Domain's
>   catalog. Same visible outcome, different cause — see `PARITY-SPEC.md §5.1`.

---

## 1. Enums (exact raw values)

Raw values are what is persisted; **never** localize or rename them.

### `AccountType` — `Packages/Core/Domain/Sources/Domain/Entities/AccountType.swift:12-71`

`enum AccountType: String, CaseIterable, Identifiable, Codable, Sendable`. `id == rawValue`.
Declaration order (= `allCases` order, drives every picker's order):

| # | case / rawValue | `displayName` (EN) | `icon` (SF Symbol) | `description` (EN) | `hasBehavior` | `isUnique` |
|---|---|---|---|---|---|---|
| 0 | `primary` | Primary | `building.columns.fill` | Where your salary lands | `true` | `false` |
| 1 | `emergency` | Emergency | `shield.fill` | Fills first until target reached | `true` | **`true`** |
| 2 | `savings` | Savings | `banknote.fill` | Receives savings after emergency | `true` | `false` |
| 3 | `personal` | Personal | `person.fill` | Your flexible spending money | `true` | `false` |
| 4 | `joint` | Joint | `person.2.fill` | For shared expenses | `false` | `false` |
| 5 | `other` | Other | `creditcard.fill` | Custom account | `false` | `false` |

`isUnique == true` only for `emergency` — the app enforces **at most one emergency account**
(`AccountsScreen.swift:262-263, 283, 308-310`).

UI colour mapping is **not** in Domain; it lives in `SharedUI/Extensions/AccountType+Color.swift:9-24`:
`primary → accentPrimary`, `emergency → warning (orange)`, `savings → accentSecondary`,
`personal → .purple`, `joint → .pink`, `other → .secondary`.
⚠️ **Inconsistency in code:** `Dashboard/Components/AccountBalancesRow.swift:124-137` uses a *different*
mapping for secondary-card icons (`primary` & `savings → accentPrimary`, `personal → accentSecondary`,
`joint → .purple`, `emergency → warning`, `other → .secondary`), and
`Dashboard/Views/TransferPlanStep.swift:195-203` a third (`primary → .secondary`, `emergency → warning`,
`savings → accentPrimary`, `personal → accentSecondary`, default `.secondary`). Pick `AccountType+Color`
as canonical for the web port and note the divergence.

### `Frequency` — `Entities/Frequency.swift:4-39`

`enum Frequency: String, CaseIterable, Codable, Sendable`

| case / rawValue | `monthlyMultiplier` | `annualMultiplier` | `icon` | `displayName` |
|---|---|---|---|---|
| `monthly` | `1` | `12` | `calendar` | Monthly |
| `annual` | `Decimal(1) / 12` | `1` | `calendar.badge.clock` | Annual |

> ### ⚠️ Annual normalisation is DELIBERATELY IMPRECISE — multiply by the constant, never divide by 12
>
> 🔁 **Correction to my earlier advice**, which said "divide-by-12 at final formatting". **That is wrong
> and would break parity.** `monthlyMultiplier` is the *pre-rounded* 28-digit constant
> `0.08333333333333333333333333333333333333`, and iOS computes `amount * multiplier`
> (`ExpenseEntry.swift:56`). Multiplying by that constant is **not** the same as dividing by 12.
>
> Probed against real Swift, linking Domain (`Frequency.annual.monthlyMultiplier`):
>
> | annual `amount` | iOS `monthlyAmount` (× constant) | `amount / 12` | equal? |
> |---|---|---|---|
> | 1200 | `99.999999999999999999999999999999999996` | `100` | **no** |
> | 2400 | `199.999999999999999999999999999999999992` | `200` | **no** |
> | 370 | `30.8333333333333333333333333333333333321` | `30.8333…333` | **no** |
> | 500 | `41.666666666666666666666666666666666665` | `41.666…666` | **no** |
>
> Round-tripping compounds it: summing twelve `monthlyAmount`s for an annual 1200 gives
> **`1199.9999999999999999999999999999999999`**, not 1200.
>
> **This is invisible on screen** — every display path rounds to 0 fraction digits, so `99.999…996`
> renders `100`. That is exactly why it is dangerous: a server-side "tidy" to `/12` looks like a
> no-op, passes every screenshot check, and silently changes every stored/compared raw value. Two
> places it could surface: a sum landing on a `.5` half-even boundary, and any equality check against
> a raw amount.
>
> **Rule for the web:** reproduce `amount × 0.08333333333333333333333333333333333333` with a decimal
> library at 28+ significant digits. Do not divide by 12, do not truncate the constant, do not use
> `0.08333`. `isBalanced`'s `< 0.01` tolerance absorbs the residue, so nothing needs "fixing".

### `AllocationMode` — `Entities/AllocationMode.swift:11-30`

| case / rawValue | `displayName` | `description` |
|---|---|---|
| `prioritized` (default) | Priority | Emergency fund fills first, then savings |
| `split` | Split | Fixed amounts to each account every month |

### `SavingsInputMode` — `Entities/SavingsInputMode.swift:7-19`

| case / rawValue | `displayName` |
|---|---|
| `percentage` | Percentage |
| `fixedAmount` | Fixed Amount |

### `RemainingMoneyDestination` — `Entities/RemainingMoneyDestination.swift:4-26`

| case / rawValue | `displayName` | `description` | `icon` * |
|---|---|---|---|
| `primarySavings` | Primary Savings | Add to your savings for future goals | `banknote.fill` |
| `personal` | Personal Account | For flexible spending | `person.fill` |
| `primary` | Keep in Primary | Leave in your main account | `building.columns.fill` |

\* `icon` is declared outside Domain, in `Onboarding/Components/RemainingMoneyPicker.swift:77-85`.

⚠️ **DISCREPANCY:** `SettingsSheet.swift:698-706` redefines `displayName` privately and renders
`.primary` as **"Primary Account"**, not "Keep in Primary". Two different labels for the same enum case
depending on the screen. The web port must decide; Domain's value is "Keep in Primary".

---

## 2. Entities

### `AccountEntry` — `Entities/AccountEntry.swift:5-84`

`struct AccountEntry: Identifiable, Sendable`

| Field | Type | Optional | Default (init) | Notes |
|---|---|---|---|---|
| `id` | `UUID` | no | `UUID()` | `let` — immutable |
| `name` | `String` | no | *required* | |
| `purpose` | `String?` | yes | `nil` | descriptive subtitle |
| `accountType` | `AccountType` | no | `.other` | |
| `isPrimary` | `Bool` | no | `false` | where salary lands |
| `isPrimarySavings` | `Bool` | no | `false` | receives auto-allocation |
| `emergencyMultiplier` | `Double?` | yes | `nil` | intended range 3.0–6.0 (**not enforced in Domain**) |
| `emergencyHardCap` | `Decimal?` | yes | `nil` | optional ceiling on target |
| `currentBalance` | `Decimal` | no | `0` | |

**Static factories** (`AccountEntry.swift:88-149`) — these are the smart defaults; `name`/`purpose`
strings are localized Domain keys:

| Factory | name | purpose | type | flags |
|---|---|---|---|---|
| `.primary(name:)` | "Main Account" | "Where your salary lands" | `.primary` | `isPrimary = true` |
| `.emergency(name:multiplier:hardCap:currentBalance:)` | "Emergency Fund" | "Protects you from unexpected expenses" | `.emergency` | `multiplier` default **3.0**, `hardCap` default `nil`, `currentBalance` default 0 |
| `.savings(name:isPrimarySavings:)` | "Savings" | "For building wealth over time" | `.savings` | `isPrimarySavings` default **true** |
| `.personal(name:)` | "Personal" | "Your flexible spending money" | `.personal` | — |
| `.joint(name:)` | "Joint" | "For shared expenses" | `.joint` | — |
| `AccountEntry.defaults` | — | — | — | **`[.primary()]`** — exactly one account (`:146-148`) |

#### Calculations

**`emergencyTarget(monthlyIncome:) -> Decimal?`** (`:56-65`)
```
if accountType != .emergency        -> nil
if emergencyMultiplier == nil       -> nil
calculated = monthlyIncome * Decimal(emergencyMultiplier)
if emergencyHardCap != nil          -> min(calculated, emergencyHardCap)
else                                -> calculated
```
Plain language: the emergency target is *N months of income*, optionally clipped by an absolute cap.
Edge cases: negative income yields a negative target (unguarded); a hard cap of `0` yields target `0`;
a hard cap **larger** than `calculated` is a no-op. No rounding is applied — full `Decimal` precision.

**`emergencyProgress(monthlyIncome:) -> Double?`** (`:69-75`)
```
target = emergencyTarget(monthlyIncome:)
if target == nil || target <= 0     -> nil
progress = Double(currentBalance / target)
return clamp(progress, 0.0, 1.0)
```
Converted to `Double` via `NSDecimalNumber.doubleValue` (`:153-157`). **Clamped to [0,1]** — an
over-funded account reports exactly `1.0`, never >1. Returns `nil` (not 0) when there is no target.

**`isEmergencyComplete(monthlyIncome:) -> Bool`** (`:78-83`)
```
target = emergencyTarget(...); if nil -> false
return currentBalance >= target
```
Note: uses `>=`, and returns `false` (not `true`) for non-emergency accounts.

### `ExpenseEntry` — `Entities/ExpenseEntry.swift:5-83`

`struct ExpenseEntry: Identifiable, Sendable, Equatable`

| Field | Type | Optional | Default |
|---|---|---|---|
| `id` | `UUID` | no | `UUID()` (`let`) |
| `name` | `String` | no | *required* |
| `amount` | `Decimal` | no | *required* |
| `frequency` | `Frequency` | no | `.monthly` |
| `icon` | `String` | no | *required* (SF Symbol name) |
| `categoryId` | `UUID?` | yes | `nil` |
| `linkedAccountId` | `UUID?` | yes | `nil` — **`nil` means the Primary account** |
| `isEnabled` | `Bool` | no | `true` |
| `notes` | `String?` | yes | `nil` |

Second convenience init (`:40-48`) takes only `name, amount, icon, linkedAccountId` and forces
`frequency = .monthly`. **This is the init the Dashboard uses** (`DashboardViewModel.swift:294-303`),
which is why the Dashboard pre-converts to monthly amounts before building entries.

Calculations (`:53-73`):
- `monthlyAmount = amount * frequency.monthlyMultiplier`
- `annualAmount  = amount * frequency.annualMultiplier`
- `displayAmount(for: viewFrequency)` → `monthlyAmount` if `.monthly`, else `annualAmount`
- `category()` (`:79-82`) resolves `categoryId` **only against `Category.defaults`** — it returns `nil`
  for custom categories. ⚠️ Known limitation; the Expenses feature works around it with
  `ExpensesViewModel.allCategories`.

### `Category` — `Entities/Category.swift:4-156`

`struct Category: Identifiable, Equatable, Sendable, Hashable`

| Field | Type | Default |
|---|---|---|
| `id` | `UUID` | `UUID()` (`let`) |
| `name` | `String` | *required* |
| `icon` | `String` | *required* |
| `colorHex` | `String` | *required* (`"#RRGGBB"`) |
| `isDefault` | `Bool` | `false` |
| `sortOrder` | `Int` | `0` |

`Category.custom(...)` factory (`:29-44`) forces `isDefault = false` and defaults `sortOrder = 100`.

**Category names are NOT localized** — they are raw English literals in Domain (`:63, 74, 84, …`),
unlike account-type display names.

### `SavingsAllocationEntry` — `Entities/SavingsAllocationEntry.swift:5-184`

`struct SavingsAllocationEntry: Identifiable, Sendable`. All 13 fields with their init defaults (`:50-64`):

| Field | Type | Default | Applies to |
|---|---|---|---|
| `id` | `UUID` | `UUID()` | — |
| `percentage` | `Double` | **`0.25`** | prioritized + percentage |
| `boostEnabled` | `Bool` | `false` | prioritized + percentage only |
| `boostMultiplier` | `Double` | **`3.0`** | " |
| `allocationMode` | `AllocationMode` | `.prioritized` | — |
| `savingsInputMode` | `SavingsInputMode` | `.percentage` | prioritized |
| `fixedAmount` | `Decimal` | `0` | prioritized + fixedAmount |
| `splitEmergencyInputMode` | `SavingsInputMode` | **`.fixedAmount`** | split |
| `splitEmergencyAmount` | `Decimal` | `0` | split |
| `splitEmergencyPercentage` | `Double` | **`0.10`** | split |
| `splitSavingsInputMode` | `SavingsInputMode` | **`.fixedAmount`** | split |
| `splitSavingsAmount` | `Decimal` | `0` | split |
| `splitSavingsPercentage` | `Double` | **`0.15`** | split |

Constants (`:142-184`):
- `minimumPercentage = 0.05` (5 %)
- `maximumPercentage = 0.50` (50 %)
- `presets = [0.10, 0.15, 0.20, 0.25, 0.30]` — **declared but never used by any view**
- `recommendedPercentage = 0.25`
- `recommendationText = "Financial experts recommend saving 20-30% of your income"` — **also unused by any view**

#### Calculations

**`isBoostApplicable`** (`:125-127`): `savingsInputMode == .percentage && allocationMode == .prioritized`.
Boost is silently ignored in split mode and in fixed-amount mode.

**`effectivePercentage`** (`:85-88`):
```
if !isBoostApplicable || !boostEnabled -> percentage
else -> min(1.0, percentage * boostMultiplier)
```
Hard-capped at 100 %.

**`calculateSavings(availableIncome:)`** (`:93-100`):
```
.percentage   -> availableIncome * Decimal(effectivePercentage)
.fixedAmount  -> min(fixedAmount, max(0, availableIncome))
```
Note the asymmetry: percentage mode is **not** clamped to availableIncome (it can't exceed it since
effectivePercentage ≤ 1 and availableIncome ≥ 0), fixed mode **is** clamped, and a negative
`availableIncome` in fixed mode yields `0`.

**`resolvedSplitEmergencyAmount(availableIncome:)`** (`:103-108`) /
**`resolvedSplitSavingsAmount(availableIncome:)`** (`:111-116`):
```
.percentage  -> availableIncome * Decimal(<split*Percentage>)
.fixedAmount -> <split*Amount>            // NOT clamped here
```

**`splitTotal(availableIncome:)`** (`:119-122`): sum of the two resolved amounts. Can exceed
availableIncome — the calculator handles that by proportional reduction (see §4).

**`isValid`** (`:153-171`):
```
prioritized + percentage  -> 0.05 <= percentage <= 0.50
prioritized + fixedAmount -> fixedAmount > 0
split                     -> (emergency side > 0) OR (savings side > 0)   // OR, not AND
```
where "side > 0" tests `split*Percentage > 0` in percentage mode, `split*Amount > 0` in fixed mode.
⚠️ `isValid` is **never called by any view** — onboarding's `canAdvance` for the savings step is
hardcoded `true` (`OnboardingViewModel.swift:83-84`). Web port: validation is currently non-blocking.

**Display helpers** (`:130-137`): `percentageDisplay = "\(Int(percentage * 100))%"`,
`effectivePercentageDisplay` likewise. `Int()` **truncates** — `0.259` renders `"25%"`.

### `TransferPlan` — `Entities/TransferPlan.swift:5-170`

Immutable result value (`let` on every field).

| Field | Type |
|---|---|
| `income` | `Decimal` |
| `totalExpenses` | `Decimal` |
| `availableIncome` | `Decimal` |
| `totalSavings` | `Decimal` (actually-allocated, not requested — see §4) |
| `accountAllocations` | `[AccountAllocation]` (priority order) |
| `remainsInPrimary` | `Decimal` |
| `accountExpenseTransfers` | `[AccountExpenseTransfer]` |
| `remainingMoney` | `Decimal` |
| `remainingDestination` | `RemainingMoneyDestination` |
| `isBalanced` | `Bool` |

**`TransferPlan.AccountAllocation`** (`:65-111`): `id` (fresh `UUID()` per instance — **not stable
across recomputation**, do not use as a React key without care), `accountId`, `accountName`,
`accountType`, `amount`, `progressBefore: Double?`, `progressAfter: Double?`,
`targetAmount: Decimal?`, `currentBalance`, `isComplete: Bool`.
- `progressChangeDisplay` (`:100-105`): `nil` unless both progresses set; else `"\(Int(before*100))% → \(Int(after*100))%"` — note the literal **`→` (U+2192)**.
- `icon` (`:108-110`): delegates to `accountType.icon`.

**`TransferPlan.AccountExpenseTransfer`** (`:118-132`): `id` (fresh UUID), `accountId`, `accountName`,
`amount`, `expenseNames: [String]`.

**Convenience** (`:137-170`):
- `hasAccountAllocations` = non-empty **and** at least one `amount > 0`
- `totalAccountAllocations` = sum of amounts
- `emergencyAllocation` / `savingsAllocation` = first allocation with that type
- `summary` = `"Income: X | Savings: Y | Remaining: Z"`, `maximumFractionDigits = 0`, **not localized**

### `ExpenseImportData` — `Entities/ExpenseImportData.swift:4-188`

JSON import DTO (used only by the DEBUG dev tools, `DevDebugView.swift:92-184`, reading
`expenses_import.json` from the bundle).

Top level: `version: String`, `exportDate: String`, `income: IncomeData`, `savings: SavingsData`,
`emergencyFund: EmergencyFundData`, `accounts: [AccountData]?`, `expenses: [ExpenseData]`.

- `IncomeData`: `amount: Decimal`, `frequency: String`, `name: String`
- `SavingsData`: `percentage: Double`, `boostEnabled: Bool`, `boostMultiplier: **Int**`
- `EmergencyFundData`: `currentBalance: Decimal`, `targetMultiplier: Double` — ⚠️ **parsed but never applied** by the importer
- `ExpenseData`: `name`, `amount: Decimal`, `frequency: String`, `icon`, `categoryId: String?`, `isEnabled: Bool`; `toExpenseEntry()` maps `frequency == "annual" ? .annual : .monthly` (anything else → monthly) and `UUID(uuidString:)` the categoryId
- `AccountData`: `name`, `accountType: String`, `isPrimary`, `isPrimarySavings`, `emergencyMultiplier: Double?`, `currentBalance: Decimal`; `accountTypeEnum` lowercases and maps `primary|emergency|savings|personal|joint`, **default `.primary`** (note: `"other"` also falls through to `.primary`)
- Errors: `ImportError.invalidData` → "Invalid JSON data"; `.decodingFailed(Error)` → "Failed to decode: …"

---

## 3. `TransferCalculator` — the core algorithm

`Packages/Core/Domain/Sources/Domain/UseCases/TransferCalculator.swift`. A stateless `enum` namespace;
one public entry point.

```swift
TransferCalculator.calculate(
    income: Decimal,
    expenses: [ExpenseEntry],
    allocation: SavingsAllocationEntry,
    accounts: [AccountEntry],
    remainingDestination: RemainingMoneyDestination
) -> TransferPlan
```

### Main flow (`:19-85`), step by step

1. **`totalExpenses`** = `expenses.reduce(0) { $0 + $1.amount }` (`:27`).
   ⚠️ Uses raw `amount`, **NOT** `monthlyAmount` — an annual expense contributes its full annual value
   here. Callers must pre-normalise. `DashboardViewModel` does (`MainTabView.swift:147-155` passes
   `expense.monthlyAmount`); `OnboardingViewModel` passes onboarding entries which are all `.monthly`.
   Also note: `isEnabled` is **not** filtered here — the caller filters
   (`MainTabView.swift:147` `expenses.filter { $0.isEnabled }`).
   Because both callers normalise before calling, the Dashboard total and the Expenses-tab total are
   **equal by construction** — see the callout in `PARITY-SPEC.md §4.1`. One API field, not two.
2. **`availableIncome`** = `max(0, income - totalExpenses)` (`:30`). Floors at zero.
3. **Savings distribution**, branching on `allocation.allocationMode` (`:36-56`):
   - `.prioritized`: `savingsPool = allocation.calculateSavings(availableIncome:)`, then
     `distributeToAccounts(totalSavings: savingsPool, accounts:, monthlyIncome: income)`
   - `.split`: `distributeSplitToAccounts(allocation:, availableIncome:, accounts:, monthlyIncome: income)`

   Both return `(allocations, allocatedSavings)`. **`allocatedSavings` is what was actually placed**, which
   can be less than requested (e.g. emergency full and no savings account exists).
4. **`remainingMoney`** = `availableIncome - allocatedSavings` (`:59`).
5. **Expense distribution**: `distributeExpenses(expenses:, accounts:)` → `(remainsInPrimary, accountExpenseTransfers)` (`:62-65`).
6. **Balance check** (`:68-71`):
   ```
   total = remainsInPrimary + Σ expenseTransfers + Σ allocations + remainingMoney
   isBalanced = abs(total - income) < 0.01
   ```
   Tolerance is a literal `0.01`.

Note `remainingMoney` is reported but **not** added to any account inside the calculator — routing it to
`remainingDestination` is the *caller's* job (`OnboardingViewModel.save`, `DashboardViewModel.computeUpdatedBalances`).

### Prioritized mode — `distributeToAccounts` (`:94-139`)

```
remainingSavings = totalSavings
allocations = []

// Step 1 — Emergency FIRST
if let emergency = accounts.first(where: { $0.accountType == .emergency }) {
    alloc = calculateEmergencyAllocation(account: emergency,
                                         availableSavings: remainingSavings,
                                         monthlyIncome: income)
    if alloc.amount > 0 || alloc.targetAmount != nil {   // note: a 0-amount alloc with a
        allocations.append(alloc)                        // target IS still appended, so the
        remainingSavings -= alloc.amount                 // UI can show a full progress bar
    }
}

// Step 2 — Primary Savings
if let savings = accounts.first(where: { $0.isPrimarySavings }) {
    if remainingSavings > 0 { append(savings, remainingSavings); remainingSavings = 0 }
} else if let savings = accounts.first(where: { $0.accountType == .savings }) {
    // fallback: first savings-type account even if not flagged primary
    if remainingSavings > 0 { append(savings, remainingSavings); remainingSavings = 0 }
}

totalAllocated = totalSavings - remainingSavings
```

Consequences to reproduce exactly:
- Only the **first** emergency account and the **first** savings account ever receive money.
- The `isPrimarySavings` lookup is **not** restricted to `accountType == .savings` — a flagged
  `personal` or `other` account would win the lookup.
- If emergency is already full and no savings account exists, `remainingSavings` stays > 0 and
  `totalAllocated < totalSavings`; the leftover therefore flows into `remainingMoney`.

### Split mode — `distributeSplitToAccounts` (`:148-225`)

```
requestedTotal = allocation.splitTotal(availableIncome:)
if requestedTotal <= 0 -> return ([], 0)

// Proportional scale-down when the user asked for more than exists
ratio = requestedTotal > availableIncome ? availableIncome / requestedTotal : 1

emergencyOverflow = 0

// --- Emergency side ---
if let emergency = first(where: .emergency) {
    requested = allocation.resolvedSplitEmergencyAmount(availableIncome:) * ratio
    if requested > 0 {
        if let target = emergency.emergencyTarget(monthlyIncome:) {
            remaining = max(0, target - emergency.currentBalance)
            if remaining <= 0 {
                emergencyOverflow = requested          // target met → ALL of it redirects
            } else {
                actual = min(requested, remaining)
                emergencyOverflow = requested - actual  // partial redirect
                alloc = calculateEmergencyAllocation(emergency, actual, income)
                if alloc.amount > 0 || alloc.targetAmount != nil { append; totalAllocated += alloc.amount }
            }
        } else {
            // no target configured → allocate the full requested amount, no progress fields
            append(emergency, requested); totalAllocated += requested
        }
    }
}

// --- Savings side (absorbs the overflow) ---
savingsAccount = first(where: isPrimarySavings) ?? first(where: .savings)
if let savingsAccount {
    requested = allocation.resolvedSplitSavingsAmount(availableIncome:) * ratio
    savingsTotal = requested + emergencyOverflow
    if savingsTotal > 0 { append(savingsAccount, savingsTotal); totalAllocated += savingsTotal }
}
```

Edge cases:
- If there is **no** savings account, `emergencyOverflow` is **dropped** from allocations and therefore
  surfaces as `remainingMoney`.
- `ratio` is `Decimal` division — repeating decimals here are the main source of the rounding that the
  `0.01` `isBalanced` tolerance absorbs.
- Percentages in split mode are of **availableIncome**, and are scaled by `ratio` *again*, so a
  50 % + 50 % split of a smaller-than-requested pool still sums to availableIncome.

### `calculateEmergencyAllocation` (`:233-269`)

```
target = account.emergencyTarget(monthlyIncome:)
if target == nil {
    // treat as unlimited: take everything offered, no progress fields, isComplete = false
    return AccountAllocation(account:, amount: availableSavings)
}
remaining        = max(0, target - account.currentBalance)
amountToAllocate = min(remaining, availableSavings)
progressBefore   = account.emergencyProgress(monthlyIncome:) ?? 0
newBalance       = currentBalance + amountToAllocate
progressAfter    = target > 0 ? min(1.0, Double(newBalance / target)) : 0
isComplete       = newBalance >= target
```
- `progressAfter` is clamped to 1.0 but **not** floored at 0 (a negative balance yields a negative
  `progressAfter`).
- When the fund is already full, this returns `amount = 0` **with** `targetAmount` set — which is why
  the caller's `if alloc.amount > 0 || alloc.targetAmount != nil` test still appends it.

### `distributeExpenses` (`:273-312`)

```
byAccount = Dictionary(grouping: expenses.filter { $0.amount > 0 }, by: \.linkedAccountId)

remainsInPrimary = Σ amounts where linkedAccountId == nil

transfers = []
for (accountId, group) in byAccount where accountId != nil {
    accountName = accounts.first { $0.id == accountId }?.name ?? "Unknown"
    amount      = Σ group.amount
    if amount > 0 { transfers.append(AccountExpenseTransfer(accountId, accountName, amount,
                                                            expenseNames: group.map(\.name))) }
}
```
- Zero/negative-amount expenses are filtered out *before* grouping.
- `"Unknown"` is a **hardcoded, non-localized** fallback name (`:294`).
- Iteration order over a Swift `Dictionary` is **unspecified** → the order of
  `accountExpenseTransfers` is non-deterministic. Sort it in the web port (by account name or id) to
  get stable rendering.

### Worked example (from `TransferPlanScreen.swift:438-449` preview)

income 14 303; expenses 3 000 + 300 = 3 300 (all linked to primary); prioritized/percentage 25 %;
accounts = primary, emergency (×3.0, balance 37 056), savings (primary savings).

```
totalExpenses   = 3300
availableIncome = 14303 - 3300 = 11003
savingsPool     = 11003 * 0.25 = 2750.75
emergency target = 14303 * 3 = 42909 ; remaining = 42909 - 37056 = 5853
  → emergency gets min(5853, 2750.75) = 2750.75 ; progress 86% → 92% ; isComplete = false
savings gets 0 (remainingSavings exhausted)
allocatedSavings = 2750.75
remainingMoney   = 11003 - 2750.75 = 8252.25
remainsInPrimary = 3300
check: 3300 + 0 + 2750.75 + 8252.25 = 14303 → isBalanced = true
```

---

## 4. Cross-layer delegation (do not duplicate logic)

The project rule (CLAUDE.md) is that only Domain computes. Verified delegations:

| Layer type | Method | Delegates to |
|---|---|---|
| `Persistence.Account` | `emergencyTarget`, `emergencyProgress` | `toEntry().…` (`Account.swift:100-109`) |
| `Persistence.Expense` | `monthlyAmount`, `annualAmount` | `toEntry().…` (`Expense.swift:88-96`) |
| `Persistence.SavingsAllocation` | `effectivePercentage`, `calculateSavings` | `toEntry().…` (`SavingsAllocation.swift:146-154`) |
| `Dashboard.DashboardAccount` | `emergencyTarget`, `emergencyProgress` | `toAccountEntry().…` (`DashboardViewModel.swift:79-87`) |
| `Expenses.ExpenseDisplayItem` | `monthlyAmount`, `annualAmount` | `toExpenseEntry().…` (`ExpensesViewModel.swift:86-94`) |
| `Dashboard.DashboardViewModel` | `computeUpdatedBalances(from:)` | `BalanceReconciler.updatedBalances(…)` (`DashboardViewModel.swift:337-343`) — **new, per R1** |

### `BalanceReconciler` — `Domain/UseCases/BalanceReconciler.swift` (added by R1)

```
updatedBalances(plan: TransferPlan, accounts: [AccountEntry],
                reconciledBalances: [UUID: Decimal]) -> [UUID: Decimal]
```
Order is load-bearing: start from `reconciledBalances`; `+=` each `accountAllocations` amount;
`+=` each `accountExpenseTransfers` amount; `+=` `remainingMoney` to the destination account
(`.primary` is a deliberate **no-op**); finally **assign** `balances[primary] = plan.remainsInPrimary`
— set, not accumulated, because what stays in primary is the month's expense float.

A faithful move from `DashboardViewModel`; behaviour unchanged.

🚧 **Pending R10:** the four accumulator sites still use `default: 0` (lines 37, 42, 50, 54). This is
unreachable in the iOS app because `NewMonthSheet.swift:108-110` seeds *every* account before calling.
R10 will make the function seed a missing account from its `currentBalance` instead. Until then, **a
caller passing a partial `reconciledBalances` will zero out any account it omitted** that receives an
allocation or transfer. See `PARITY-SPEC.md §7.4`.

⚠️ Two places compute locally instead of delegating:
- `Persistence.Income.monthlyAmount/annualAmount` multiply by `frequency.*Multiplier` inline
  (`Income.swift:39-48`) — documented as intentional.
- `SettingsSheet` and `EmergencyMultiplierPicker` re-derive `calculatedTarget = monthlyIncome * multiplier`
  and the min-with-cap themselves (`SettingsSheet.swift:617-630`, `EmergencyMultiplierPicker.swift:18-34`)
  rather than calling `emergencyTarget`. Same result today, but a second copy of the rule.
- `SavingsSlider.effectivePercentage` (`SavingsSlider.swift:34-36`) is `percentage * boostMultiplier`
  **without** the `min(1.0, …)` cap that Domain applies. The screen prevents the situation via
  `canEnableBoost`, but the component alone can display >100 %.

---

## 5. SwiftData persistence models (to be replaced by a web store)

Schema registered in `Diameris/AppDelegate/DiamerisApp.swift:18-27` — **7 models**, on-disk
(`isStoredInMemoryOnly: false`). **No migration plan / `VersionedSchema` exists anywhere in the repo**
(searched); the app relies on SwiftData lightweight migration only.

### `UserProfile` — `Persistence/Models/UserProfile.swift:7-32`
| Field | Type | Default |
|---|---|---|
| `name` | `String` | *required* |
| `currencyCode` | `String` | *required* |
| `createdAt` | `Date` | `Date()` at init |
| `remainingMoneyDestinationRaw` | `String` | from `remainingMoneyDestination` param, default `.primarySavings` |

No `@Attribute(.unique)` id — the app treats `userProfiles.first` as *the* profile
(`MainTabView.swift:27`). Only ever one row is created (in `OnboardingViewModel.save`).
Computed `remainingMoneyDestination` falls back to `.primarySavings` on unknown raw values.

### `Income` — `Models/Income.swift:7-49`
| Field | Type | Default |
|---|---|---|
| `id` | `UUID` `@Attribute(.unique)` | `UUID()` |
| `name` | `String` | **`"Salary"`** (init default) |
| `amount` | `Decimal` | *required* |
| `frequencyRaw` | `String` | `Frequency.monthly.rawValue` |
| `isActive` | `Bool` | `true` (always, not a param) |
| `createdAt` | `Date` | `Date()` |

Only one Income row is created; readers use `incomes.first?.amount ?? 0`
(`MainTabView.swift:182-186`, `SettingsSheet.swift:47`). `isActive` is written but **never read**.

### `Expense` — `Models/Expense.swift:7-97`
| Field | Type | Default |
|---|---|---|
| `id` | `UUID` unique | `UUID()` |
| `name` | `String` | *required* |
| `amount` | `Decimal` | *required* |
| `frequencyRaw` | `String` | `.monthly` |
| `icon` | `String` | *required* |
| `isEnabled` | `Bool` | `true` |
| `linkedAccountId` | `UUID?` | `nil` (= Primary) |
| `categoryId` | `UUID?` | `nil` |
| `notes` | `String?` | `nil` |
| `createdAt` | `Date` | `Date()` |
| `sortOrder` | `Int` | `0` |

⚠️ `linkedAccountId` / `categoryId` are **loose UUIDs, not SwiftData relationships** — no referential
integrity; deleting a category or account leaves dangling ids. The Expenses feature explicitly handles
unknown category ids (`ExpensesViewModel.swift:317-319`).

### `Account` — `Models/Account.swift:7-110`
| Field | Type | Default |
|---|---|---|
| `id` | `UUID` unique | `UUID()` — ⚠️ **regenerated**, `Account(from: entry)` does **not** carry over `entry.id` |
| `name` | `String` | *required* |
| `purpose` | `String?` | `nil` |
| `isPrimary` | `Bool` | `false` |
| `sortOrder` | `Int` | `0` |
| `accountTypeRaw` | `String` | `AccountType.other.rawValue` |
| `isPrimarySavings` | `Bool` | `false` |
| `emergencyMultiplier` | `Double?` | `nil` |
| `emergencyHardCap` | `Decimal?` | `nil` |
| `currentBalance` | `Decimal` | `0` |
| `createdAt` | `Date` | `Date()` |

`accountType` getter falls back to `.other` on unknown raw values.

### `SavingsAllocation` — `Models/SavingsAllocation.swift:7-165`
`id` unique + the same 12 allocation fields as `SavingsAllocationEntry`, stored with the enum-raw
suffix and **property-level defaults declared in the model** (which is what makes lightweight
migration work):
`allocationModeRaw = "prioritized"`, `savingsInputModeRaw = "percentage"`, `fixedAmount = 0`,
`splitEmergencyInputModeRaw = "fixedAmount"`, `splitEmergencyAmount = 0`,
`splitEmergencyPercentage = 0.10`, `splitSavingsInputModeRaw = "fixedAmount"`,
`splitSavingsAmount = 0`, `splitSavingsPercentage = 0.15` (`:25-49`).
Init defaults: `percentage = 0.25`, `boostEnabled = false`, `boostMultiplier = 3.0`, `createdAt = .now`.
Type-safe getters fall back to `.prioritized` / `.percentage` / `.fixedAmount` / `.fixedAmount`.

### `CustomCategory` — `Models/CustomCategory.swift:11-56`
| Field | Type | Default |
|---|---|---|
| `id` | `UUID` unique | `UUID()` — **is** passed through by callers so ids are stable |
| `name` | `String` | *required* |
| `icon` | `String` | *required* |
| `colorHex` | `String` | *required* |
| `sortOrder` | `Int` | **`100`** |
| `createdAt` | `Date` | `Date()` |

`toCategory()` → `Domain.Category.custom(...)` so `isDefault == false`.
**Default categories are deliberately NOT persisted** (`CustomCategory.swift:9`) — they live only in
Domain code. The web port must do the same or seed them with the exact fixed UUIDs below.

Also exported as type aliases in `Persistence.swift:6-12`: `ExpenseEntity`, `AccountEntity`,
`IncomeEntity`, `UserProfileEntity`, `SavingsAllocationEntity`, `CategoryEntity`, plus
`ExpenseCategory = Domain.Category`.

### `MonthlyRecord` — `Dashboard/Models/MonthlyRecord.swift:34-83`
Declared in the **Dashboard feature**, not Persistence, but registered in the app schema.
| Field | Type | Default |
|---|---|---|
| `id` | `UUID` unique | `UUID()` |
| `month` | `Date` | *required* — "first day of the month this record represents" |
| `incomeAmount` | `Decimal` | *required* |
| `totalExpenses` | `Decimal` | *required* |
| `totalSavings` | `Decimal` | *required* |
| `remainingMoney` | `Decimal` | *required* |
| `transfersExecuted` | `Bool` | `false` |
| `createdAt` | `Date` | `Date()` |
| `accountSnapshotsData` | `Data?` (private) | JSON-encoded `[AccountSnapshot]` |

`AccountSnapshot` (`:6-29`): `accountId: UUID`, `accountName: String`, `accountType: String` (raw),
`balanceBefore: Decimal`, `transferAmount: Decimal`, `balanceAfter: Decimal`.
`monthDisplay` = `DateFormatters.monthYear` → e.g. `"December 2025"`.

⚠️ **`MonthlyRecord` is never written.** No `context.insert(MonthlyRecord…)` exists anywhere. The New
Month flow updates balances only (`MainTabView.swift:306-332`). Month history is therefore an
**unimplemented** capability despite the model existing — see `Docs/MVP/10-BudgetAnalysis.md`.

---

## 6. Seed / default data (verbatim)

### Default expense categories — THE canonical list

> ✅ **R6 verification — closed, no divergence possible.** R6 (since downgraded to a verification item)
> asked whether Domain's `Category.defaults` and the Features layer's `ExpenseCategory` agree
> field-for-field on name, icon, `colorHex` and **order**.
>
> **They agree on all four, necessarily and permanently, because they are the same type.**
> `ExpenseCategory` is a *type alias* for `Domain.Category` — not a wrapper, not a projection, not a
> parallel struct. `ExpenseCategory.defaults` and `Domain.Category.defaults` are two spellings of one
> static array. There is no code path on which a field could diverge, so there is no bug to name here
> and nothing to re-verify if Domain changes. Evidence:
>
> | Evidence | Result |
> |---|---|
> | `grep` for every declaration of `ExpenseCategory` | 3 aliases, all `= Domain.Category`: `Features/Expenses/Sources/Expenses/Expenses.swift:5`, `Platform/Persistence/Sources/Persistence/Models/CustomCategory.swift:6`, `Domain/Tests/DomainTests/CategoryTests.swift:6` |
> | `grep` for any second `defaults` category array | none — every reference resolves to `Domain.Category.defaults` (`ExpensesViewModel.swift:209,268`, `CategoryManagementView.swift:22`, `CategoryPicker.swift:46`) |
> | `grep` for the category name literals (`"Auto/Transport"`, `"Housing"`, …) outside Domain | **zero** occurrences in any Features file; all 8 names exist only in `Domain/Entities/Category.swift` (+ its tests) |
>
> The file originally cited, `Expenses/Components/ExpenseCategoryCard.swift`, defines
> `ExpenseCategoryCard` — a **SwiftUI `View`** — plus a `Color.init?(hex: String)` helper. No category
> data. The near-identical name (`ExpenseCategoryCard` vs `ExpenseCategory`) is the likely origin of
> the concern.
>
> **Order is Domain's order on every screen**, which is the part most worth pinning:
>
> | Render site | Source expression | Resulting order |
> |---|---|---|
> | Manage Categories, "Default Categories" section | `ForEach(ExpenseCategory.defaults)` (`CategoryManagementView.swift:22`) | declaration order = `sortOrder` 0→7 |
> | Expenses tab groups | `allCategories` = `(defaults + custom).sorted { $0.sortOrder < $1.sortOrder }` (`ExpensesViewModel.swift:268`) | defaults 0→7, then customs (all `sortOrder = 100`) |
> | Category picker in Add Expense | `viewModel.allCategories` | same as above, after a leading `None` row |
>
> Custom categories therefore always sort **after** all eight defaults, and ties among customs fall back
> to insertion order (`sorted` is not stable in Swift, so two customs are formally unordered — a latent
> nondeterminism worth avoiding on web by tie-breaking on `createdAt` or `name`).
>
> **Independent confirmation:** the walkthrough of Manage Categories (`reference-screens/15-manage-categories.jpg`)
> lists all **8** in exactly this order with matching icons and colours. The Expenses tab showed only 4
> because grouping omits categories with no expenses (`ExpensesViewModel.swift:308-313`), not because a
> rival list exists.
>
> The genuine two-list divergence is **docs vs code**, tabulated at the end of this section.

Source: `Packages/Core/Domain/Sources/Domain/Entities/Category.swift:51-150`.
Fixed UUIDs (`:51-58`) so ids are stable across launches. **These exact strings/UUIDs must be
reproduced** or existing expense `categoryId`s break. Confirmed live in
`Diameris/Resources/expenses_import.json`, whose expenses reference `D1A00001-…` and `D1A00007-…`.

| sortOrder | UUID | `name` | `icon` | `colorHex` | comment in code |
|---|---|---|---|---|---|
| 0 | `D1A00001-0000-0000-0000-000000000001` | `Auto/Transport` | `car.fill` | `#3B82F6` | Blue |
| 1 | `D1A00002-0000-0000-0000-000000000002` | `Subscriptions` | `repeat.circle.fill` | `#8B5CF6` | Purple |
| 2 | `D1A00003-0000-0000-0000-000000000003` | `Lifestyle` | `sparkles` | `#F59E0B` | Amber |
| 3 | `D1A00004-0000-0000-0000-000000000004` | `Housing` | `house.fill` | `#10B981` | Emerald |
| 4 | `D1A00005-0000-0000-0000-000000000005` | `Pets` | `pawprint.fill` | `#EC4899` | Pink |
| 5 | `D1A00006-0000-0000-0000-000000000006` | `Health/Fitness` | `heart.fill` | `#EF4444` | Red |
| 6 | `D1A00007-0000-0000-0000-000000000007` | `Food/Groceries` | `cart.fill` | `#22C55E` | Green |
| 7 | `D1A00008-0000-0000-0000-000000000008` | `Entertainment` | `tv.fill` | `#06B6D4` | Cyan |

All have `isDefault = true`. `Category.defaults` returns them in exactly this order (`:141-150`) and
the Expenses tab renders them in `sortOrder` order via
`allCategories = (defaults + custom).sorted { $0.sortOrder < $1.sortOrder }`
(`ExpensesViewModel.swift:268`) — custom categories all carry `sortOrder = 100`, so they always sort
**after** all eight defaults.

`Category.defaultCategory(for: id)` (`:153-155`) is a linear lookup over **this array only** — it
returns `nil` for custom categories. That is why `ExpenseEntry.category()` cannot resolve custom
categories and the Expenses feature uses `allCategories` instead.

**Category names are NOT localized** — they are raw English literals in Domain (unlike account-type
display names, which are). They render identically in EN and RO.

#### ⚠️ The real divergence: code (8) vs `Docs/MVP/04-Categories.md` (6)

`Docs/MVP/04-Categories.md:62-131` specifies a different list. **Use the code's, above.** Recorded
here so Backend does not "fix" the code list toward the doc:

| Doc name | Doc UUID | Doc icon | Doc hex | → Code icon | → Code hex | Divergence |
|---|---|---|---|---|---|---|
| Auto/Transport | `00000000-…-0001` | `car.fill` | `#3B82F6` | `car.fill` | `#3B82F6` | ⚠️ **UUID only** |
| Subscriptions | `…-0002` | `tv.fill` | `#8B5CF6` | `repeat.circle.fill` | `#8B5CF6` | ⚠️ UUID + **icon** |
| Lifestyle | `…-0003` | `heart.fill` | `#EC4899` | `sparkles` | `#F59E0B` | ⚠️ UUID + **icon + colour** |
| Housing | `…-0004` | `house.fill` | `#F59E0B` | `house.fill` | `#10B981` | ⚠️ UUID + **colour** |
| Pets | `…-0005` | `pawprint.fill` | `#10B981` | `pawprint.fill` | `#EC4899` | ⚠️ UUID + **colour** |
| Health/Fitness | `…-0006` | `figure.run` | `#06B6D4` | `heart.fill` | `#EF4444` | ⚠️ UUID + **icon + colour** |
| *(absent)* | — | — | — | `cart.fill` | `#22C55E` | ⚠️ **Food/Groceries is code-only** |
| *(absent)* | — | — | — | `tv.fill` | `#06B6D4` | ⚠️ **Entertainment is code-only** |

Every UUID differs (`00000000-…` vs `D1A0000N-…`), 3 icons differ, 4 colours differ, and the code adds
2 categories. Note the colours were *rotated*: the doc's Lifestyle pink `#EC4899` is the code's Pets
colour, the doc's Housing amber `#F59E0B` is the code's Lifestyle colour, and so on. Seeding the doc's
values would produce a plausible-looking but wrong palette **and** break every stored `categoryId`.

### Default accounts
`AccountEntry.defaults == [.primary()]` → one account: name "Main Account", purpose
"Where your salary lands", type `.primary`, `isPrimary = true`, balance 0
(`AccountEntry.swift:146-148`).

### Onboarding seed expenses — `OnboardingViewModel.swift:16-21`
Four rows, all `amount = 0`, all `.monthly`:

| name (localized key) | icon | categoryId |
|---|---|---|
| `Food` | `cart.fill` | `Category.foodGroceries.id` |
| `Rent` | `house.fill` | `Category.housing.id` |
| `Gas` | `fuelpump.fill` | `Category.autoTransport.id` |
| `Streaming` | `tv.fill` | `Category.subscriptions.id` |

⚠️ Note the icon/category mismatch vs the category's own icon (`Gas` uses `fuelpump.fill` while
Auto/Transport is `car.fill`) — intentional, expenses carry their own icon.

### Other seeded defaults
- `OnboardingViewModel`: `currency = Currency.fromLocale()`, `monthlyIncome = 0`, `name = ""`,
  `savingsAllocation = SavingsAllocationEntry()` (all defaults from §2),
  `remainingMoneyDestination = .primarySavings`, `currentStep = .welcome`.
- Income row is created with `name = "Salary".localized` (`OnboardingViewModel.swift:171`).
- `AddCategorySheet` new-category defaults: `selectedIcon = "star.fill"`, `selectedColor = "#3B82F6"`
  (`CategoryManagementView.swift:117-118`), `sortOrder = 100`.
- `ExpenseInput` default icon: `"dollarsign.circle.fill"` (`ExpensesViewModel.swift:120`).
- `ExpensesViewModel.currency` default: **`.usd`** (`ExpensesViewModel.swift:215`) —
  ⚠️ inconsistent with `DashboardViewModel.currency` default `.ron` (`DashboardViewModel.swift:121`)
  and `Currency.fromLocale()`'s fallback `.ron`. Both are overwritten from the profile at load, but
  the transient default differs.

---

## 7. Formatting & currency

`Packages/Core/Utilities/Sources/Utilities/` — pure Foundation, portable.

### `Currency` (`Currency.swift:4-31`)
`enum Currency: String, CaseIterable, Identifiable, Sendable`, `id == rawValue`.

| rawValue | `symbol` | `displayName` |
|---|---|---|
| `RON` | `lei` | `Romanian Leu (RON)` |
| `EUR` | `€` | `Euro (EUR)` |
| `USD` | `$` | `US Dollar (USD)` |

`fromLocale()`: `Locale.current.currency?.identifier` → matching case, else **`.ron`**.
⚠️ `symbol` is defined but **never used anywhere in the UI** — every amount is rendered with the
`rawValue` code appended. `displayName` is not localized.

### `AmountFormatter` (`AmountFormatter.swift:4-44`)
- **`formatForDisplay(_:currency:)`** — `NumberFormatter`, `.decimal`,
  `maximumFractionDigits = 0`, `groupingSeparator = ","`. Returns `"\(formatted) \(currency)"`.
  → `14303` + `"RON"` ⇒ **`"14,303 RON"`**. Rounding is `NumberFormatter`'s default
  (`.halfEven`, banker's rounding). Locale-independent grouping (forced comma), but grouping *size*
  comes from the current locale's `.decimal` style.
  Failure path returns the string `"0"`.
- **`formatForEditing(_:)`** — returns **`""`** when `amount <= 0`; otherwise `.decimal` with
  `maximumFractionDigits = 2`, `minimumFractionDigits = 0`, `groupingSeparator = ""`.
- **`parse(_:)`** — replaces **all** `,` with `.`, then `Decimal(string:)`; returns `0` on failure.
  ⚠️ So `"1,234"` parses as **1.234**, not 1234. Web port must match this (or fix deliberately).

### `DateFormatters` (`DateFormatters.swift:5-33`)
| Name | Format | Example |
|---|---|---|
| `monthYear` | `"MMMM yyyy"` | December 2025 |
| `shortMonthYear` | `"MMM yyyy"` | Dec 2025 |
| `fullDate` | `dateStyle = .long` | December 29, 2025 |
| `shortDate` | `dateStyle = .short` | 12/29/25 |

Only `monthYear` is actually used (`DashboardViewModel.currentMonthDisplay`, `MonthlyRecord.monthDisplay`).
These use the device locale, so the Dashboard title is locale-formatted while amounts are not.

---

## 8. Golden references for parity verification

Two assets in the repo are directly usable as the numeric oracle for the web port.

### 8.1 The existing Swift Testing suites — 467 `@Test` cases, 132 `@Suite`s

| File | `@Test` | `@Suite` | Covers |
|---|---|---|---|
| `Domain/Tests/DomainTests/TransferCalculatorTests.swift` | 46 | 11 | **the whole algorithm** — suites: Basic Calculations, Emergency Account Priority, Savings Account Behavior, Boost Mode, Expense Distribution, Remaining Money, Edge Cases, **Real World Scenarios**, Split Allocation Mode, Fixed Amount Savings Mode |
| `Domain/…/SavingsAllocationEntryTests.swift` | 46 | 11 | percentage/fixed/split resolution, boost cap, `isValid` |
| `Domain/…/AccountEntryTests.swift` | 35 | 8 | `emergencyTarget` / `emergencyProgress` / `isEmergencyComplete`, factories |
| `Domain/…/AccountTypeTests.swift` | 28 | 9 | raw values, icons, `isUnique`, `hasBehavior` |
| `Domain/…/CategoryTests.swift` | 26 | 7 | the 8 defaults, fixed UUIDs, lookup |
| `Domain/…/ExpenseEntryTests.swift` | 23 | 8 | monthly/annual conversion |
| `Domain/…/FrequencyTests.swift` | 17 | 7 | multipliers |
| `Utilities/…/AmountFormatterTests.swift` | 29 | 6 | `formatForDisplay` / `formatForEditing` / `parse` — **the exact string outputs** |
| `Utilities/…/CurrencyTests.swift` | 20 | 8 | codes, symbols, `fromLocale()` |
| `Dashboard/Tests/…/DashboardViewModelTests.swift` | 59 | 14 | `totalSavings`, `computeUpdatedBalances`, transfer-plan wiring |
| `Dashboard/Tests/…/DashboardAccountTests.swift` | 18 | 4 | delegation to Domain |
| `Expenses/Tests/…/ExpensesViewModelTests.swift` | 48 | 16 | grouping, search, totals, optimistic mutations |
| `Onboarding/Tests/…/OnboardingViewModelTests.swift` | 46 | 12 | `canAdvance`, step order, `save` balance maths |
| `Persistence/Tests/…/PersistenceTests.swift` | 16 | 6 | model round-trips |
| `DesignSystem/Tests/…/DesignSystemTests.swift` | 10 | 5 | token values |

**These are the parity oracle.** Port the assertions from `TransferCalculatorTests`,
`SavingsAllocationEntryTests`, `AccountEntryTests` and `AmountFormatterTests` verbatim into the web
test suite — every expected value in them was computed by the shipped Swift code. In particular
"Real World Scenarios" (`TransferCalculatorTests.swift:681-777`) contains end-to-end fixtures.

### 8.2 `Diameris/Resources/expenses_import.json` — a real user snapshot

`version 1.1`, `exportDate 2025-12-29T23:01:50.222377`. Romanian data, matching the numbers used in
every `Docs/MVP` mock:

```
income:        { amount: 14303, frequency: "monthly", name: "Salariu" }
savings:       { percentage: 0.25, boostEnabled: true, boostMultiplier: 3 }
emergencyFund: { currentBalance: 37056, targetMultiplier: 3.0 }
accounts:      5 entries
expenses:      18 entries   (e.g. "Mâncare" 3000 monthly cart.fill → D1A00007…;
                                  "Benzină"  300 monthly fuelpump.fill → D1A00001…)
```

Note the `categoryId`s use the **code's** `D1A0000N-…` UUIDs, confirming those are the live values.
Use this file as the seed fixture for end-to-end web parity checks: import it, run the calculator, and
diff against the iOS app driven with the same import (the DEBUG dev tools can load it — §9 of
`PARITY-SPEC.md`).

---

## 9. Things that cannot exist on web, and the stated fallbacks

| iOS-only | Where | Fallback |
|---|---|---|
| **Haptics** (`HapticManager`, 8 methods) | ~40 call sites across all features | No web equivalent. `navigator.vibrate()` is Android-Chrome only. Drop silently; keep the *visual* state change that accompanied each haptic. Every call site is listed in `PARITY-SPEC.md`. |
| **SwiftData** (`@Model`, `@Query`, `ModelContext`, `ModelContext.didSave` notifications) | `Persistence`, `MainTabView`, `SettingsSheet`, `DevDebugView` | Replace with a web store. Note the app's data-flow contract: a single `DataObserver` (`DataObserver.swift:27-41`) listens to `ModelContext.didSave` and re-runs `refreshAllData()`, i.e. **any save re-derives every view model from scratch**. Reproduce that "save → full refresh" semantic. |
| **Liquid Glass** (`.glassEffect`, `GlassEffectContainer`, `glassEffectID`, `.buttonStyle(.glass/.glassProminent)`) | Everywhere | `backdrop-filter: blur()` + translucent background. Morph transitions (`glassEffectID`) have no direct equivalent — see `DESIGN-TOKENS.md`. |
| **`UIKeyboardType` / `.decimalPad`** | `OnboardingTextField`, every amount field | `<input type="text" inputmode="decimal">`. |
| **`KeyboardHelper.dismiss()`** | onboarding advance, New Month steps | `activeElement.blur()`; the 100–150 ms sleeps that exist to let the keyboard animate out (`DiamerisApp.swift:83-88`, `OnboardingViewModel.swift:54-57`) are unnecessary on web. |
| **`@AppStorage("onboardingCompleted")`** | `AppStorageKeys.swift:4`, `DiamerisApp.swift:45`, `DevDebugView.swift:9` | `localStorage` key `onboardingCompleted` (boolean). |
| **`symbolEffect(.pulse/.bounce)`, `contentTransition(.numericText())`** | Welcome/Header icons; every animated amount | CSS keyframes; a digit-roll/crossfade component. |
| **SF Symbols** | everywhere | Needs an icon-set mapping — full inventory in `DESIGN-TOKENS.md`. |
| **Foundation Models / on-device LLM** | **not present in code at all** | `Docs/FoundationModels-Using-on-device-LLM.md` and `Docs/Diameris-AI-Features.md` are pre-MVP brainstorming; the Insights tab is a hardcoded "Coming soon" placeholder (`MainTabView.swift:337-357`). Nothing to port. |
