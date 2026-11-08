# PARITY REGISTER — enumerated deviations & unreachable strings

R6 requires deviations be **enumerated, not described**: *if a deviation is not listed here, it is a bug.*
This is the Analyst's consolidated list, feeding `PARITY-GAPS.md`. Every row carries a **reason** and
**evidence**, so a future reader can re-derive it rather than delete it as dead weight.

Companion docs: `PARITY-SPEC.md` (screens), `DOMAIN-CONTRACT.md` (calculations), `LOCALIZATION.md`
(catalogs), `DESIGN-TOKENS.md` (visuals).

---

## A. Strings that MUST stay English — the R35 guard allowlist

Each renders English on iOS too. Translating any of them is a **silent improvement (R26a)**. This is the
allowlist the key-resolution guard must carry; without it the guard flags these as defects and pushes
someone into exactly the violation it exists to prevent.

| # | Key | Why iOS shows English | Evidence |
|---|---|---|---|
| 1 | `Back` | absent from the `dashboard` catalog, so `.localized` falls back to the key | `NewMonthSheet.swift:49`; catalog lookup returns nothing |
| 2 | `Developer Tools` | absent from every catalog — `#if DEBUG`-only code was never extracted | `DashboardView.swift:48` |
| 3 | `%lld percent complete` | `String(localized:)` with **no `bundle:`** → resolves against `.main`; app catalog has no entry | `ProgressRing.swift:46`; SharedUI has no catalog |
| 4 | `Monthly` | `Frequency.displayName` binds **Domain**'s bundle, which lacks the key. `"Lunar"` exists only in `expenses`, which that call site never reads | `Frequency.swift:33-38` |
| 5 | `Annual` | same as `Monthly` | `Frequency.swift:33-38` |
| 6 | `Romanian Leu (RON)` | `Currency.displayName` has **no `.localized` call at all** — bare Swift literals | `Utilities/Currency.swift:19-25` |
| 7 | `Euro (EUR)` | same | `Utilities/Currency.swift:19-25` |
| 8 | `US Dollar (USD)` | same | `Utilities/Currency.swift:19-25` |

⚠️ **`Annual` has a live exception that must NOT be allowlisted away:** `ExpenseItemRow.swift:60`'s
`"Annual".localized` binds the **Expenses** bundle, where `Annual = "Anual"` exists. So the `(Anual)`
caption is correct *underneath a segmented control still reading `Annual`*. Reproduce that contradiction.

---

## B. The `tDomain` matrix — which served `displayName`s to translate

Every `*DisplayName` in an API response is an **English lookup key**, not display text (see §E1).
"Translate them all" is wrong for two of six.

| Enum | Domain RO | iOS in RO | Web must |
|---|---|---|---|
| `AccountType` (6 cases) | 6/6 | Romanian | ✅ `tDomain` |
| `AllocationMode` (2) | 2/2 | Romanian | ✅ `tDomain` |
| `SavingsInputMode` (2) | 2/2 | Romanian | ✅ `tDomain` |
| `RemainingMoneyDestination` (3) | 3/3 | Romanian | ✅ `tDomain` — but see B1 |
| **`Frequency`** (2) | **0/2** | **English** | ⛔ **raw** |
| **`Currency`** (3) | **0/3** | **English** | ⛔ **raw** |

⚠️ **The matrix covers more than `displayName`.** `description` is a *second* Domain-localized property
and is fully translated for `AccountType` (6), `AllocationMode` (2) and `RemainingMoneyDestination` (3).
It must go through `tDomain` too. Verified correct in `SettingsSheet.tsx:170`.

### B1. `RemainingMoneyDestination.primary` — two labels for one case (declaration shadowing)

`SettingsSheet.swift:698-706` declares a **`private extension RemainingMoneyDestination { var displayName }`**
that shadows Domain's *for that file only*. Both translate, so this is not English leakage — it is two
correct labels depending on the screen.

| Case | Settings (`app` catalog) | Onboarding (`domain` catalog) |
|---|---|---|
| `primary` | **"Primary Account"** / `Cont principal` | **"Keep in Primary"** / `Păstrează în Principal` |
| `primarySavings` | "Primary Savings" / `Economii principale` | identical |
| `personal` | "Personal Account" / `Cont personal` | identical |

