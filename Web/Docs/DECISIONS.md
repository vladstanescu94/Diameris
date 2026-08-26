# Web Client — Architecture Decisions

Status: **proposed by the orchestrator, open to challenge by the Critic.**
Anything the Critic rejects with a concrete better alternative gets changed.

### Environment facts (verified by the orchestrator, 2026-08-06)
- Swift 6.3.3, target `arm64-apple-macosx26.0`.
- **Vapor 4.122.0 resolves and builds clean on macOS** (throwaway package, `swift build`
  succeeded in 63s). Network access to GitHub works.
- Node v24.4.1, npm 11.4.2, registry reachable.
- So the *server* half of D1 is proven. The open question the Critic must settle is
  whether `Domain`/`Utilities` themselves compile for macOS.

## Goal

A **local, laptop-only** web client for Diameris that is **1:1 with the iOS app** —
same screens, same strings, same numbers, same visual language. Runs from one command,
no cloud, no accounts, no external services.

## D1 — Reuse the Swift Domain layer via a Vapor server (not a TS reimplementation)

`Packages/Core/Domain` is pure Swift (entities + `TransferCalculator`) and the project
rule is *"Business Logic Lives in Domain Only — never duplicate across layers"*
(`CLAUDE.md`). A TypeScript reimplementation of the allocation maths would duplicate it
and drift, which is exactly what breaks 1:1 parity.

**Decision:** a Vapor HTTP server (`Web/Server`) that depends on the *existing*
`Domain` and `Utilities` SPM packages and exposes them over JSON. The browser holds
**zero** business logic — it renders what the server computes.

Required changes to existing code — **this list is exhaustive and authorised; anything
beyond it must be escalated to `main` before being made. Do not silently edit iOS code.**

1. Add `.macOS(.v26)` to the `platforms:` array of `Packages/Core/Domain/Package.swift`
   and `Packages/Core/Utilities/Package.swift`. Additive; cannot affect the iOS build.
2. `Packages/Core/Utilities` contains exactly two UIKit-dependent files —
   `HapticManager.swift` and `KeyboardHelper.swift` (both `import UIKit` on line 1).
   Wrap each file's entire contents in `#if canImport(UIKit)` … `#endif`.
   On iOS `canImport(UIKit)` is always true, so the iOS build is byte-for-byte unaffected;
   on macOS the two types simply do not exist, which is correct — the server needs neither.
   `Packages/Core/Domain` is already clean (verified: no UIKit/SwiftUI/Combine imports, no
   `#if os(...)`, no availability pins).

After (1) and (2), the server may depend on `Utilities` for `AmountFormatter`, `Currency`
and `DateFormatters` — which is what guarantees identical money formatting — instead of
reimplementing them.

**Rounding is settled:** `AmountFormatter.formatForDisplay` uses `NumberFormatter` with
`maximumFractionDigits = 0` and a forced `","` grouping separator, so rounding is
`NumberFormatter`'s default **half-even (banker's)**. That is why `1182.5 → "1,182"` and
`3547.5 → "3,548"`. The web client must implement half-even, not `Math.round`.

⚠️ Known iOS bug to preserve deliberately: `AmountFormatter.parse` replaces *all* commas
with periods, so `"1,234"` parses as `1.234`. The web client reproduces the iOS behaviour
rather than fixing it, so numbers match; logged in `PARITY-GAPS.md` as an upstream bug.

⚠️ `TransferCalculator.distributeExpenses` builds its result by iterating a
`Dictionary(grouping:)`, so **`accountExpenseTransfers` comes out in nondeterministic
order**. The server must sort it (by account name) before serialising, or the web UI will
reorder rows between requests where iOS happens not to. Sorting in the server is allowed;
changing Domain is not.

## D2 — Persistence: JSON document store, not SwiftData, not Fluent

`Packages/Platform/Persistence` is SwiftData and iOS-only; it cannot be reused server-side.
This is a single-user local app with one small aggregate (profile + settings + accounts +
expenses + categories). A Fluent/SQLite layer would mean a third set of models duplicating
Domain for no benefit.

**Decision:** one JSON document at `~/.diameris/web-store.json`, owned by an `actor`,
written atomically (temp file + rename). Versioned with a `schemaVersion` field.
Seeded with the same default categories/settings the iOS app seeds.

## D3 — Frontend: Vite + React + TypeScript

Hand-rolled vanilla DOM would not survive the amount of stateful UI here (5-step onboarding,
3-step modal flow, sheets, segmented controls, sliders). React + Vite is the least-friction
choice that stays entirely local.

- No CSS framework. A hand-written stylesheet driven by CSS custom properties generated
  from `DESIGN-TOKENS.md`, so tokens have exactly one definition.
- Liquid Glass approximated with `backdrop-filter: blur() saturate()`, layered
  translucent fills, hairline borders and soft shadows. Light **and** dark via
  `prefers-color-scheme` plus an explicit override.
- Icons: SF Symbols cannot be redistributed. Use **Lucide** (ISC licensed, npm) with an
  explicit `SFSymbol → Lucide` mapping table so every icon choice is reviewable.
- i18n: EN + RO, same keys as the iOS catalog, simple `t()` over a JSON dictionary.

## D4 — API shape

REST, JSON, `snake_case` off / `camelCase` on (Swift-native), all money as **decimal
strings** (never JS floats — that would break the 1182.5 / 3547.5 cases).

```
GET  /api/state                 → whole app state + derived summary
POST /api/onboarding/complete   → body: the onboarding payload
PUT  /api/settings
GET/POST/PUT/DELETE /api/accounts[/:id]
GET/POST/PUT/DELETE /api/expenses[/:id]
GET  /api/categories
GET  /api/transfer-plan         → TransferCalculator output
POST /api/new-month             → income + balances → applies the month
POST /api/reset                 → dev tools parity
```

The server also serves the built SPA from `/` so there is a single origin and no CORS.

## D5 — One command to run

`Web/run.sh` — builds the frontend if stale, then `swift run` the server on
`http://localhost:8080`. `Web/dev.sh` runs Vite dev server + server with proxy for
iteration. Documented in `Web/README.md`.

## D6 — Definition of "1:1"

Parity is judged against `Web/Docs/GROUND-TRUTH.md`, `PARITY-SPEC.md` and the reference
screenshots, on these axes, in priority order:

1. **Numeric** — every computed value matches the iOS app for the same inputs. Non-negotiable.
2. **Content** — every screen, section, row, label, caption, empty state and validation
   message exists, in the same order, with the same wording.
3. **Behavioural** — same navigation, same modals, same enable/disable rules, same defaults.
4. **Visual** — same layout, hierarchy, colour semantics, radii, spacing rhythm, light+dark.
   A browser cannot reproduce Liquid Glass exactly; "closest faithful approximation" is the bar.
5. **Not portable** — Foundation Models on-device LLM (use the deterministic fallback the
   MVP docs already specify) and haptics (drop). Anything dropped is listed in
   `Web/Docs/PARITY-GAPS.md` with a reason. Nothing is dropped silently.

## Out of scope
Auth, multi-user, cloud sync, hosting, mobile browsers, PWA/offline, iPad layouts.

---

# RESOLUTIONS after Critic review (orchestrator, binding)

The Critic verified D1–D6 empirically. Verdicts: D1 approve-with-changes, D2 approve,
D3 approve-with-changes, D4 approve-with-changes, D5 approve, D6 approve-with-changes.
These amendments are now part of the contract.

## R1 — `computeUpdatedBalances` is lifted into Domain (authorised iOS change #3)

The New Month write path — the most stateful operation in the app, the thing that produces
EF 2,365 / Savings 7,095 — lives at
`Packages/Features/Dashboard/Sources/Dashboard/ViewModels/DashboardViewModel.swift:335-371`,
outside Domain. The server cannot import a Features package, so under D1 as written it
would have to be hand-ported: exactly the duplication D1 exists to prevent.

