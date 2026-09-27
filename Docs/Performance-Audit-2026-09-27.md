# Performance & Bundle Size Audit — 2026-09-27

Goal: a smoother, faster app with no behaviour change and no new features. Bundle size was measured
too, but **speed wins over size**: the app is already small (≈2.3 MB installed, ≈0.9 MB zipped),
so no change that trades runtime speed for size was kept.

**Rule applied:** every change is behaviour-preserving, backed by a measurement or by Apple's
SwiftUI guidance (`xcode-integration:swiftui-specialist`), and covered by the existing suites plus a
new test where a regression was possible.

---

## 1. Changes

| # | Change | Why | Evidence |
|---|---|---|---|
| P1 | `AmountFormatter` caches one `NumberFormatter` per locale (display and editing), behind a `Mutex` | Every amount label in every row/card/body created a new `NumberFormatter` | Benchmark: 40 amounts **352 µs → 30 µs** (11.7×), 3 runs, same process |
| P2 | `OnboardingViewModel.transferPlan` is stored and recomputed in the `didSet` of its five inputs (income, expenses, accounts, allocation, destination) | It was a computed property running the whole `TransferCalculator` on every read — about 25 reads per `TransferPlanScreen` body, several per `SavingsScreen` body | New test *The stored transfer plan follows every input change* (red when any `didSet` is removed) |
| P3 | `TransferPlan` (and its nested types) are `Equatable` | Lets Observation skip notifying when a recomputed plan is identical | — |
| P4 | `SavingsSlider` skips writes when the dragged percent hasn't changed | Nested writes through a binding (`$vm.savingsAllocation.percentage`) **always** notify, even with an equal value, so almost every drag event re-rendered the Savings screen | Verified with a standalone Observation probe (see §3) |
| P5 | `Color(light:dark:)` converts to `UIColor` once, not inside the trait provider | The provider runs on every trait resolution | — |
| P6 | `expenses_import.json` excluded from **Release** builds (`EXCLUDED_SOURCE_FILE_NAMES`, both app targets) | Dev-only (`DevDebugView` is `#if DEBUG`), and it holds real account/expense data | Archive no longer contains it; Debug still does (dev import verified in the simulator) |

## 2. Measurements

### Micro-benchmarks (macOS, release build, M-series)

A scratch SwiftPM executable linked the real `Domain` and `Utilities` packages; each case was warmed
up, then the median of 5 runs was taken.

| Operation | Before | After |
|---|---|---|
| `AmountFormatter.formatForDisplay`, 40 amounts | 352 µs | 30 µs |
| `TransferCalculator.calculate`, 30 expenses / 6 accounts | 18–22 µs | unchanged (now run once per input change in onboarding instead of once per read) |
| `[ExpenseEntry].totalMonthly`, 30 expenses | 9 µs | unchanged |

### Bundle (archive, `generic/platform=iOS`, unsigned)

| Build | App | Binary | Zipped |
|---|---|---|---|
| Baseline (HEAD) | 2,288 KB | 2,223,840 B | 887,822 B |
| After this audit | 2,300 KB | 2,241,112 B | 891,988 B |
| `-Osize` (measured, **not adopted**) | 1,968 KB | 1,902,568 B | 863,966 B |

The new code costs ≈17 KB of binary, more than the 5 KB JSON saves. `-Osize` would cut 15% of
installed size (3% zipped) for a 1–3% slowdown on Domain hot paths. It was rejected because speed
comes first. It would also need `unsafeFlags` in every package: a project-level
`SWIFT_OPTIMIZATION_LEVEL` reaches only the app module, since SPM packages keep `-O`.

## 3. Findings worth knowing

- **Observation skips equal top-level writes, not nested ones.** With Swift 6.2's `@Observable`,
  `model.value = sameValue` doesn't notify when the type is `Equatable`, but
  `model.structProperty.field = sameValue` (what `$model.structProperty.field` bindings do) always
  notifies. Guard high-frequency writers (drag gestures, timers) against equal values.
- **Computed properties on `@Observable` models are not cached.** A view that reads
  `model.expensiveThing` N times runs it N times per body. Store derived values and refresh them
  from the inputs' `didSet` (Apple's "Cache derived @Observable values" guidance).
- **Plain Release `build`s are instrumented for coverage.** The scheme's auto-created test plan
  enables code coverage (`ENABLE_CODE_COVERAGE = YES`), so `xcodebuild build -configuration
  Release` binaries carry ≈330 KB of `__llvm_prf_*` / `__LLVM_COV` sections, and they aren't
  stripped either (8.2 MB binary). `archive` turns coverage off and strips, so shipped builds are
  unaffected. Measure size from an **archive**.

## 4. Looked at and left alone

- `ExpensesViewModel.expenseGroups` / `allCategories` are computed per body, but the list body only
  re-runs when expenses, categories, search text or frequency change, and the data is tens of rows.
- Expanding one expense category re-renders every card (they share the `expandedCategories` set);
  cheap after P1.
- Confetti already draws from a `TimelineView` (no per-frame state); the Welcome glow blur is static.
- Launch: container creation and the two startup repairs are small fetches.
- Hex color parsing in `ExpenseCategoryCard` (`Scanner`) runs per body but costs ~1 µs; replacing
  it would change how malformed hex is handled.

## 5. Verification

- Unit tests: Domain 62, Utilities 9, DesignSystem 4, SharedUI 2, Persistence 31, Dashboard 18,
  Expenses 12, Onboarding 38 (+1 new) — all pass.
- Simulator (iPhone 17 Pro, light + dark): Dashboard and Expenses show Romanian-grouped amounts
  (`8.500 RON`, monthly/annual toggle, expanded rows). Onboarding was run through to the Transfer
  Plan: available income, boost (1.875 → 5.625 RON) and the destination change all update live,
  and the plan balances ("Total: 10.000 RON, All accounted for!").
- The custom slider can't be dragged through AXe (it exposes no drag target), so P4 rests on its
  equal-value guard and the plan-sync test rather than a simulated drag.