Web must scope the override to `.primary` only. Verified correct: `SettingsSheet.tsx:318` —
`value === 'primary' ? t('Primary Account') : tDomain(domainDisplayName)`.

---

## C. Unreachable catalog entries — 81 of 352 rows

From the systematic sweep (`LOCALIZATION.md §3.4`). 271 rows verified reachable.

| Class | n | Meaning | Action | Example |
|---|---|---|---|---|
| **A** wrong Romanian | 3 | copy's RO ≠ producing module's RO | 🔴 entry **dropped** | `app.Other = "Altele"` vs Domain's `"Altul"` |
| **B** Romanian where English is correct | 2 | copy has RO; producing module's catalog has none → iOS falls back to English | 🔴 **RO dropped**, EN kept | `expenses.Monthly = "Lunar"`, `expenses.Amount = "Sumă"` |
| **C** benign duplicate | 21 | identical RO both sides | 🟢 harmless | `onboarding.Joint` == `domain.Joint` |
| **D** dead interpolated | 1 | `%@` key that `"...".localized` can never produce | 🟡 dead — do not wire up | `expenses.'Total %@ Expenses' = "Cheltuieli %@ totale"` |
| **E** no call site | ~55 | literal in no Swift source — stale keys from removed code | 🟡 dead, harmless | `Add Subcategory`, `Main Checking`, `Your Goals` |
| **F** variant mismatch | 2 pairs | re-extraction left a *translated stale* variant beside an *untranslated live* one | 🔴 stale RO **dropped** | live `Step %lld of %lld` (no RO) vs stale `Step %d of %d` (`"Pasul %d din %d"`) |

Enforced by `Web/gen-locales.py`; `--check` is a required CI step (R27).

---

## D. Accepted behavioural deviations

| # | Deviation | Reason | Evidence |
|---|---|---|---|
| D1 | **Loading state exists on web, not on iOS** | SwiftData is synchronous; HTTP is not. Kept deliberately plain so it isn't graded as invented UI | `PARITY-SPEC.md §0.3`; `App.test.tsx:8-15` |
| D2 | **Developer Tools is a dev-only route, not a toolbar button** | iOS gates both the view *and* its entry point behind `#if DEBUG`, so a shipping user cannot reach it. An always-visible button is the opposite of that | R16/R28c; `DashboardView.swift:46-50` |
| D3 | **Dev harnesses exist that iOS has no analogue for** (`?dev=gallery`, `?dev=modals`, `?dev=onboarding`) | Review/screenshot surfaces; route-gated, unreachable from app navigation | `modals/index.ts:15`; `App.tsx:20-21` |
| D4 | **Reduce Motion is honoured on web; iOS never reads it** | `accessibilityReduceMotion` appears nowhere in the iOS codebase despite `DesignGuidelines` requiring it. `prefers-reduced-motion` is a free accessibility win | grep: 0 occurrences |
| D5 | **Responsive layout; iOS is iPhone-only** | no `NavigationSplitView` / `ViewThatFits` / `horizontalSizeClass` anywhere in iOS | grep: 0 occurrences |
| D6 | **Custom-category sort is tie-broken on `createdAt`/`name`** | iOS uses `sorted { $0.sortOrder < $1.sortOrder }`, which is **not stable** in Swift, and all customs share `sortOrder = 100` — so two customs are formally unordered upstream | R17; `ExpensesViewModel.swift:268` |

---

## E. Upstream quirks reproduced deliberately (NOT bugs to fix)