**Decision: move it into `Domain` as a new file and have `DashboardViewModel` delegate.**
This is not scope creep — `CLAUDE.md` mandates it ("Business Logic Lives in Domain Only …
other layers must delegate, not reimplement"). It is a pure move, so it is verifiable:

- The extracted Domain function must be behaviour-identical (a move, not a rewrite).
- `DashboardViewModel` keeps its method signature and delegates in one line.
- **Both must hold before this is considered done:** the existing
  `Packages/Features/Dashboard/Tests/DashboardTests/*` pass unchanged, and the full iOS app
  still builds. If either fails, revert and fall back to R1-fallback.
- **R1-fallback** (only if the move cannot be made safely): port it into the server *and*
  pin it with a checked-in golden-vector JSON asserted by both `DomainTests` and the server.

## R2 — The client performs **zero** numeric work of any kind

Stronger than D1. The three distinct rules (half-even money, truncated percentages,
`isBalanced`) are each easy to get wrong in JS, and every JS default is wrong for at least
one of them. So the server sends **pre-computed display values for everything numeric**,
including the truncated integer percentages for the expense breakdown and the emergency-fund
ring, and the `isBalanced` boolean.

The client never rounds, never divides, never sums. If a screen appears to need a number the
API does not provide, that is a missing field — Frontend asks Backend, and does not compute it.
This removes the Critic's risk #3 entirely rather than mitigating it.

## R3 — **AMENDED. The two totals are equal by construction; keep them equal.**

R3 originally said the Dashboard and Expenses-tab totals legitimately disagree, and told
implementers to *mirror the disagreement*. **That rationale was wrong** — the Critic
retracted its own risk #2 after finding the call site it had missed.

`MainTabView.swift:147` maps `expenses.filter { $0.isEnabled }.map { … amount: expense.monthlyAmount }`
— the **app layer filters and normalises before the Dashboard view model ever sees the
expenses**. So `DashboardViewModel.totalExpenses` and
`ExpensesViewModel.totalMonthlyExpenses` (`:272-276`) apply the same rule and are identical by
construction, not coincidence. Reading the view model in isolation is what made them look
divergent.

**Binding, replacing the original R3 in full:**

- There is **one** total: Σ`monthlyAmount` over **enabled** expenses. Both screens show it.
- **Ignore any earlier instruction to expose `dashboardTotalExpensesRaw` vs
  `expensesTabTotalMonthlyNormalised` as differing values, and ignore "reproduce that
  disagreement".** That was written on a retracted finding. If both field names survive in the
  contract to avoid churn, they must return the **same** value.
- The harness asserts it as an **equality invariant** (`invariant.equalFields`), which is
  stronger than asserting two independent literals.
- `PARITY-GAPS.md` must **not** log an inconsistency here. G1 is withdrawn.

Confirmed from source: `MainTabView.swift:147-155` hands the Dashboard **pre-filtered,
pre-normalised** expenses (`filter { isEnabled }`, `amount: monthlyAmount`); the Expenses tab
receives raw expenses and normalises itself. Both evaluate to the same sum.

### The real behaviour R3 was near

`ExpenseListView` is `.searchable`. `ExpensesViewModel.expenseGroups` filters by `searchText`
(`:292, :330`) but `totalMonthlyExpenses` does **not**. So **typing in the search box changes
the visible list and leaves the header total unchanged.** That is observable, shipped
behaviour and must be reproduced — see R14 gap 4. The natural implementation (recompute the
total from visible rows) is wrong twice over: wrong number, and client-side arithmetic.

## R4 — Localization: **FIVE** catalogs (corrected)

My original R4 said four. It was wrong — it omitted `Diameris/Resources/Localizable.xcstrings`,
the main app target's catalog, which owns the **entire Settings sheet**, `AccountEditorSheet`,
the three tab labels and the Insights placeholder. Building the union from four catalogs would
have shipped Settings with zero Romanian.

| Namespace | Package | Keys | RO |
|---|---|---|---|
| `app` | main target | 59 | 54 |
| `domain` | Core/Domain | 29 | 29 |
| `onboarding` | Features/Onboarding | 169 | 169 |
| `dashboard` | Features/Dashboard | 41 | 37 |
| `expenses` | Features/Expenses | 55 | 53 |
| **total** | | **353** | **342** |

Namespacing is **mandatory, not hygiene.** 39 keys appear in more than one catalog, and **3 have
identical English but different Romanian** — a flat union would silently pick one and lose a real
behavioural difference:
- `Other` → `app` "Altele" vs `domain`/`onboarding` "Altul"
- `For building wealth over time` → two different RO phrasings
- `Receives savings after emergency` → two different RO phrasings

Mechanism: enum labels (`AccountType.displayName` etc.) always resolve in `domain` regardless of
which screen displays them, because `displayName` is computed inside Domain. Route lookups the
same way or the RO text will be wrong on specific screens.

11 keys have no Romanian — including `Cancel` in `app`, where iOS falls back to a system
translation that **the web does not get for free and must translate explicitly**.

## R5 — API additions (amends D4)

- `POST/PUT/DELETE /api/categories[/:id]` — user-created categories are a real feature
  (`Persistence/Models/CustomCategory.swift`, the Expenses `…` overflow menu).
- Expense payloads carry `frequency`, `isEnabled`, `categoryId`, `linkedAccountId` — the
  Monthly|Annual control and the "n/m enabled" subtitle depend on them.
- `POST /api/new-month` is backed by the Domain function from R1, never by server-local maths.

## R6 — Categories — **WITHDRAWN. The premise was false.**

R6 originally claimed a Features-layer `ExpenseCategory` competed with Domain's
`Category.defaults`. **That is not true, and R6 should never have existed.**
`ExpenseCategory` is a **type alias for `Domain.Category`** — verified three ways by the Analyst:

- All three declarations are aliases (`Expenses/Sources/Expenses/Expenses.swift:5`,
  `Persistence/Models/CustomCategory.swift:6`, `DomainTests/CategoryTests.swift:6`), each
  `= Domain.Category`.
- No second `defaults` array exists anywhere; every reference resolves to Domain's.
- The category name literals (`"Auto/Transport"` …) appear in **zero** Features files — only in
  `Domain/Entities/Category.swift`.

The file I cited, `ExpenseCategoryCard.swift`, defines a SwiftUI *View* plus a `Color(hex:)`
helper and contains no category data. `ExpenseCategoryCard` vs `ExpenseCategory` was the mix-up.
My live-app observation (all 8 categories in Manage Categories) was correct; the explanation I
attached to it was not.

**There is exactly one category list: Domain's 8 defaults.** Seed from `DOMAIN-CONTRACT.md §6`.
`PARITY-GAPS.md` must **not** record a Domain-vs-Features divergence — it does not exist.

### The real divergence, which R6 was groping towards

**Code (8 categories) vs `Docs/MVP/04-Categories.md` (6).** Every UUID differs
(`D1A0000N-…` vs `00000000-…`), 3 icons differ, 4 colours differ, and the colours are *rotated*
between categories — the doc's Lifestyle pink is the code's Pets colour. Seeding the doc's
values would produce a plausible-but-wrong palette **and** break every stored `categoryId`.

**Binding: the code is canonical, the MVP doc is stale.** Side-by-side table with ⚠️ per row is
in `DOMAIN-CONTRACT.md §6`.

## R7 — Pin the formatting locale explicitly — ⚠️ **my instruction was wrong; corrected**

I told Backend to pin `Locale(identifier: "en_US_POSIX")` in the server's Money assembly.
**That would have broken every money string in the app.** Verified by running real Swift:

```
en_US       -> 9,000   | usesGrouping: true  | groupingSize: 3
en_US_POSIX -> 9000    | usesGrouping: false | groupingSize: 0
```

`en_US_POSIX` is the reflex choice for machine-stable formatting and it is **wrong here**: it
disables grouping outright, so `9,000 RON` would have silently become `9000 RON` on every
screen. Forcing `groupingSeparator = ","` does not help — with `usesGroupingSeparator: false`
there is nothing to separate.

**Correct pinning, which is what Backend actually implemented:**
- **Formatting** → `en_US` (`LocalePin.swift:38`). Grouping on at size 3, `.` as decimal
  separator. Everything needed, nothing extra.
- **Parsing** → `en_US_POSIX` (`DecimalString.swift:35`), where a fixed decimal separator and
  no grouping expectation *is* what you want.

Two things worth recording about how this was caught. **Backend did not blindly follow the
instruction** — it implemented the correct locale and documented the reasoning in
`LocalePin.swift:27-38`, including why the reflex is wrong. And the **Reviewer flagged it
independently** while closing OQ11. An implementer declining a wrong instruction from me, with
the reasoning written down at the site, is exactly what should happen.

Also noted there: `LC_ALL`/`LANG` do **not** move `Locale.current` on macOS (verified —
`LC_ALL=en_US_POSIX` leaves it as `en_US@rg=rozzzz`), so the pin has to be explicit in code.

`NumberFormatter` reads the process locale for grouping *size* and negative form; only the
separator is pinned in `AmountFormatter`. The reference screenshots were captured under an
English locale ("August 2026", `9,000 RON`, `-4,270 RON`). The server therefore pins its
formatter locale explicitly rather than inheriting the host's, so output is reproducible on
any laptop. Month names follow the selected UI language (EN/RO).

## R9 — Parity viewport, and dark mode must be asserted

Two gaps the Critic found in `PARITY-SPEC.md`: the word "dark" appears **zero** times in 98KB,
and responsive behaviour was deferred to nobody with no acceptance criterion.

**Viewport ruling** — the Critic proposed 390px (where the screenshots are), I had told Frontend
1280×900 (a laptop, which is what the user asked for). Both are right about different things, so:

- The app renders as a **centred column of 402px logical width** — the same column the iOS
  screenshots show — inside whatever window it's given.
- **Parity is measured at that 402px column, at ±2px.** That is the only width with an
  acceptance criterion, and it is where the reference images are comparable.

⚠️ **CORRECTED from 390px.** I ruled 390 (and the Critic proposed it) by asserting the
iPhone 17 Pro logical width from memory. Neither of us measured. iPhone 17 Pro is **402×874**.
The Critic settled it from the screenshots' aspect ratio — they are downscaled to 368×800, so
widths can't be read directly, but the ratio is decisive:

```
402/874 = 0.459954 → width at height 800 = 367.96 → 368  ✅ matches the reference images
390/844 = 0.462085 → 369.67 → 370  ❌
393/852 = 0.461268 → 369.01 → 369  ❌
```

**±2px grading at 390 would have mis-graded every screen by 12px** — i.e. the acceptance
criterion itself would have been the bug. Frontend's independently-chosen 402 in
`tokens.css:167` is correct and stays.
- Outside the column, the laptop window is **unconstrained** (background fill only). We are
  not designing a desktop multi-column layout; the deliverable is the mobile app, on a laptop.
- Reviewer screenshots at both 390×844 and 1280×900; only the former is graded on ±2px.

**Dark mode** — Analyst to add one explicit assertion to `PARITY-SPEC.md §0.3`: either
"dark mode is pure token substitution, no per-screen divergence" (if true) or an enumerated
list of the exceptions. A builder currently cannot tell, and D6 axis 4 requires both themes.
Note from the reference shot `13-dashboard-dark.jpg`: the dark background is near-**black**,
not dark grey.

## R10 — `BalanceReconciler` has an undocumented precondition. Guard it. (blocking)

The Critic found the most dangerous thing anyone has found so far, and it is *not* caught by
the 77 passing tests.

`computeUpdatedBalances` seeds from `data.reconciledBalances` using
`balances[id, default: 0]`. In the shipped iOS app that dict is **complete** only because
`NewMonthSheet.setupInitialValues()` (`:107-110`) seeds *every* account — while
`ReconcileAccountsStep` (`:30-36`) only lets the user *edit* emergency/savings/personal.
**The function's correctness precondition is supplied by a view, not by the function.**

So if the server builds its dict from the *editable* accounts only, every other account
(joint, personal, custom) silently resets to `0 + expenseTransfers` — **real balances wiped**,
with no test failing and no `isBalanced` warning, because `isBalanced` is computed earlier.

Binding requirements:
1. `BalanceReconciler.updatedBalances` must **state the precondition in its doc comment** and
   **defend it**: seed missing accounts from `accounts[].currentBalance` rather than trusting
   the caller, or take the full account set and derive the starting dict itself. Defending it
   inside Domain is strictly better than documenting it, because the server is a second caller
   and there will be a third.
2. `POST /api/new-month` must pass a **complete** balance dict covering every account.
3. Also unguarded and untested: `remainingDestination == .primarySavings` with **no**
   primary-savings account is an `if let` with no `else` (`TransferCalculator`-adjacent,
   `:353-355` pre-move) — the remaining money silently vanishes. Surface it rather than
   swallow it.

## R11 — Golden vectors are mandatory, captured **before** trusting the R1 move

My R1 verification confirmed: faithful move by inspection, iOS build green, 77 tests green,
and the tests are *not* vacuous (there is a dedicated `Suite "Compute Updated Balances"`).
The Critic correctly adds that this still is **not a behaviour-identity proof**, because:

- Half that suite's assertions are **inequalities** (`>= 15000`, `> 1000`, `>= 42000`). A
  refactor that *double-adds* an allocation passes all of them. Only three exact assertions
  exist in the entire suite.
- No test pins the published ground-truth vector (9000 / 4270 / 25% → EF 2,365, Savings 7,095) —
  the numbers the whole parity claim rests on.

So: `Web/Docs/golden-vectors.json` (Reviewer owns) is **required regardless of test status**,
and must include at minimum:
(a) the two-month ground-truth sequence to 2,365 / 7,095;
(b) an **incomplete** `reconciledBalances` dict — the R10 case;
(c) `.primarySavings` destination with no such account;
(d) emergency already at target, with overflow redirected to savings.

Asserted by both the Swift tests and the Playwright suite, with **exact** equality, never
inequalities.

## R12 — Icon and colour palettes are **served, never hardcoded**

Settled by counting source, after two agents disagreed:

| Grid | Screen | Count | Source |
|---|---|---|---|
| `IconPicker` | Add/Edit **Expense** | **37** | `AddExpenseSheet.swift:193-231` |
| category icons | **New Category** | **12** | `CategoryManagementView.swift:133-137` |
| category colours | **New Category** | **10** | `CategoryManagementView.swift:120-131` |

My `GROUND-TRUTH.md` said 18 for the expense grid; that was a miscount from a **clipped
screenshot**. The 18th source entry is `creditcard.fill` — the last symbol visible — which is
why the error looked self-consistent. The API contract inherited the 18 and is also wrong.

The two icon grids overlap on only **5** symbols, and `calendar` is in the *category* grid but
not the expense one — so a single shared array silently breaks whichever screen loses.

**Binding:** the server's `reference` payload serves **all three** lists —
`expenseIcons` (37), `categoryIcons` (12), `categoryColors` (10) — in source order. The client
hardcodes none of them and never infers a length from an image. Colours in order:
`#3B82F6 #8B5CF6 #F59E0B #10B981 #EC4899 #EF4444 #22C55E #06B6D4 #F97316 #6366F1`
(1–8 are the 8 default-category colours in the same order; 9–10 are picker-only; default
selection is swatch 1).

## R13 — Savings slider: serve a **precomputed position table** (unblocks R2)

The savings slider (onboarding step 6 **and** Settings) renders a live `25%` and
"That's **1,182 RON**/month" as the user drags. That needs `Int(pct*100)` and
`pct × availableIncome` **per frame** — forbidden by R2 — and a round-trip per frame is not
an option.

**Binding:** `GET /api/state` and `/api/onboarding/preview` return a table covering **every
selectable slider position**:

```
savingsSliderPositions: [
  { percentage: 0.25, percentDisplay: "25%",
    savings: { amount: "1182.5", display: "1,182 RON", editing: "1182,5" },
    isRecommended: true },
  …
]
```

Dragging becomes an array index lookup: zero client arithmetic, zero latency, one request.
The same table serves both screens. This is the pattern to reuse whenever a screen looks like
it needs live client-side maths — enumerate the outcomes server-side instead.

## R14 — Three more API additions

- **`isReconcilable: bool` on `Account`.** New Month step 2 shows cards only for
  `emergency | savings | personal` (`ReconcileAccountsStep.swift:30-36`); primary/joint/other
  are excluded. Without the flag the client must hardcode an account-type rule — business
  logic in the client, which D1 forbids even though it isn't arithmetic.
- **`wasLastMonthDisplay: "was 1,182 RON last month"`** on the same objects. String assembly
  belongs server-side alongside the existing `subtitle`/`progressChangeDisplay` fields.
- **Search semantics, documented (see R3).** Search filters `categories[].expenses` by name
  **client-side** (string matching is permitted — it is not arithmetic), while
  `totalMonthly` / `totalAnnual` and the "n/m enabled" counts stay **global and
  search-independent**. One line in the contract prevents the natural, wrong implementation.

## R15 — Amount parsing: local while typing, server on commit

`POST /api/parse-amount` per keystroke would feel awful. Parsing is **string manipulation, not
arithmetic**, so it does not violate R2.

**Binding:** the client parses locally for the live field (reproducing the iOS comma quirk),
and `/api/parse-amount` is retained as the **test oracle** — the Verify harness asserts the
local parser against it, so drift is caught without putting a network hop in the keystroke
path.

## R16 — Developer Tools: tooling, not a ported screen

The `DevDebugView` **and its toolbar entry point are both inside `#if DEBUG`**, so a shipping
user cannot reach it, and none of its 20+ strings are localized — evidence it was never
product surface. It therefore fails the "the app the user actually sees" standard.

**Binding:** do not port it as a screen, and do **not** list it in `PARITY-GAPS.md` (a gap
implies shipped behaviour we chose not to match; this is non-shipped). Do implement two of its
actions as **dev-only tooling** because the harness needs them: deterministic **reset** and
deterministic **seed** (`expenses_import.json` is already a usable fixture).

## R17 — Two nondeterminism traps to fix rather than inherit

- **Custom category order.** `allCategories` uses `sorted { $0.sortOrder < $1.sortOrder }`;
  Swift's `sorted` is **not** guaranteed stable and all custom categories share
  `sortOrder = 100`, so two customs are formally unordered. The web must tie-break on
  `createdAt`, then `name`. (Same class of bug as the `Dictionary(grouping:)` ordering in D1.)
- **`currentMonthDisplay` uses the server's clock and locale.** Fine for a local app, but the
  Verify harness must **pin a date** or it will flake at month boundaries.

Also noted: there is a second Xcode target, `ro.svc.Diameris-QA` at `MARKETING_VERSION = 1.0`,
with a separate data store. The reference screenshots are from the main target (Version 0.1,
Build 1). A future screenshot showing 1.0 came from QA and is not comparable.

## R18 — The inline-computed-display pattern, and the closed set of API gaps

A **systematic sweep** (Critic, task 16) grepped every non-test View/ViewModel in
`Packages/Features`, `Packages/Core/SharedUI` and `Diameris/` for arithmetic
(`Int(`, `*`, `/`, `min`, `max`, `reduce`, `NSDecimalNumber`) minus layout noise — ~50 sites,
triaged. This replaces the earlier opportunistic gap-finding and should be treated as a
**closed set**, not a starting point.

**Single root cause for all of it:** *iOS computes a display value inline from two stored
values, and the contract ships only the stored values.* Every fix has the same shape —
**enumerate the resolved outcomes server-side.** R13's slider table was the first instance;
the same pattern serves three more screens.

### Blocking (cannot be built at all under R2)

1. **Split allocation mode — an entire mode is unservable.** `SavingsScreen.swift:164, 171,
   210, 217` renders, per side, `Int(splitEmergencyPercentage * 100)%` **and**
   `availableIncome × percentage` as money. The contract stores the split *settings* but
   returns **no resolved per-side amounts**. Needs:
   `{ emergency: {percentDisplay, amount}, savings: {percentDisplay, amount},
   requestedTotal, scaleRatio, wasScaledDown }`. `scaleRatio` is load-bearing —
   `TransferCalculator.swift:161-163` proportionally reduces both sides when the requested
   total exceeds available income, and the screen shows the reduced figures.
   ⚠️ This stayed invisible because `GROUND-TRUTH.md` only ever walked **Priority** mode.
   Split is fully implemented in Domain and specced, and is absent from the MVP docs, so
   there is no document to fall back on.
2. **`emergencyTargetUncapped` + `isCapActive` on `Account`.** When the hard cap bites,
   `EmergencyMultiplierPicker.swift:91-100` renders the **uncapped** target struck through
   beside the capped one. `AccountEntry.emergencyTarget` already applies `min(…)`, so only the
   effective value exists — drawing the strikethrough would require `income × multiplier`.
3. **`emergencyMultiplierOptions`** — 4 discrete options (`:15` = `[3,4,5,6]`) with
   `"\(Int(option))×"` labels and per-option captions **"Minimum recommended" / "Standard
   protection" / "Enhanced protection" / "Maximum security"** (`:191-197`), each with its own
   resolved target so tapping 3×→6× updates live pre-save. The current
   `emergencyMultiplierRange: [3, 6]` cannot produce any of it; Frontend would invent captions.
4. **`savingsSliderPositions`** (R13) **plus the missing `step` constant** —
   `SavingsSlider.swift:184-186` steps by a fixed increment that `reference.savingsConstants`
   does not ship. The table cannot even be authored without it.

### Required, non-blocking

5. **`categoryIcons` (12) / `categoryColors` (10)** — distinct from `expenseIcons` (**37**, per R12).
6. **`isReconcilable` on `Account`** + `wasLastMonthDisplay` (R14).
7. **Search semantics** — `totalMonthly`/`totalAnnual` and the enabled counts are
   search-independent (R3/R14).
8. **`AccountEditorSheet`'s Current Balance field does not use `AmountFormatter`.**
   `SettingsSheet.swift:55` is `TextField("0", value:, format: .number)` — locale grouping
   applies and the "empty when zero" behaviour does not. So `editing` is **not universal**;
   serve a distinct value for this field or log the divergence. Do not let the client assume.
9. **`accountSuggestions`** — the 3 chips (`AddAccountSheet.swift:61-69`) are raw English
   literals with **no `.localized`**, so they render English in Romanian. Serve as data.
   ⚠️ The chip labelled **"Emergency" creates a `.savings` account** (discrepancy #16).
   Serving it as data reproduces the bug faithfully and makes it trivially flippable later.
   Log the unlocalized chips in `PARITY-GAPS.md` — a faithful port leaves them English in RO,
   which will otherwise look like our bug.

### Explicitly NOT R2 violations — do not over-correct

- `OnboardingProgressIndicator.swift:19`, `OnboardingViewModel.swift:155` — step fractions from
  a step index. **Client-owned navigation state, not business data.** R2 governs money and
  derived business values; reading it wider would force a round-trip per onboarding step.
- `ExpenseCategoryCard.swift:145-147` — hex→RGB conversion. Presentation.
- `SettingsSheet.swift:50-54` — recomputes totals already served by `dashboard.summary`; the
  web just reads the served values.
- ~~`AddExpenseSheet.swift:34` — `amount × 12` live annualized preview on an unsaved draft.
  **Ruling: allow this one client-side multiply.**~~
  ⚠️ **EXCEPTION WITHDRAWN. My ruling was wrong twice over, and the second error makes it
  impossible to implement.**

  **First**, the direction: it is **÷ 12**, not × 12 — the row shows the *monthly equivalent of an
  annual amount*. Following my wording literally would have been **144× wrong**.

  **Second, and fatal:** iOS does not divide at all. It **multiplies by
  `Frequency.annual.monthlyMultiplier` = `Decimal(1)/12`, a 28-significant-digit constant**. So:

  ```
  iOS:  1266 × 0.08333333333333333333333333333  = 105.4999…  → "105 RON"
  JS:   1266 / 12                               = 105.5      → "106 RON"   ✗
  ```

  **The disagreement is in the operand, not the rounding.** No amount of care in `money.ts` — no
  half-even implementation, no Decimal library short of reproducing the exact 28-digit constant —
  recovers it. A client-side computation here is not "slightly riskier"; it is **wrong**, and
  wrong in a way that only shows up on the small set of amounts where the truncated constant and
  true division straddle a `.5` boundary.

  **Correct resolution, which Frontend2 adopted instead of taking my exception:** hold the row
  unrendered and request `POST /api/expenses/preview` from Backend. Verified in the browser after
  it shipped: a 1,266 annual expense renders **`105 RON`**.

  **The lesson is about R2 itself.** I granted this exception on the reasoning that a keystroke
  round-trip was worse than one trivial multiply, and that R2 exists to protect *persisted,
  compounding* values. Both premises were plausible and the conclusion was still unimplementable.
  **R2 has no safe exceptions for money arithmetic** — not because the rule is sacred, but because
  the shared-Domain architecture is the only thing that reproduces Apple's `Decimal` semantics, and
  "just this once" cannot. Frontend2 declining an exception its orchestrator had explicitly
  granted is the single best judgement call made on this project.
- `SettingsSheet.swift:218` — `Int(min(100, pct * boost * 100))` clamps at 100 **after**
  multiplying where Domain's `effectivePercentage` clamps at 1.0 **before**. Numerically
  identical, but it is a second implementation: serve `boostedPercentDisplay`.

## R19 — Dark mode is pure token substitution (closes R9's dark-mode item)

Verified by exhaustive grep: the codebase contains **zero** occurrences of
`@Environment(\.colorScheme)`, `colorScheme` or `preferredColorScheme`. **No view branches on
appearance** — no dark-specific layout, string, icon, spacing or component anywhere. Dark is
produced entirely by adaptive brand + semantic colours.

So: one component set, swap tokens under `@media (prefers-color-scheme: dark)`. Confirmed
dark backgrounds are pure **`#000000`**, not dark grey:

| Screens | Light | Dark |
|---|---|---|
| Dashboard, Expenses, all 7 onboarding, all 3 New Month steps (`ScrollView`) | `#FFFFFF` | `#000000` |
| Settings, AccountEditor, AddExpense, AddCategory (`Form`/`List`) | `#F2F2F7` | `#000000` |
| — their grouped rows | `#FFFFFF` | `#1C1C1E` |

Only *grouped rows* lift to `#1C1C1E`. Five elements are intentionally non-adaptive and stay
fixed: selected-state `.white` on coloured fills, the slider thumb, the 8 category hexes, the
10 picker swatches. Note the slider thumb's `black.opacity(0.15)` shadow is the app's **only**
shadow and is effectively invisible on black — reproduce as-is, do not substitute a light one.

## R20 — Truncated percent is for **labels only**. Geometry uses the full double. (blocking)

The best "looks right, isn't" catch of the project. We fought hard to make percentages
**truncate** (R2, verified live). That truncation then leaked into the *geometry*:
`ProgressRing`/`ProgressBar` were driving the arc and bar width from the truncated integer
(`ui.css:223`, `calc(1% * var(--percent))`).

iOS draws the arc from the full `Double` (`AccountEntry.emergencyProgress` →
`0.04379629629629629`), and truncates **only** for the text label. Measured at the graded
402px column (bar ≈ 354px, ring circumference ≈ 181px):

| True | Renders | Bar error | Ring error |
|---|---|---|---|
| 4.380% | `4%` | 1.34px | 0.69px |
| **8.759%** | `8%` | **2.69px** | 1.79px |
| 8.990% | `8%` | **3.50px** | — |
| 58.990% | `58%` | **3.50px** | — |

**The 8.759% case is the GROUND-TRUTH month-2 emergency fund** — so the single most-asserted
scenario in the project would have been graded a ±2px layout failure, and whoever investigated
would have gone hunting in CSS for a cause that was a wrong server field.

**Binding:**
- **Labels** use the server's truncated integer (`emergencyProgressPercent`, `percent`).
- **Geometry** uses the server's full double (`emergencyProgress`, `progressBefore`,
  `progressAfter`) — already shipped in the API, so this costs nothing and adds no arithmetic:
  `pathLength={1}` with `strokeDasharray="{progress} 1"`, and `calc(100% * var(--progress))`.
- Two different server fields for two different jobs. Neither is derived from the other
  client-side.

## R21 — R2's mechanical guard must catch arithmetic, not just formatters

`noClientMaths.test.ts` was the right instinct and is well built, but its pattern list matches
**formatters**, not arithmetic. These all pass clean today: `total.amount * 0.25`, `Number(`,
`parseInt(`, unary `+`, `.reduce((a,b) => a+b)`.

Add at minimum `/\bNumber\s*\(/`, `/\bparseInt\s*\(/`, and a narrow `/\.amount\s*[*/+-]/` —
the last catches the realistic failure directly, since **every money value arrives as
`.amount`**. A guard that misses the likeliest breach is worse than none, because it is trusted.

## R22 — One source for the category palette

Three copies of the 10 category colours now exist: `reference.categoryColors` (R12's single
source), `tokens.css --cat-*`, and `Gallery.tsx` fixtures. The gallery is route-gated dev-only
and fine, but must carry a comment so nobody copies screen code out of it.

**Binding:** swatches render from the API response. Either drop the `--cat-*` tokens or add a
test asserting they equal `reference.categoryColors`. R12's drift-proofing is worthless with a
second copy outside it.

## R23 — Three behavioural answers, from source (closes Reviewer gaps 5, 7, 9)

**Remaining Money default = `.primarySavings`, and it IS preselected.**
`OnboardingViewModel.swift:29`. The picker has no default of its own. In the normal path it is
inserted at **index 0**, so it is the first card and already highlighted (accentSecondary fill,
white text, trailing checkmark). My tap during the walkthrough was a no-op reselecting the
current value — so `08-dashboard.jpg` reflects the *default*, not my choice.

⚠️ **Upstream bug found behind it.** If the user skipped the savings-account prompt,
`.primarySavings` is not in `availableDestinations` yet remains the selected value, so **no
card renders selected**. At save (`:215-230`) the switch credits no account, and primary was
already *assigned* `remainsInPrimary` — so `remainingMoney` is credited to **nothing and
vanishes**. The screen displays money the database will not contain. **Reproduce it; log in
`PARITY-GAPS.md`.** Same family as the `.primarySavings`-with-no-account hole in R18.

**`Emergency␣␣• 3× income` is NOT a double space — it is layout.**
`SettingsSheet.swift:373-388` is an `HStack(spacing: Spacing.xs)` — an **8pt gap** — with 2–3
independent `Text` views, each its own colour: `"Emergency"` (secondary), optionally
`"• Primary"` (accentPrimary), optionally `"• 3× income"` (accentSecondary). Every string has
single spaces (`:433-436`).
**Binding: the web emits 2–3 inline elements with an 8px gap and per-element colour — not one
concatenated string.** The server must **not** emit a double-spaced `subtitle`; it currently
does, which is my own error propagating from a flattened accessibility label. Don't "fix" it to
a single space either — it was never one string.

**"Skip for now" — the two buttons do DIFFERENT things.** Both `advance()` exactly one step;
neither jumps to the summary.
- **Expenses skip** zeroes all 4 amounts (rows kept in memory with name/icon/category). At
  save, `where expense.amount > 0` means **zero `Expense` rows persist** → `totalExpenses = 0`,
  `availableIncome == income`.
- **Savings skip does NOT zero savings.** It assigns a fresh `SavingsAllocationEntry()`, i.e.
  resets to **25% prioritized/percentage, boost off**, and a row **is** persisted.
  **Skipping the savings screen still saves 25%.**

The asymmetry is the point: one zeroes its data, the other restores a non-zero default. Both
mean "discard my edits"; neither means "opt out".

## R24 — Make the wrong value unrepresentable, not documented (blocking)

The fourth leak in the R20 family, with a worse failure mode. `Money` carries three forms of one
quantity — `amount` (payload), `display` (labels), `editing` (inputs) — and `.display` /
`.editing` are both `string` on the same object, one identifier apart.

Run against the real parser:

```
parseUserInput("9,000 RON")  = 9.000    ← nine thousand becomes nine
parseUserInput("1,182 RON")  = 1.182
parseUserInput("27,000 RON") = 27.000
parseUserInput("1182.5")     = 1182.5   ← correct: this is `editing`
```

**1000× silent data loss.** No exception, no validation error. Under this machine's Romanian
regional formats `"9.000"` even *reads* as nine thousand to a reviewer, so it survives review
and surfaces only after it has been persisted.

**Binding:** brand `display` and `editing` as distinct types (`money.ts` already brands
`Money`), so `AmountField.value: EditingString` **rejects a display string at compile time**.

The general principle, which now applies beyond this instance: where a mistake is
type-expressible, **a doc comment is not a control.** Two implementers share `src/ui/`, and
"seed this from `editing`" is exactly the note that gets skimmed. Close the family, not the case.

## R25 — Confusable-pairs register

Four leaks of one shape have now been found: **a correct value used in the wrong place.** So
rather than wait for the fifth, every quantity with more than one server representation is
enumerated. The last column is the important one — a trap invisible in the ground-truth data
ships green.

| # | Quantity | Forms | Leak symptom | Caught by GT data? |
|---|---|---|---|---|
| 1 | money | `amount` / `display` / `editing` | `display`→input, 1000× loss | ❌ |
| 2 | progress | `progress` / `progressPercent` / `progressDisplay` | R20, 3.50px | ✅ fixed |
| 3 | **expense amount** | `amount` / `monthlyAmount` / `annualAmount` | **12× on annual expenses** | ❌ all four seeds are monthly |
| 4 | emergency target | capped / uncapped | strikethrough missing | ❌ GT has no hard cap |
| 5 | allocation order | Domain priority / server-sorted | emergency & savings swap | ⚠️ |
| 6 | `linkedAccountId: null` | null means **primary**, not "none" | blank or "Unknown" for Main Account | ✅ |
| 7 | destination label | "Keep in Primary" / "Primary Account" | wrong string on one screen | ✅ |
| 8 | **transfer-plan rows** | one account can legitimately appear **twice** | rows collapse, remaining money vanishes from the display | ❌ Priority-mode GT has Emergency and Savings as distinct rows |

**Row 8, found by walking Split at target (`24-split-at-target-transferplan.jpg`):** when the
emergency fund is full its share overflows to savings, producing **two rows both named
"Savings"** — `+1,182 RON` and `+3,548 RON` — distinguished only by the second's
`remaining money` subtitle. A client keying rows by account id or name **collapses them and
silently drops 3,548 RON from the display.** Render the plan as an **ordered list**, never a map
keyed by account. Emergency Fund is **absent** from the list entirely, not present with a zero.

### R25b — Settings' split "Total Monthly" is the *requested* total

Also from that walk: at-target, Settings still shows `473 RON` (Emergency 10% alone) and
`1,182 RON` (both sides) — identical to the not-at-target case. It is purely `splitTotal` and
does **not** reflect the fund being full. The overflow redirect happens at **transfer-plan**
time. Two different numbers for two different screens; don't unify them.

**Row 3 is binding now:** `expense.amount` is **never displayed** in iOS. `ExpenseItemRow.swift:31`
renders `displayFrequency == .monthly ? monthlyAmount : annualAmount`, and
`ExpenseCategoryCard.swift:34` does the same for group totals. `amount` exists **solely to seed
the edit field**. Because every seed expense is monthly, rendering `amount` passes the entire
ground-truth suite and is 12× wrong for any annual expense.

**R25a — the fixtures must be extended or four of these seven are untestable by construction.**
`golden-vectors.json` needs **an annual expense** and **a hard-capped emergency fund**. Without
them rows 1, 3 and 4 cannot fail a test no matter how wrong the client is.

## R26 — G2 ruling: **mirror the defect. Do not show the warning.** (settles a real conflict)

Backend added `unallocatedRemainingMoney` to `/api/new-month/preview` and instructed Frontend to
show a warning in place of "All amounts add up correctly". That is the **opposite** of the OQ8
ruling behind G2, `S17` and `S21`. Frontend typed the field but did not wire it; the Reviewer
marked G2 contested and left both vectors as written. **Both held the right position and
escalated instead of guessing — that is exactly the behaviour I want.**

**Ruling: mirror iOS.** The money vanishes, `isBalanced` continues to report `true`, and the
banner keeps saying "All amounts add up correctly". `S17`/`S21` stay as written; do not flip them.

Reasoning, in order of weight:

1. **The brief is 1:1 with the mobile app.** A warning iOS does not show is a behavioural
   divergence under D6 axis 3 — the web would be *better*, which is still not *the same*.
2. **"Deliberately better than the app we're porting" is a product decision, not an engineering
   one**, and the user is unavailable. Choosing 1:1 is the reversible default; shipping an
   unrequested improvement silently is not.
3. **The blast radius is near zero.** The path is unreachable in the default flow (it requires
   skipping the savings-account prompt), so mirroring costs almost nothing in practice.
4. `S17`'s inverse assertion already fires if the parts ever reconcile — so a future accidental
   "fix" is caught. That protection only works if we don't deliberately break it now.

**`unallocatedRemainingMoney` is not wasted — it is quarantined.** Keep serving it, but it must
**not** drive any user-facing UI. It may surface only in the **dev-tools** surface, which R16
already established is not shipped parity surface. That keeps the diagnostic, keeps parity, and
leaves a one-line hook if the user later wants the real fix.

**Flag for the user's review** (they asked for 1:1 and are unavailable): iOS can silently lose
the remaining money when `.primarySavings` is selected without such an account existing. We
reproduce it. Say the word and it becomes a warning — the field and the vectors are already in
place, so flipping it is a small change, deliberately.

### R26a — the general rule this establishes

Where iOS has a defect, **we reproduce it and log it. We never silently improve it.** An
improvement is a product change and needs the user. Every mirrored defect must additionally
carry a test that **fails if the values ever come out correct**, so nobody can "fix" it by
accident — the Reviewer's `expectedToFail` + inverse-assertion pair is the required pattern.

## R27 — Assorted rulings

**`subtitleParts` — approved, and Backend must serve it.** A flat `"Emergency  • 3× income"`
reproduces the text but not the per-part colours or the 8px gap, and splitting on `"•"`
client-side would be presentation logic guessing at server data. Serve
`subtitleParts: [{text, tone}]` where `tone` ∈ secondary / accentPrimary / accentSecondary.
Frontend is right not to parse it; the Settings account rows stay a known visual gap until then.

**API gate warns by default — approved.** The Reviewer made `globalSetup` print the outstanding
count plus a "these may be missing API fields, not UI bugs" banner rather than aborting, with
`PARITY_STRICT_API=1` for CI. Correct call: a hard block gives Frontend zero UI signal while the
API is incomplete, and the two failure modes are independent. The banner prevents the
misdiagnosis, which was the actual goal.

**`gen-locales.py --check` is a required step, not optional.** `i18n.ts`'s
`requested-ns → app → key` chain is safe *only because* the orphaned duplicates are dropped at
generation time — the safety lives in the generator, not the lookup. A hand-edit reintroducing
`app.Other` reopens the hole silently and renders "Altele" for "Altul" **in Romanian only, on a
screen that looks perfect in English**. The `--check` gate is what makes that impossible.

**Row 5 of R25 — resolved, three ways:**
- *Safe:* allocation array order is deterministic in both modes (`distributeToAccounts` appends
  emergency then savings unconditionally). ⚠️ dropped.
- *Unspecifiable:* the account **list** order. `MainTabView.swift:13` declares
  `@Query private var accounts: [Account]` with **no sort descriptor**, so Dashboard cards render
  in unspecified store order — while `SettingsSheet.swift:349` sorts by `sortOrder`. **iOS is
  inconsistent with itself.** The server sorts by `(sortOrder, createdAt)`.
- *Upstream bug:* `isPrimarySavings` is **not enforced unique** (`SettingsSheet.swift:605` sets
  it without clearing others, unlike `isPrimary`), and `accounts.first(where:)` runs over the
  unsorted array — so with two flagged accounts iOS credits a **nondeterministic** one between
  launches.

Consequent actions, all binding:
1. **Golden vectors must never contain two `isPrimarySavings` accounts.** iOS has no defined
   answer, so an assertion would encode one arbitrary run — the fixture would certify a coin flip.
2. **Dashboard screenshot grading uses one account per type**, so it can't flake on iOS's ordering.
3. `PARITY-GAPS`: the web is **deliberately more deterministic than iOS** here — a divergence,
   not a defect — plus the iOS Dashboard-vs-Settings inconsistency as an upstream bug.

### R27a — which instrument answers which question

Codifying the Critic's boundary, because routing questions wrongly wastes the most time:
- Reachable from `Packages/Core/Domain` or `Utilities` — formatter edge cases, rounding,
  allocation maths (`AmountFormatter`, `TransferCalculator`, `AccountEntry`,
  `SavingsAllocationEntry`, `BalanceReconciler`) → **the Critic's real-Swift probe.** Authoritative.
- Computed in a **View** (`Int(progress*100)`, the `.number`-formatted balance field), or
  anything about SwiftData ordering → **the simulator**, i.e. the orchestrator.

Ask the right one; don't queue behind the orchestrator for a question a probe answers better.

## R28 — First-screen defects and one ruling contradiction

**R28a — `-0 RON` is a real, reachable bug. Fix it.**
`DashboardScreen.tsx:74` prefixes a minus unconditionally. iOS
(`SummaryCard.swift:96-99`) is `style == .negative && amount > 0 ? "-" : ""`, so at zero
expenses iOS renders **`0 RON`** and the web renders **`-0 RON`**.

Reachable on the **first dashboard a new user sees**: R23's "Skip for now" on the onboarding
expenses screen persists *zero* `Expense` rows, so `totalExpenses = 0`. Disabling all expenses
also reaches it. Fix with `money.ts`'s existing `isZero()` — a pure string test, so R2 is intact.

Note this is *not* the same as R24's `-0`: there, iOS **does** emit `-0` for `-0.4`, and we
reproduce it. Here iOS emits `0` and we must too. **Same glyph, opposite rulings** — which is
itself an R25-family hazard, so both cases are now pinned by vectors.

**R28b — `Search expenses` reads the wrong namespace.**
`MainShell.tsx:100` calls `t('Search expenses')` bound to **`app`**, but the string exists only
in the `expenses` catalog (`"Caută cheltuieli"`). The `→ app` fallback cannot rescue it because
`app` *is* what was requested, so Romanian renders the **English** placeholder. iOS puts this on
`ExpenseListView`, so `expenses` is correct. Exactly the failure class R4 was hardened against:
invisible in English, wrong only in Romanian, on a screen that looks perfect.

**R28c — R16 contradiction resolved: gate the Dev Tools button, do not enumerate it.**
`MainShell.tsx:82-90` renders the `hammer.fill` toolbar button unconditionally, logged as an
enumerated deviation. That contradicts R16, which ruled the Dev Tools surface is **not shipped
parity surface** precisely because both the view *and its entry point* are `#if DEBUG` — a
shipping user cannot reach it. An always-visible button is the opposite.

**Ruling: gate it behind `import.meta.env.DEV` (or the existing `?dev=` pattern the client
already uses for the gallery).** It is not a deviation to record; it is a deviation to remove.
The Analyst was right to flag its own ruling being contradicted rather than let the comment stand.

**R28d — register row 9: the two implementers diverged on server enum labels.**
Server enum `displayName`s are **always English by design** (`Bundle.module` falls back to the
key on macOS), so Romanian must come from the client dictionary via `tDomain`.

Frontend2 built `tDomain` and applies it consistently. Frontend renders `f.displayName` **raw**
(`ExpensesScreen.tsx:78`, `:100`) — while correctly using `t()` for its own literals, so this is
not i18n negligence: the two label sources look identical at the call site.

**Structural cause, and the actual fix:** `tDomain` lives inside Frontend2's feature folder, so
Frontend had no way to know it existed. **Promote it to a shared export in `src/lib/i18n.ts`.**
Fixing only the two call sites leaves the next implementer to repeat it.

Scope: every `reference` enum — `accountTypes`, `allocationModes`, `savingsInputModes`,
`remainingMoneyDestinations` — anywhere they are rendered on Dashboard, Settings or New Month.

### ⚠️ R28d CORRECTED — the header is **fully English**, and 2 of 6 enums must stay raw

My original R28d said the header renders the mixed string "Total **Lunar** Expenses" and that
all served `displayName`s need `tDomain`. **Both halves were wrong.** The Critic's original
finding was one inference short; the Analyst traced both halves and I verified the catalogs
directly.

**The header renders "Total Monthly Expenses" in Romanian — fully English. Two stacked lookup
failures:**

1. **The wrapper never resolves.** `"Total \(x) Expenses".localized` interpolates *first*, so
   `.localized` receives a plain `String` and the whole thing becomes the runtime key
   `"Total Monthly Expenses"`. Xcode's *static* extractor wrote **`"Total %@ Expenses"`** into
   the catalog instead — with a perfectly good `ro` value, `"Cheltuieli %@ totale"`. Runtime key
   ≠ catalog key, so **that translation is dead.** Same orphan family as `app.Other = "Altele"`.
   Verified: `Total %@ Expenses` is present in the *Expenses* catalog, absent from Domain's.
2. **The inner word never resolves either — this is what kills "Lunar".**
   `Frequency.displayName` is *Domain* code, and `Domain`'s `.localized` binds
   `bundle: .module` (`Domain/Utils/Localization.swift`). **`Monthly` and `Annual` are ABSENT
   from the Domain catalog** — verified — and also absent from the app target's. The
   `Monthly → "Lunar"` entry lives in the **`expenses`** catalog, which `displayName` never
   reads. So `displayName` returns its own key: `"Monthly"`, in both languages.

**Therefore `ExpensesScreen.tsx:100` rendering `f.displayName` raw was ALREADY CORRECT**, and
"fixing" it to Lunar/Anual would have broken parity — the exact forbidden improvement R26a bans.
The Monthly|Annual segmented control shows **English** on iOS too.

⚠️ But the `(Anual)` row caption **is** correctly Romanian, because it binds the *Expenses*
bundle (`ExpenseItemRow.swift:60`). So iOS ships a screen where the segment reads **Annual**
while the row caption reads **(Anual)**. Reproduce that inconsistency.

### The matrix — which served `displayName`s to translate

| Enum | Domain RO coverage | iOS in RO | Web must |
|---|---|---|---|
| `AccountType` | 6/6 | Romanian | ✅ `tDomain` |
| `AllocationMode` | 2/2 | Romanian | ✅ `tDomain` |
| `SavingsInputMode` | 2/2 | Romanian | ✅ `tDomain` |
| `RemainingMoneyDestination` | 3/3 | Romanian | ✅ `tDomain` |
| **`Frequency`** | **0/2** | **English** | ⛔ **render raw** |
| **`Currency`** | **0/3** | **English** | ⛔ **render raw** |

`Currency.displayName` has **no `.localized` at all** (`Utilities/Currency.swift:19-25`) — bare
literals, English by construction on every platform.

### R28e — structural: SwiftPM never compiles `.xcstrings`, so the server cannot serve Romanian

Found while chasing the above, and it reframes the whole class. `Domain_Domain.bundle` ships the
**raw `Localizable.xcstrings`** — no `.lproj`, no compiled `.strings` — because compiling
xcstrings is an Xcode step (`xcstringstool`) that plain SwiftPM does not run. Verified three
ways: bundle contents; a probe executable returning `AccountType.other.displayName == "Other"`
even under `-AppleLanguages '(ro)'`; and live `/api/state` returning `"Emergency"`, `"Priority"`,
`"Primary Savings"`.

**This is not a bug and does not break parity, but it changes what those fields mean:** every
`*DisplayName` the server sends is an **English lookup key**, not display text. So client-side
`tDomain` is **mandatory** for the four translatable enums — not tidying — and **pointless** for
the two iOS leaves English.

## R29 — Verify gets its own port and store. Browser verification is racy today. (blocking)

Frontend reported that the harness's `POST /api/reset` + `/onboarding/complete` wiped its writes
twice mid-session and flipped the app between onboarded and not while it was driving a browser.
I confirmed the cause: **there is no isolation to be had.** `Configure.swift:9` hardcodes
`port = 8080` and `JSONStore.swift:29-30` hardcodes `~/.diameris/web-store.json`. One port, one
store, three consumers (Frontend driving, Frontend2 driving, Reviewer resetting).

This invalidates results in **both** directions: the Reviewer's failures may be Frontend's
in-flight edits, and Frontend's observations may be the Reviewer's resets. Neither can trust a
browser run — and my own gate resets the store too, so I am a third offender.

**Binding, assigned to Backend:**
- Honour `DIAMERIS_PORT` (default 8080) and `DIAMERIS_STORE` (default `~/.diameris/web-store.json`).
- The Reviewer runs its own instance — `DIAMERIS_PORT=8081`,
  `DIAMERIS_STORE=<tmp>/verify-store.json` — and points Playwright at it.
- `Web/run.sh` keeps today's defaults so manual driving is unchanged.
- The propagation gate takes a `--base-url` so it can target either.

Until it lands, **any browser-driven result is provisional** and should say so. This is an
orchestration failure of mine: I asked three agents to drive the same mutable singleton and then
treated their contradictory observations as signal.

### ✅ R29 implemented — and it exposed a SECOND coordination problem, also mine

`Configure.swift:18,24` now read `DIAMERIS_PORT` and `DIAMERIS_STORE`, and
`Web/verify-server.sh` starts an isolated instance (port 8081, temp store). Verified: env
overrides present, `run.sh` defaults unchanged, gate accepts `--base-url`.

**But while testing it I killed every agent's server.** I ran `pkill -f DiamerisServer`, which
matches *all* instances — mine, Backend's, and the Reviewer's on 8081. My 8081 probe then failed
with `Address already in use` because the Reviewer already owned that port. So the port/store fix
solved the **data** race and left a **process** race untouched.

### R29a — server process ownership (binding on everyone)

| Port | Owner | Start with |
|---|---|---|
| **8080** | shared, for implementers driving browsers | `Web/run.sh` |
| **8081** | **Reviewer only** | `Web/verify-server.sh` |

- **Never run `pkill -f DiamerisServer`.** It kills every agent's instance. Kill by **pid** on
  your own port: `lsof -ti:8081 | xargs kill`.
- **Check before starting:** if `curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:<port>/api/state`
  returns 200, an instance is already serving — do not start a second. Two processes on one port
  produce intermittent `bind: Address already in use` and a server that appears to flap.
- **Nobody but the Reviewer resets 8081**; nobody but its owner resets 8080 mid-session. My own
  propagation gate resets 8080, so run it against `--base-url` when someone is driving.

The general lesson, and it is the same shape as R29 itself: **a shared mutable resource with no
declared owner will be corrupted by well-behaved agents.** Ports and processes needed ownership
just as much as the store did.

## R30 — The completion strings: same flag, two screens, two behaviours (pre-warning)

`allocation.isComplete` drives **different strings with different structures** in two places, and
**neither is served**. Both are already in `en.json`/`ro.json` — extracted, unrendered, which is
the signature of an orphan waiting to happen.

| Screen | Source | String | Structure | Catalog |
|---|---|---|---|---|
| **New Month** | `TransferPlanStep.swift:188-192` | `"Completes fund to 100%!"` | **replaces** `progressChangeDisplay` | `dashboard` → "Completează fondul la 100%!" |
| **Onboarding** | `TransferPlanScreen.swift:375-386` | `"Target reached!"` | **appends** a green ✓ row below `progressDisplay` | `onboarding` → "Țintă atinsă!" |

⚠️ **A client that implements "if `isComplete`, show the completion string" uniformly is wrong on
one of the two screens** — different wording *and* replace-vs-append. The conditions differ too:
New Month additionally requires `accountType == .emergency`; onboarding does not. So a completed
**savings** target shows "Target reached!" in onboarding and **nothing** in New Month.

`isComplete` is served, so the client branches — it just branches **differently per screen**.

### R30a — the asymmetric `!isBalanced` pair, where one side is silent

When `!isBalanced`: **New Month renders absolutely nothing** — the badge is `if isBalanced` with
no warning variant (`TransferPlanStep.swift:333-349`) — while **onboarding renders an orange
`exclamationmark.triangle.fill`** and drops "All accounted for!".

**Do not "improve" New Month by borrowing onboarding's warning.** That is the tempting direction
and it is a silent divergence (R26a).

Four rows of the narrow-state matrix (`PARITY-SPEC.md §7.3`, 9 rows) are **negative space** —
the correct output is *nothing*. A screenshot suite cannot assert that by looking; they need
explicit **absence** assertions.

## R31 — Two attachments to existing tickets

**R31a — the `-0` bug has a second site, and that screen isn't built yet.**
`TransferPlanStep.swift:106` carries the identical `let prefix = negative && amount > 0 ? "-" : ""`
as `SummaryCard.swift:97`. Fixing only the Dashboard leaves **New Month shipping the same
`-0 RON`** when expenses are zero. Free to get right at authoring time — attach to R28a.

**R31b — `AccountAllocation.id` is a fresh `UUID()` per computation.**
So it is **not** a stable React key, and not a usable identity across responses. Key transfer
rows on the **index**, or an `(accountId, position)` composite. Compounds R25 row 8: one account
can appear twice, and its `id` changes every fetch.

## R32 — `isBalanced` is false **iff `totalExpenses > income`**, and that state renders NOTHING

The Critic probed all 16 mode × account-set cells and `!isBalanced` fired in **none** of them.
Rather than widen the search it derived the trigger from `TransferCalculator.swift:70-71`:

```
total = remainsInPrimary + expenseTransfers + allocations + remainingMoney
      = totalExpenses + availableIncome
availableIncome = max(0, income − totalExpenses)     ← the clamp is the whole story
```

If `income >= totalExpenses` then `total == income` and it is **always balanced**. Only the
`max(0, …)` clamp can break the identity. Predicted, then tested:

```
income=9000 exp=9000  isBalanced=true   banner SHOWN     ← boundary
income=9000 exp=9001  isBalanced=false  banner ABSENT    ← one unit later
income=0    exp=500   isBalanced=false  banner ABSENT
```

**`isBalanced == false` ⟺ `totalExpenses > income`.** Mode-independent and
account-set-independent — so the earlier assumption that this was a rare multi-factor state was
wrong; it is a single, simple, reachable condition.

### ⚠️ At `expenses > income`, N1 and N4 fire **together** — the screen renders nothing at all

New Month step 3 shows the summary card and then **nothing else**: no "Transfers to make" card,
no validation banner, no warning, no error state. **This is the single most inviting place in the
entire flow to add "Your expenses exceed your income!" — and iOS shows nothing.** Any implementer
looking at that blank screen will conclude something is broken.

**The regression vector to write first** (Critic's, adopted): `exp == income` versus
`exp == income + 1`. Adjacent states with **different** output — banner shown + card absent,
versus banner absent + card absent. It pins the clamp boundary and cannot pass by accident.

### Negative-space register, now pre-verified rather than provisional

| Entry | Mode-dependent? | Notes |
|---|---|---|
| Emergency row when fund full | **YES** — 3 cases (R28d / §7.3 5a-5c) | plus a multiplier condition |
| **N2** no-note row | **YES** | `EF+SAV, EF empty`: no nil-note row under prioritized, one under split — split allocates to savings (note always nil), prioritized sends all to emergency |
| N1 banner | no | trigger above |
| N3 no remaining-money row | no | `availableIncome == 0` |
| N4 whole card absent | no | `availableIncome == 0` |
| **N5, N6, N7** (Settings) | **no axis at all** | read account *properties*, never touch `TransferPlan` — mode-independent **by construction**. Do not build a mode axis here; there is nothing to vary. |

**The account-set axis earned its place:** the `EF only, EF full` divergence (rows=1 with
`+0 RON` under prioritized, rows=0 under split) exists *only* because that axis was varied.

## R33 — Brand the **state**, not just the component (amends R24)

R24 branded `display` / `editing` so `AmountField.value: EditingString` rejects a display string
at compile time. **That only protects code routed through `AmountField`.** Frontend2's onboarding
used hand-rolled `<input>`s, so the feature **typechecked green while doing precisely what R24
exists to stop.** The guard was on the door, not the room.

Fix, applied: brand the **draft state** itself. It surfaced **9 compile errors on 9 real sites** —
i.e. the unprotected surface was larger than the protected one.

**The general rule:** a type guard placed on a *component boundary* is bypassed by anyone who
doesn't use the component. Put it on the **data** — the state, the model, the parsed value — so
every consumer inherits it. Same logic as R21 (guard the arithmetic, not the formatters) and R24
itself (make it unrepresentable, not documented): **push the constraint down to where the value
lives.**

## R34 — R2 exemption for `lib/i18n.ts`: approved, and why the precedent is narrow

Frontend's positional-specifier fix needs `Number(pos)` to turn `"2"` in `%2$lld` into an array
index, which trips the no-client-maths guard. It added `lib/i18n.ts` to `EXEMPT` with an inline
justification, and flagged that the guard's own documentation says not to.

**Approved.** The guard exists to stop **money** arithmetic. `i18n.ts` has no access to a
`MoneyValue` at all — there is nothing there for the rule to protect, and the coerced value is a
*format-specifier index*, never a quantity. Loosening the **pattern** would have been wrong;
exempting one file that provably handles no money is not.

**Conditions, so this doesn't become a general escape hatch:** the exemption is per-**file**,
never per-pattern; it carries an inline justification naming why no money can reach it; and it is
listed here. Raising it rather than silently adding it was the right call — an exemption nobody
reviewed is how a mechanical guard decays into decoration.

### R34a — the defect class that fix exposed

`interpolate` never handled positional specifiers, and Xcode's extractor emits `%1$lld` for
**any** string taking more than one argument. So **every multi-argument string in both catalogs
was rendering its specifiers raw** — it simply hadn't surfaced because nothing built so far used
one.

It was invisible to the build, invisible to 123 passing tests, and invisible in **both**
languages — because the defect is in **substitution**, not lookup. Only rendering a real
multi-argument string exposed it. Worth remembering as a category: *a bug in the mechanism that
formats every string is invisible until a string exercises the mechanism.*

## R35 — Every `t()` key must be proven to resolve. A spec note is not a control.

`NewMonthSheet.tsx:418` used an **en dash** (U+2013) where iOS and the catalog use a
**hyphen-minus** (U+002D). Verified: client bytes `e2 80 93`, catalog key codepoint `0x2d`.

**One character, two symptoms:**
1. **English:** an en dash renders where iOS renders a hyphen — a visible glyph difference on the
   flow's completion button.
2. **Romanian:** the key misses, silently falls back to itself, and renders **English**.
   `'Gata - Am făcut transferurile'` sits in the catalog, unreachable from that call site.

**The process point is the important one.** `PARITY-SPEC.md §7.3` *explicitly* said "the label uses
a plain hyphen-minus, not an en dash" — and it still slipped. **A note in a document is not a
control.** Same lesson as R21/R24/R33, now for strings: the constraint has to be mechanical.

**Binding — a new client test:** scan every `t()` / `tDomain()` call in `src`, extract the literal
key, and assert it **exists in the namespace it is bound to**. Any key that would silently
key-fall-back fails the build. This catches the whole class — mistyped keys, en/em dashes, smart
quotes, `…` vs `...`, non-breaking spaces — rather than the one instance.

Three things it must get right, or it becomes another instrument that agrees with the bug:

**1. Verify it non-vacuously**, as was done for the no-client-maths guard. Two planted cases,
because they test different failure modes:
- an **en dash** for a hyphen → tests glyph normalisation;
- **`New Category` vs `New Category...`** → tests **key selection**. This is the most conflatable
  pair in the catalogs: *both* keys are live, *both* have Romanian, and they differ only by
  trailing dots. `New Category` → `Categorie nouă` is the nav title
  (`CategoryManagementView.swift:212`); `New Category...` → `Categorie nouă...` is the menu label
  (`AddExpenseSheet.swift:78`). Picking the wrong one, or typing `…` for `...`, silently loses
  Romanian while looking perfect in English. (Frontend got both right independently, including a
  test asserting the three literal dots.)

**2. An allowlist for keys that are *correctly* absent**, where iOS also falls back to English so
translating would be R26a. Entries: `Back` (absent from the dashboard catalog,
`NewMonthSheet.swift:49`), `Developer Tools`, `%lld percent complete` (resolves against a
bundle-less SharedUI), `Amount` (SharedUI calls `String(localized:)` with **no `bundle:`** so it
binds `.main`, which has no `Amount`; the `expenses` "Sumă" is an orphan that call site cannot
reach), the `Currency.displayName` values (`Romanian Leu (RON)` / `Euro (EUR)` /
`US Dollar (USD)` — bare literals, **no `.localized` call at all**), and `Step %lld of %lld`
(live variant untranslated; the translated `%d` variant is an unreachable orphan).

⚠️ **`Monthly` and `Annual` are NOT allowlist entries — that instruction of mine was wrong, and
the guard caught it on its first run.** Both facts hold simultaneously and they are not in
conflict:
- **English** comes from `Frequency.displayName`, which is rendered **raw** and never reaches
  `t()` at all — so it needs no allowlist entry.
- **Romanian** comes from `t('Annual')` on the row caption, which **does** resolve to `Anual` in
  the `expenses` catalog (`ExpenseItemRow.swift:60`).

Had the entries stayed, they would have **masked a real miss on the row caption.** This is the
guard-encodes-a-wrong-belief hazard firing on **my own instruction**, and being caught by the
mechanism it was about to corrupt. The lesson is not "be careful with allowlists" but: *an
allowlist entry must name the call site it exempts, not just the key* — because the same key can
be correct-English at one call site and correct-Romanian at another.

**⚠️ Without the allowlist this guard would actively push someone into breaking parity** — it
would flag New Month's back button and the Monthly/Annual control as defects. That is a
guard-encodes-the-wrong-belief hazard, the mechanical analogue of a wrong spec note.

**3. Every allowlist entry carries its reason AND its evidence** — which catalog lacks the key,
and which call site proves it. Analyst's rule, adopted verbatim: *an allowlist without reasons
decays into a list of things someone once suppressed.* A future reader must be able to re-derive
each entry, or they will "helpfully" delete it.

⚠️ **A second site the punctuation sweep missed: `Gallery.tsx:114`** carries the same en dash. It
is dev-only and route-gated so it is not a parity defect, but it shows the sweep was
`t()`-scoped while the *string* appears elsewhere — the mechanical check should cover
`src/**` and treat gallery/fixture copies as a separate, labelled category (R22's residue again).

## R36 — **Shadowing**: the first case that defeats the three-part localization rule

`SettingsSheet.swift:698-706` declares a **`private extension RemainingMoneyDestination { var
displayName }`** that *shadows* Domain's property for every call site in that file. So `:403`'s
`Text(destination.displayName)` silently resolves to the **private** one.

The Critic read `:403` first and nearly filed row 7 as a false alarm — **the line is
character-identical to the onboarding call site.** The shadow is invisible unless you scroll to
the bottom of the file.

| case | Settings | Onboarding |
|---|---|---|
| `.primarySavings` | Primary Savings / `Economii principale` | same |
| `.personal` | Personal Account / `Cont personal` | same |
| **`.primary`** | **Primary Account** / `Cont principal` | **Keep in Primary** / `Păstrează în Principal` |

**Only `.primary` differs, and both sides translate** — so this is *not* an English-leakage case.
It is two labels for one enum case on two screens. The web needs a **Settings-scoped override for
`.primary` only**, and must not unify them in either language. The app catalog carries all three
keys, so the shadow introduces no bundle gap.

### Why this is a rule amendment, not just a finding

Standing rule #3 says three things must agree — call **form**, **bundle**, **catalog**. Here
**all three agree and the answer is still wrong**, because the *symbol* resolves somewhere other
than where you would look. So the rule needs a fourth clause:

> **4. Which declaration the symbol actually resolves to.** A `private extension` on an imported
> type shadows the original for that file only.

The tell is `private extension` on a type you didn't define. There is exactly **one** in the
codebase (`grep -rn "private extension RemainingMoneyDestination"`), so it is not systemic — but
⚠️ **a key-resolution guard that resolves `displayName` by type name will get this one wrong in
the confident direction.** R35's guard must special-case it or skip `displayName` entirely.

### R36a — Settings' enum rule is simpler than the global one

Settings renders **no `Frequency` control** (that's the Expenses tab). So on Settings,
**`Currency` is the only enum that must stay English** — 4 translate, 1 raw. A cleaner rule for
that screen than the global 4-of-6, and less likely to be misapplied.

Per-key evidence confirmed: `Primary→Principal`, `Joint→Comun`, `Other→Altul`,
`Priority→Prioritizat`, `Fixed Amount→Sumă fixă`.

## R8 — D6 becomes measurable

Replacing the unfalsifiable wording:
- Axis 1 (numeric) is enforced by a **checked-in golden-vector JSON** asserted by both the
  Swift tests and the Playwright suite. Without that harness it was a slogan.
- Axis 4 (visual): spacing/size parity judged at **±2px** against the named screenshots in
  `Web/Docs/reference-screens/`.
  ⚠️ **Amended — this bullet used to say "laptop viewport 1280×900 being the primary target",
  which contradicted R9.** R9 governs: the **402px column is the only graded width**. 1280×900
  is still captured, to confirm the column centres sanely in a laptop window, but it is **not
  graded** and has no ±2px criterion. Caught by the Reviewer as OQ9.
- "Closest faithful approximation" is replaced by an **enumerated list of accepted
  deviations** in `PARITY-GAPS.md`. If a deviation is not enumerated, it is a bug.