| # | Quirk | Detail | Evidence |
|---|---|---|---|
| E1 | **Server cannot serve Romanian** | SwiftPM never compiles `.xcstrings`, so the Domain bundle ships the raw file and every `.localized` returns the English key. Client-side `tDomain` is therefore mandatory | `DOMAIN-CONTRACT.md §1`; live `/api/state` returns `"Emergency"`, `"Priority"` |
| E2 | **`AmountFormatter.parse` treats `,` as a decimal point** | `"1,234"` parses as **1.234**. All commas → dots before `Decimal(string:)` | `AmountFormatter.swift:37-43` |
| E3 | **Annual normalisation is imprecise** | `amount × 0.08333…333` (28 digits), **not** `amount / 12`. Annual 1200 → `99.999999999999999999999999999999999996`. Invisible on screen (0 dp), so a `/12` "tidy" passes every screenshot while changing stored values | probed in real Swift; `Frequency.swift:9-14` |
| E4 | **Two rounding rules** | money → **half-even**; percentages → **truncated** via `Int(Double)`. `0.119 → 11%`, confirmed on device (`120/4270 = 2.81% → 2%`) | `PARITY-SPEC.md §0.3` |
| E5 | **Expenses header is fully English** | `"Total \(x) Expenses".localized` interpolates *before* lookup, so the runtime key never matches the catalog's `Total %@ Expenses`; and the inner word fails separately (allowlist #4) | `ExpenseListView.swift:91` |
| E6 | **Emergency caption is Romanian only when a hard cap is set** | only the *capped* variant is both live **and** translated. Uncapped → the live key `Target: %lld× monthly income` has no RO → English | `EmergencyProgressCard.swift:76-84` |
| E7 | **Search narrows rows but not the header total** | `displayTotal` reads `expenses`; `expenseGroups` reads `filteredExpenses` | `ExpensesViewModel.swift:271-292` |
| E8 | **New Month shows nothing when the plan is unbalanced** | badge is `if isBalanced` with no warning variant. Onboarding *does* warn — do not unify | `TransferPlanStep.swift:333-349` vs `TransferPlanScreen.swift:257-279` |
| E9 | **`Done - I made the transfers` uses a hyphen, not an en dash** | one wrong glyph costs both the glyph and the Romanian | `TransferPlanStep.swift:45`; fixed as R28-family |
| E10 | **Onboarding remaining-money can vanish** | with no primary-savings account, `.primarySavings` stays selected but matches no account, so `remainingMoney` is credited to nothing while still displayed | `OnboardingViewModel.swift:215-230` |
| E11 | **`Account(from: entry)` regenerates the UUID** | onboarding `linkedAccountId`s point at ids no persisted `Account` has | `Account.swift:46` |
| E12 | **`+0 RON` emergency row in Prioritized only** | appended because `targetAmount != nil` even at `amount == 0`; Split appends nothing. Never filter the row loop — gate the card on `hasTransfers` | `TransferCalculator.swift:109-112` vs `:176-178` |

---

## F. Features specified but absent from iOS — nothing to port

| Feature | Doc | Status |
|---|---|---|
| Loans | `Docs/MVP/06-Loans.md` (464 lines) | no model, view or repository; the only occurrence is a test expense named "Car Loan" |
| Budget Analysis — health score, benchmarks, recommendations | `Docs/MVP/10` (524 lines) | absent; Insights is a hardcoded "Coming soon" |
| Transfer checklist — checkboxes, Copy buttons, `MonthlyTransferStatus` | `Docs/MVP/09` | absent; replaced by the New Month flow |
| Savings-rate assessment (5 tiers) | `Docs/MVP/07:129-180` | absent |
| Month history | — | `MonthlyRecord` model exists but is **never written or read** |
| Settings: export / reset / version / privacy / support | `Docs/MVP/11` | absent |
| Foundation Models / on-device LLM | several docs | no FM code at all; the documented "fallback" *is* the shipped behaviour |

---

## G. Standing rule #3 — the four-clause form

`.localized` names a **lookup**, not a translation. Whether it resolves depends on:

1. **Which bundle the call site binds** — `.module` of the *defining* module, or `.main` when no `bundle:`
   is passed (SharedUI/Utilities → the app catalog).
2. **Whether that catalog holds the key** — a translation in a *different* catalog is unreachable.
3. **Which call form is used** — `"a \(x) b".localized` interpolates *before* lookup (runtime key is the
   filled string, so a `%@` catalog key can never match); `String(localized:)` / `String.localized()`
   capture placeholders and *do* match.
4. **Which declaration the symbol resolves to** — a file-private extension can **shadow** a Domain
   property for that file only (B1). Same symbol, same call, different string.

**Check the call site, the resource, the form, and the declaration.** Three of the five orphan classes
above were found by clauses 1–2, Class D by clause 3, Class F by reading Swift *types* (which no
scanner here can do), and B1 by clause 4.
