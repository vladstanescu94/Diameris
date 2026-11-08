# API CONTRACT — Diameris web server

**Owner:** Backend. Frontend reads this; request changes by messaging Backend.
**Version:** v1 (2026-08-06). Shapes below are **frozen** unless this doc says otherwise.

Base URL: `http://127.0.0.1:8080`. No auth, no CORS (same origin — the server also serves
`Web/Client/dist` with SPA fallback to `index.html`).

Content type is `application/json` for every request and response. Keys are **camelCase**.

### Null convention — read this before typing your DTOs

**A field whose value is null is omitted from the JSON entirely.** Swift's `Codable` encodes
optionals with `encodeIfPresent`, so `"profile": null` never appears — the `profile` key is simply
absent. This applies to every nullable field: `profile`, `dashboard.emergencyFund`,
`dashboard.primaryAccount`, `account.purpose`, `account.emergencyMultiplier`,
`account.emergencyTarget`, `expense.categoryId`, `expense.category`, `expense.linkedAccountId`,
`expense.notes`, `allocation.targetAmount`, `allocation.progressChangeDisplay`,
`unallocatedRemainingMoney`, and the rest.

Where this doc writes `"someField": null` in an example, read it as *"the key is absent"*. Type
these as **optional** properties in TypeScript (`profile?: Profile`) and test them with
`if (!state.profile)` or `state.dashboard.emergencyFund ?? null` — **not** `=== null`, which
fails on an absent key. If you use a schema validator, mark them `.optional()`, not `.nullable()`.

*Why not emit explicit nulls?* It would mean hand-writing `encode(to:)` for ~15 DTOs, and every
one becomes a place where a newly added field is silently dropped from the API because someone
forgot to add a line. One documented convention is the safer trade.

---

## 0. The two rules that matter most

### 0.1 Money is never a JSON number

Every monetary value in **responses** is an object:

```json
{ "amount": "1182.5", "display": "1,182 RON", "editing": "1182.5", "isZero": false }
```

| Field | Meaning | Produced by |
|---|---|---|
| `amount` | Exact decimal, canonical (`.` separator, no grouping, no currency). The **only** value you may compute with — and you should never need to. | `Decimal.description` |
| `display` | Ready-to-render string, currency code appended. **Render this. Never re-format it.** | `Utilities.AmountFormatter.formatForDisplay` |
| `editing` | Value for a prefilled `<input>`. **`""` when the amount is ≤ 0** (iOS behaviour). Up to 2 dp, no grouping, `.` decimal separator. | `Utilities.AmountFormatter.formatForEditing` |
| `isZero` | Whether the underlying decimal is exactly zero. **Use this for zero tests, never the strings.** | `value == 0` |

> ⚠️ **Never infer zero from `display`.** With `maximumFractionDigits = 0`, `-0.004` renders as
> **`"-0 RON"`** and `0.4` renders as `"0 RON"` — so `display == "0 RON"` is wrong in *both*
> directions, and `-0 RON` is reachable (the Skip-for-now paths can land a hair below zero).
> `isZero` is the guard. `parseFloat(amount) === 0` would be client-side numeric logic, which R2
> forbids anyway.

> ⚠️ **`editing` is display-only — never parse it.** As of v1.2 the server pins its locale to
> `en_US` (R7), so `editing` is reliably `"1182.5"` on every machine. Before that pin it was
> `"1182,5"` here, because `formatForEditing` leaves the decimal separator to the host locale —
> which is also why `GROUND-TRUTH.md` records the iOS fields as `3547,5` (the reference simulator
> used Romanian regional formats). When the user submits, send back the canonical `amount` you
> were given, or round-trip the typed text through `POST /api/parse-amount`. Never
> `parseFloat(editing)`.
>
> ⚠️ **One field is not `AmountFormatter`-formatted at all**: the Settings account editor's
> balance input. Use `account.balanceEditorValue` there — see §2.1.

`display` and `editing` come from the *same* `Utilities` code the iOS app compiles, so
formatting is identical by construction — including the half-even (banker's) rounding that
makes `1182.5 → "1,182 RON"` and `3547.5 → "3,548 RON"`.

> **Frontend: do not implement any number formatting.** If you need a formatted string that
> isn't in a response, that is a missing server field — message Backend.

In **requests**, money is a plain JSON **string**: `"9000"`, `"1182.5"`, `"0"`.
A JSON *number* is rejected with `400` and a message telling you to send a string. This is
deliberate: JS `number` cannot represent `1182.5` round-trips reliably across the whole app,
and a silent precision loss here would break numeric parity everywhere downstream.

### 0.2 Every mutation returns the whole state

This mirrors the iOS data-flow contract (`DOMAIN-CONTRACT.md §8`): a single `DataObserver`
listens for `ModelContext.didSave` and re-derives **every** view model from scratch. So here,
**every mutating endpoint returns exactly the same body as `GET /api/state`** — the complete,
freshly-derived state. Replace your whole client store with the response; never patch it.

Consequence: there is no such thing as a partial update response, and no endpoint returns a
bare created object.

---

## 1. `GET /api/state`

The one read you need. Returns `AppState`.

```jsonc
{
  "schemaVersion": 1,
  "onboardingCompleted": true,
  "profile": {
    "name": "Vlad",
    "currencyCode": "RON",
    "currencyDisplayName": "Romanian Leu (RON)",
    "remainingMoneyDestination": "primarySavings",
    "remainingMoneyDestinationDisplayName": "Primary Savings",
    "createdAt": "2026-08-06T13:22:41Z"
  },
  "settings": {
    "income": { "amount": "9000", "display": "9,000 RON", "editing": "9000" },
    "savings": {
      "percentage": 0.25,
      "percentageDisplay": "25%",
      "effectivePercentage": 0.25,
      "effectivePercentageDisplay": "25%",
      "boostEnabled": false,
      "boostMultiplier": 3,
      "isBoostApplicable": true,
      "allocationMode": "prioritized",
      "allocationModeDisplayName": "Priority",
      "allocationModeDescription": "Emergency fund fills first, then savings",
      "savingsInputMode": "percentage",
      "fixedAmount": { "amount": "0", "display": "0 RON", "editing": "" },
      "splitEmergencyInputMode": "fixedAmount",
      "splitEmergencyAmount": { "amount": "0", "display": "0 RON", "editing": "" },
      "splitEmergencyPercentage": 0.1,
      "splitSavingsInputMode": "fixedAmount",
      "splitSavingsAmount": { "amount": "0", "display": "0 RON", "editing": "" },
      "splitSavingsPercentage": 0.15,
      "isValid": true
    }
  },
  "accounts": [ /* Account, sorted by sortOrder */ ],
  "expenses": [ /* Expense, sorted by sortOrder then createdAt */ ],
  "categories": [ /* Category, sorted by sortOrder */ ],
  "dashboard": { /* §2.4 */ },
  "expensesScreen": { /* §2.5 */ },
  "transferPlan": { /* §2.6 */ },
  "reference": { /* §2.7 — enum tables, for pickers */ }
}
```

`profile` is `null` and `onboardingCompleted` is `false` before onboarding completes.
When `profile` is `null`, `dashboard` and `transferPlan` are still present but derived from
zero income (all amounts `"0"`), and `expensesScreen.categories` is empty.

### 2.1 `Account`

```json
{
  "id": "4C9B21A0-7E64-4C2E-9B1F-0A6D3E7F1122",
  "name": "Emergency Fund",
  "purpose": "Protects you from unexpected expenses",
  "accountType": "emergency",
  "accountTypeDisplayName": "Emergency",
  "accountTypeDescription": "Fills first until target reached",
  "icon": "shield.fill",
  "isPrimary": false,
  "isPrimarySavings": false,
  "emergencyMultiplier": 3,
  "emergencyHardCap": null,
  "currentBalance": { "amount": "1182.5", "display": "1,182 RON", "editing": "1182.5" },
  "sortOrder": 1,
  "emergencyTarget": { "amount": "27000", "display": "27,000 RON", "editing": "27000" },
  "emergencyProgress": 0.04379629629629629,
  "emergencyProgressPercent": 4,
  "emergencyProgressDisplay": "4%",
  "isEmergencyComplete": false,
  "subtitleParts": ["Emergency", "3× income"],
  "emergencyTargetUncapped": { "amount": "27000", "display": "27,000 RON", "editing": "27000" },
  "isCapActive": false,
  "multiplierOptions": [
    { "multiplier": 3, "display": "3×", "caption": "Minimum recommended",
      "target": { "amount": "27000", "display": "27,000 RON", "editing": "27000" },
      "targetUncapped": { "amount": "27000", "display": "27,000 RON", "editing": "27000" },
      "isCapActive": false, "isSelected": true }
  ],
  "isReconcilable": true,
  "wasLastMonthDisplay": "was 1,182 RON last month",
  "balanceEditorValue": "1,182.5"
}
```

- `emergencyTarget` / `emergencyProgress` / `emergencyProgressPercent` /
  `emergencyProgressDisplay` are `null` for non-emergency accounts, and `null` when no
  multiplier is set. All from `Domain.AccountEntry`.
- `emergencyProgressPercent` is `Int(progress * 100)` — **truncated, matching iOS**
  (`0.0438 → 4`, not 4.4 rounded).
- **`subtitleParts`** is the Settings > Accounts row subtitle as **2–3 separate strings**
  (`["Primary"]`, `["Emergency", "3× income"]`, `["Savings", "Primary"]`). iOS renders them as
  distinct inline elements with their own colours and an 8px gap — it was never one concatenated
  string, so none is served (R23). Render the separator yourself.
- `emergencyTargetUncapped` / `isCapActive`: when a hard cap bites, iOS shows the **uncapped**
  target struck through next to the capped one in orange. `emergencyTarget` is already capped, so
  the uncapped figure has to be served or the client would recompute `income × multiplier`.
- `multiplierOptions`: the four discrete options (3–6×) with their captions and their own resolved
  targets, so tapping 3×→6× updates live before anything is saved.
- `isReconcilable`: whether New Month step 2 lets this balance be edited —
  `emergency|savings|personal` only. Served so the client doesn't hardcode the rule.
- `balanceEditorValue`: ⚠️ the Settings account editor uses `TextField(format: .number)`, **not**
  `AmountFormatter` — so it groups (`"1,182.5"`) and shows `"0"` rather than blank for zero.
  `Money.editing` is wrong for that one field.
- `icon` is an **SF Symbol name**. Map it to Lucide client-side (`DESIGN-TOKENS.md`).

### 2.2 `Expense`

```json
{
  "id": "9F1D...",
  "name": "Rent",
  "amount": { "amount": "2500", "display": "2,500 RON", "editing": "2500" },
  "frequency": "monthly",
  "frequencyDisplayName": "Monthly",
  "frequencyIcon": "calendar",
  "monthlyAmount": { "amount": "2500", "display": "2,500 RON", "editing": "2500" },
  "annualAmount": { "amount": "30000", "display": "30,000 RON", "editing": "30000" },
  "icon": "house.fill",
  "categoryId": "D1A00004-0000-0000-0000-000000000004",
  "category": { /* Category, or null */ },
  "linkedAccountId": null,
  "linkedAccountName": "Main Account",
  "isEnabled": true,
  "notes": null,
  "sortOrder": 1
}
```

- `linkedAccountId: null` **means the primary account** (iOS convention). `linkedAccountName`
  resolves it for you — it is the primary account's name when `linkedAccountId` is `null`, and
  `"Unknown"` when the id dangles (iOS's non-localized fallback; ids are loose, not FKs).
- `annualAmount` for a monthly expense is `× 12`; `monthlyAmount` for an annual expense is
  `× (1/12)` computed in `Decimal`, so it does not drift on large sums.

### 2.3 `Category`

```json
{
  "id": "D1A00001-0000-0000-0000-000000000001",
  "name": "Auto/Transport",
  "icon": "car.fill",
  "colorHex": "#3B82F6",
  "isDefault": true,
  "sortOrder": 0
}
```

The 8 defaults are seeded from `Domain.Category.defaults` with their fixed UUIDs
(`D1A00001…` – `D1A00008…`), so ids are stable across restarts and match iOS.
Category **names are raw English in Domain and are NOT localized** — if RO is needed, the
client's i18n must translate them by name.

### 2.4 `dashboard`

Everything the Dashboard screen renders, in render order.

```json
{
  "currentMonthDisplay": "August 2026",
  "summary": {
    "income":          { "amount": "9000",   "display": "9,000 RON",  "editing": "9000" },
    "expenses":        { "amount": "4270",   "display": "4,270 RON",  "editing": "4270" },
    "savings":         { "amount": "1182.5", "display": "1,182 RON",  "editing": "1182.5" },
    "personalSpending":{ "amount": "3547.5", "display": "3,548 RON",  "editing": "3547.5" }
  },
  "emergencyFund": {
    "accountId": "4C9B...",
    "accountName": "Emergency Fund",
    "balance": { "amount": "1182.5", "display": "1,182 RON", "editing": "1182.5" },
    "target":  { "amount": "27000",  "display": "27,000 RON", "editing": "27000" },
    "progress": 0.04379629629629629,
    "progressPercent": 4,
    "progressDisplay": "4%",
    "multiplier": 3,
    "targetCaption": "Target: 3× monthly income",
    "isComplete": false
  },
  "primaryAccount": { /* Account, or null */ },
  "otherAccounts": [ /* Account[] — accounts where isPrimary == false */ ],
  "expenseBreakdown": [
    { "id": "…", "name": "Rent",      "icon": "house.fill",
      "amount": { "amount": "2500", "display": "2,500 RON", "editing": "2500" },
      "percent": 58, "percentDisplay": "58%" },
    { "id": "…", "name": "Food",      "icon": "cart.fill",     "amount": { "…": "…" }, "percent": 28, "percentDisplay": "28%" },
    { "id": "…", "name": "Gas",       "icon": "fuelpump.fill", "amount": { "…": "…" }, "percent": 10, "percentDisplay": "10%" },
    { "id": "…", "name": "Streaming", "icon": "tv.fill",       "amount": { "…": "…" }, "percent": 2,  "percentDisplay": "2%" }
  ]
}
```

- `summary.savings` is `transferPlan.totalSavings` and `summary.personalSpending` is
  `transferPlan.remainingMoney` — the exact two fields `SummaryCard` is fed on iOS. They are
  *not* recomputed separately.
- `emergencyFund` is `null` when there is no emergency account.
- `currentMonthDisplay` is `DateFormatters.monthYear` on the **server's** locale/clock
  (`"MMMM yyyy"`), same as iOS uses the device's.
- `expenseBreakdown` is enabled expenses with `monthlyAmount > 0`, **sorted amount-descending,
  capped at 5** (`ExpenseBreakdownCard.prefix(5)`). `percent` is
  `Int((amount / total) * 100)` — **truncated**, so Streaming `120/4270 = 2.81%` renders
  **`2%`**. ⚠️ `GROUND-TRUTH.md` writes this row as "~3%"; the code truncates, so `2` is
  correct. Flagged to `main`.

### 2.5 `expensesScreen`

```json
{
  "totalMonthly": { "amount": "4270",  "display": "4,270 RON",  "editing": "4270" },
  "totalAnnual":  { "amount": "51240", "display": "51,240 RON", "editing": "51240" },
  "categories": [
    {
      "category": { /* Category */ },
      "id": "D1A00004-0000-0000-0000-000000000004",
      "name": "Housing",
      "enabledCount": 1,
      "totalCount": 1,
      "enabledCaption": "1/1 enabled",
      "monthlyTotal": { "amount": "2500", "display": "2,500 RON", "editing": "2500" },
      "annualTotal":  { "amount": "30000","display": "30,000 RON","editing": "30000" },
      "expenses": [ /* Expense[] */ ]
    }
  ]
}
```

**Group order reproduces `ExpensesViewModel.swift:291-327` exactly:**
1. one group per **known** category that has expenses, in `sortOrder`;
2. then one group per **unknown** (dangling) `categoryId` — `category` omitted, `id` = the dangling
   id, `name` = `"Uncategorized"`;
3. then the **uncategorized** group if any expense has no `categoryId` — `id` is the sentinel
   `00000000-0000-0000-0000-000000000000`, `category` omitted, `name` = `"Uncategorized"`.

- **`id` is always present and is the correct React key.** `category?.id` is not: two groups for two
  *different* deleted categories both have no `category` and would collide into one row.
- **`category` is optional** (omitted, per the null convention) for groups 2 and 3. `name` is always
  present, so the `"Uncategorized"` fallback string never has to be invented client-side.
- Group totals count **enabled expenses only**; `enabledCaption`'s denominator is **all** expenses in
  the group. `totalMonthly`/`totalAnnual` at the top are global and **search-independent**.

### 2.6 `transferPlan`

Straight from `Domain.TransferCalculator` — assembled, never recomputed.

```json
{
  "income":          { "amount": "9000",   "display": "9,000 RON", "editing": "9000" },
  "totalExpenses":   { "amount": "4270",   "display": "4,270 RON", "editing": "4270" },
  "availableIncome": { "amount": "4730",   "display": "4,730 RON", "editing": "4730" },
  "totalSavings":    { "amount": "1182.5", "display": "1,182 RON", "editing": "1182.5" },
  "accountAllocations": [
    {
      "accountId": "4C9B...",
      "accountName": "Emergency Fund",
      "accountType": "emergency",
      "icon": "shield.fill",
      "amount": { "amount": "1182.5", "display": "1,182 RON", "editing": "1182.5" },
      "progressBefore": 0,
      "progressAfter": 0.04379629629629629,
      "progressBeforePercent": 0,
      "progressAfterPercent": 4,
      "progressChangeDisplay": "0% → 4%",
  "newMonthNote": "0% → 4%",
  "progressChangeTone": "warning",
      "targetAmount": { "amount": "27000", "display": "27,000 RON", "editing": "27000" },
      "currentBalance": { "amount": "0", "display": "0 RON", "editing": "" },
      "isComplete": false
    }
  ],
  "remainsInPrimary": { "amount": "4270", "display": "4,270 RON", "editing": "4270" },
  "accountExpenseTransfers": [],
  "remainingMoney": { "amount": "3547.5", "display": "3,548 RON", "editing": "3547.5" },
  "remainingDestination": "primarySavings",
  "remainingDestinationDisplayName": "Primary Savings",
  "isBalanced": true,
  "hasAccountAllocations": true,
  "totalAccountAllocations": { "amount": "1182.5", "display": "1,182 RON", "editing": "1182.5" },
  "summary": "Income: 9,000 | Savings: 1,182 | Remaining: 3,548"
}
```

- **`accountAllocations` has no `id`.** iOS mints a fresh `UUID()` on every recomputation, so
  it is useless as a React key — **key on `accountId`**, which is stable.
- **Completion strings are per-screen, deliberately not unified (R30).** The same `isComplete` flag
  drives two different renderings, so one field would be wrong on one screen:
  | Field | Screen | Semantics |
  |---|---|---|
  | `newMonthNote` | New Month (`TransferPlanStep.swift:188-193`) | `"Completes fund to 100%!"` **replaces** the progress string — but only when `accountType == "emergency"` **and** `isComplete`. Otherwise it *is* the progress string. Render this field alone. |
  | `onboardingCompletionNote` | Onboarding (`TransferPlanScreen.swift:375-386`) | `"Target reached!"` **appended** as a ✓ row *beside* `progressChangeDisplay`. **Not** gated on `accountType`. `null` unless `isComplete` and a progress string exists. |
  | `progressChangeTone` | Onboarding | `positive` / `warning` for the progress text's colour (iOS `.green` / `.orange`). |
- `progressChangeDisplay` uses the literal `→` (U+2192) and truncated ints, exactly as
  `TransferPlan.AccountAllocation.progressChangeDisplay` does. `null` unless both progresses
  are set.
- **`accountExpenseTransfers` is sorted by `accountName` ascending** by the server. Domain
  builds it from a `Dictionary(grouping:)`, so its natural order is nondeterministic; sorting
  here is what stops rows from shuffling between requests (`DECISIONS.md` D1 ⚠️).
- `accountAllocations` keeps Domain's **priority order** (emergency first, then savings) — not
  sorted. Do not reorder it.

### 2.7 `reference`

Enum tables for every picker, in `allCases` declaration order — which **is** the order iOS
renders them in. Use this instead of hardcoding enum lists in TS.

```json
{
  "accountTypes": [
    { "value": "primary", "displayName": "Primary", "description": "Where your salary lands",
      "icon": "building.columns.fill", "hasBehavior": true, "isUnique": false }
  ],
  "frequencies":  [ { "value": "monthly", "displayName": "Monthly", "icon": "calendar" } ],
  "allocationModes": [ { "value": "prioritized", "displayName": "Priority",
                         "description": "Emergency fund fills first, then savings" } ],
  "savingsInputModes": [ { "value": "percentage", "displayName": "Percentage" } ],
  "remainingMoneyDestinations": [
    { "value": "primarySavings", "displayName": "Primary Savings",
      "description": "Add to your savings for future goals", "icon": "banknote.fill" }
  ],
  "currencies": [ { "value": "RON", "symbol": "lei", "displayName": "Romanian Leu (RON)" } ],
  "savingsConstants": {
    "minimumPercentage": 0.05, "maximumPercentage": 0.5, "recommendedPercentage": 0.25,
    "presets": [0.1, 0.15, 0.2, 0.25, 0.3],
    "defaultBoostMultiplier": 3, "defaultEmergencyMultiplier": 3,
    "emergencyMultiplierRange": [3, 6]
  },
  "expenseIcons": ["dollarsign.circle.fill", "cart.fill", "…18 total, see GROUND-TRUTH"],
  "defaultNewCategory": { "icon": "star.fill", "colorHex": "#3B82F6", "sortOrder": 100 },
  "defaultExpenseIcon": "dollarsign.circle.fill"
}
```

⚠️ `remainingMoneyDestinations[].displayName` for `primary` is Domain's **`"Keep in Primary"`**.
`SettingsSheet` privately relabels it `"Primary Account"` — a genuine iOS inconsistency
(`DOMAIN-CONTRACT.md §1`). Use `"Keep in Primary"` in the onboarding picker (matches
`GROUND-TRUTH.md` step 7) and hardcode `"Primary Account"` in Settings if you want to match
that screen too. Your call; flag it in `PARITY-GAPS.md`.

⚠️ Enum `displayName`s come from Domain's `.localized`, which resolves against
`Bundle.module`. SwiftPM copies `Localizable.xcstrings` without compiling it on macOS, so
these fall back to the key — **which is the English string** (verified). So **EN is exact and
RO must come from the client's i18n dictionary**, keyed by the English string. Do not expect
the server to return Romanian.

---

## 3. Mutating endpoints

All return `AppState` (§1). All are `Content-Type: application/json`.

### `POST /api/onboarding/complete`

Body — mirrors `OnboardingViewModel.save` exactly:

```json
{
  "name": "Vlad",
  "currencyCode": "RON",
  "monthlyIncome": "9000",
  "accounts": [
    { "id": "AAAA...", "name": "Main Account", "purpose": "Where your salary lands",
      "accountType": "primary", "isPrimary": true, "isPrimarySavings": false,
      "emergencyMultiplier": null, "emergencyHardCap": null, "currentBalance": "0" },
    { "id": "BBBB...", "name": "Emergency Fund", "purpose": "Protects you from unexpected expenses",
      "accountType": "emergency", "isPrimary": false, "isPrimarySavings": false,
      "emergencyMultiplier": 3, "emergencyHardCap": null, "currentBalance": "0" },
    { "id": "CCCC...", "name": "Savings", "purpose": "For building wealth over time",
      "accountType": "savings", "isPrimary": false, "isPrimarySavings": true,
      "emergencyMultiplier": null, "emergencyHardCap": null, "currentBalance": "0" }
  ],
  "expenses": [
    { "id": "E1...", "name": "Food",      "amount": "1200", "frequency": "monthly", "icon": "cart.fill",     "categoryId": "D1A00007-0000-0000-0000-000000000007", "linkedAccountId": null, "isEnabled": true, "notes": null },
    { "id": "E2...", "name": "Rent",      "amount": "2500", "frequency": "monthly", "icon": "house.fill",    "categoryId": "D1A00004-0000-0000-0000-000000000004", "linkedAccountId": null, "isEnabled": true, "notes": null },
    { "id": "E3...", "name": "Gas",       "amount": "450",  "frequency": "monthly", "icon": "fuelpump.fill", "categoryId": "D1A00001-0000-0000-0000-000000000001", "linkedAccountId": null, "isEnabled": true, "notes": null },
    { "id": "E4...", "name": "Streaming", "amount": "120",  "frequency": "monthly", "icon": "tv.fill",       "categoryId": "D1A00002-0000-0000-0000-000000000002", "linkedAccountId": null, "isEnabled": true, "notes": null }
  ],
  "savings": {
    "percentage": 0.25, "boostEnabled": false, "boostMultiplier": 3,
    "allocationMode": "prioritized", "savingsInputMode": "percentage", "fixedAmount": "0",
    "splitEmergencyInputMode": "fixedAmount", "splitEmergencyAmount": "0", "splitEmergencyPercentage": 0.1,
    "splitSavingsInputMode": "fixedAmount",  "splitSavingsAmount": "0",  "splitSavingsPercentage": 0.15
  },
  "remainingMoneyDestination": "primarySavings"
}
```

Every field in `savings` is optional and falls back to the Domain default. `id` on accounts and
expenses is optional (server mints one); **send them** so the ids you used for
`linkedAccountId` during onboarding survive.

Server behaviour, identical to `OnboardingViewModel.save`: expenses with `amount <= 0` are
**dropped**; the transfer plan is computed; account balances are updated by allocations +
expense transfers; primary is **set** to `remainsInPrimary`; `remainingMoney` is added to the
destination account. With the example above the store ends at Main `4270`, Emergency `1182.5`,
Savings `3547.5`.

> One deliberate divergence: iOS's `Account(from:)` **regenerates** the account UUID on save,
> orphaning onboarding ids. The server **keeps** the ids you send. Observationally identical
> (iOS re-reads from the store immediately after), and it avoids dangling `linkedAccountId`s.

### `POST /api/onboarding/preview`

Same body as `/complete`, **persists nothing**. For onboarding steps 5–7, which show live
numbers before saving.

```json
{
  "availableIncome": { "amount": "4730",   "display": "4,730 RON", "editing": "4730" },
  "savingsAmount":   { "amount": "1182.5", "display": "1,182 RON", "editing": "1182.5" },
  "totalExpenses":   { "amount": "4270",   "display": "4,270 RON", "editing": "4270" },
  "accounts": [ /* Account[] with emergencyTarget resolved against this income */ ],
  "transferPlan": { /* §2.6 */ }
}
```

`savingsAmount` is `SavingsAllocationEntry.calculateSavings(availableIncome:)` — the number
behind step 6's "That's 1,182 RON/month".

### `PUT /api/settings`

Every field optional; omitted fields are left untouched.

```json
{
  "name": "Vlad",
  "currencyCode": "RON",
  "monthlyIncome": "9000",
  "remainingMoneyDestination": "primarySavings",
  "savings": { "percentage": 0.3, "boostEnabled": true }
}
```

### `POST /api/accounts` · `PUT /api/accounts/:id` · `DELETE /api/accounts/:id`

```json
{ "name": "Emergency Fund", "purpose": "Protects you from unexpected expenses",
  "accountType": "emergency", "isPrimary": false, "isPrimarySavings": false,
  "emergencyMultiplier": 3, "emergencyHardCap": null, "currentBalance": "0" }
```

`PUT` treats every field as optional (partial update). Enforced rules, matching iOS:
- **At most one `emergency` account** (`AccountType.isUnique`) → `409` `"Only one emergency account is allowed"`.
- **Exactly one primary**: setting `isPrimary: true` clears it on every other account.
- Deleting the primary account → `409` `"The primary account cannot be removed"`.

### `POST /api/expenses` · `PUT /api/expenses/:id` · `DELETE /api/expenses/:id`

```json
{ "name": "Rent", "amount": "2500", "frequency": "monthly", "icon": "house.fill",
  "categoryId": "D1A00004-0000-0000-0000-000000000004",
  "linkedAccountId": null, "isEnabled": true, "notes": null }
```

`PUT` is a partial update — send `{"isEnabled": false}` alone to flip the accordion toggle.
Defaults on `POST`: `frequency: "monthly"`, `icon: "dollarsign.circle.fill"`,
`isEnabled: true`, `linkedAccountId: null` (= primary).

### `POST /api/expenses/preview`

Live values for an **unsaved** draft in the Add/Edit Expense sheet. Persists nothing. Debounce it
like `/onboarding/preview`.

```json
{ "amount": "1250", "frequency": "annual" }
```
```json
{
  "amount":            { "amount": "1250", "display": "1,250 RON", "editing": "1250", "isZero": false },
  "monthlyAmount":     { "amount": "104.1666666666666666666666666666666", "display": "104 RON", … },
  "annualAmount":      { "amount": "1250", "display": "1,250 RON", … },
  "monthlyEquivalent": { "amount": "104.1666666666666666666666666666666", "display": "104 RON", … },
  "showsMonthlyEquivalent": true
}
```

- `monthlyEquivalent` is the value the **"Monthly Equivalent"** row renders
  (`AddExpenseSheet.swift:32-35`). Identical to `monthlyAmount`; named separately for the row's own
  semantics.
- `showsMonthlyEquivalent` reproduces iOS's render gate — **annual frequency and a positive
  amount** — so the client doesn't reinvent the condition.

⚠️ **This row is `amount × (1/12)`, a division — not `× 12`.** An earlier note in `DECISIONS.md`
recorded it as an annualized `× 12`; implementing that would be **144× wrong**.

⚠️ **And it cannot be done client-side even with correct rounding.** The multiplier is
`Decimal(1)/12`, a 28-significant-digit constant, so an exact `.5` is *unreachable*: `1266 / 12` is
mathematically `105.5` and a JS division rounds it to `106`, but `1266 × Decimal(1)/12` is
`105.4999…` and iOS shows **`105 RON`**. Dividing produces a different *value* at the boundary, not
just different rounding. Verified live: `1200 → 100`, `1250 → 104`, `1266 → 105`.

### `GET /api/categories` · `POST /api/categories` · `DELETE /api/categories/:id`

`GET` returns `{ "categories": [ /* Category[] */ ] }` (defaults + custom, by `sortOrder`).

`POST` body — `sortOrder` defaults to `100`, matching `Category.custom`:

```json
{ "name": "Travel", "icon": "airplane", "colorHex": "#3B82F6" }
```

`DELETE` on a default category → `409` `"Default categories cannot be deleted"`. Deleting a
custom category leaves expenses' `categoryId` dangling — exactly as iOS does; those expenses
come back with `"category": null`.

### `GET /api/transfer-plan`

`{ "transferPlan": { /* §2.6 */ } }` for the current stored state. `GET /api/state` already
includes it; this exists for the Verify harness.

### `POST /api/new-month/preview`

Step 3 of the New Month flow. Persists nothing.

```json
{ "income": "9000", "reconciledBalances": { "4C9B...": "1182.5", "CCCC...": "3547.5" } }
```

```json
{
  "transferPlan": { /* §2.6, computed with the reconciled balances substituted */ },
  "unallocatedRemainingMoney": null,
  "projectedBalances": [
    { "accountId": "4C9B...", "accountName": "Emergency Fund",
      "before": { "amount": "1182.5", "display": "1,182 RON", "editing": "1182,5" },
      "after":  { "amount": "2365",   "display": "2,365 RON",  "editing": "2365" } }
  ]
}
```

`reconciledBalances` maps account id → balance string. **Omitted accounts keep their stored
balance** — you may send a partial map (the iOS sheet only reconciles emergency/savings/personal
accounts, so a Joint account is never in it and must not be reset to zero).
`projectedBalances` is `Domain.BalanceReconciler` — the balances `POST /api/new-month` will write.

`unallocatedRemainingMoney` is `null` in the normal case. It is non-null when
`remainingMoneyDestination` names a *role* no account fills — e.g. the destination is
`primarySavings` but the user has no primary-savings account — in which case that money lands in
no balance at all. When it is non-null, show a warning instead of the
"All amounts add up correctly" banner; the amount really is unaccounted for.

### `POST /api/new-month`

Same body as the preview. Commits: writes income, then the projected balances. Returns
`AppState`.

### `POST /api/reset`

No body. Wipes the store and re-seeds (8 default categories, default savings settings,
no profile / accounts / expenses). `onboardingCompleted` returns to `false`.
This is the Developer Tools parity hook.

### `POST /api/parse-amount`

Utility so the client never has to reimplement input parsing.

```json
{ "text": "1,234" }
```
```json
{ "amount": "1.234", "display": "1 RON", "editing": "1.23" }
```

⚠️ This is `Utilities.AmountFormatter.parse`, which replaces **all** commas with periods — so
`"1,234"` really does parse as **1.234**, not 1234. That is an upstream iOS bug we reproduce
deliberately for parity (`DECISIONS.md` D1 ⚠️, logged in `PARITY-GAPS.md`). Use this endpoint if
you want exact parity on typed input; parse locally only if you accept the divergence.

---

## 4. Errors

```json
{ "error": true, "reason": "Only one emergency account is allowed" }
```

| Status | When |
|---|---|
| `400` | Malformed JSON; money sent as a number instead of a string; unparseable decimal string |
| `404` | Unknown `:id` |
| `409` | A rule violation (second emergency account, deleting primary, deleting a default category) |
| `500` | Store write failure |

Vapor's default error shape is `{"error": true, "reason": "..."}` — that is what you get.

---

## 4.5 Running an isolated instance (R29)

Two environment variables, so a verification run cannot wipe a store someone else is driving:

| Variable | Default | Effect |
|---|---|---|
| `DIAMERIS_PORT` | `8080` | Port to bind (loopback only, always) |
| `DIAMERIS_STORE` | `~/.diameris/web-store.json` | Store path; `~` expanded, relative paths resolve against cwd |

**All three scripts are idempotent.** `run.sh`, `dev.sh` and `verify-server.sh` take an atomic
start lock on their port and exit `0` with "already serving — nothing to do" rather than launching a
doomed second instance. A duplicate start does not fail cleanly: the new process binds, logs
"Diameris web server on …", then dies with `bind(...): Address already in use` — and during the
overlap requests can land on the instance that is dying, which reads as an intermittently
unreachable server. That is the "flapping" everyone was seeing.

⚠️ A plain check-then-start is **not** sufficient and was verified insufficient: two launches inside
the ~4 s boot window both see "not serving" and both start. Hence the lock (`mkdir`, the portable
atomic primitive — `flock` is absent on macOS). Verified with three simultaneous launches: exactly
one listener, zero bind failures, two deferred and exited 0.

⚠️ Use `lsof -ti:<port> -sTCP:LISTEN` to ask "is this port served". **Never `pgrep -f
DiamerisServer`** — it matches *any* instance, so it reports "running" for the Verify server on 8081
while 8080 has no listener. And never `pkill -f DiamerisServer`: it kills every agent's instance.
A genuine bind failure now logs the port, the `lsof` command to find the holder, and that warning,
instead of a bare Swift fatal-error trace.

`Web/verify-server.sh` wraps this: **port 8081 with a fresh throwaway store**, deleted on each
launch so a run never inherits the last one's state. `Web/run.sh` keeps the real defaults.

```bash
./Web/verify-server.sh                                                  # 8081, temp store
python3 Web/Docs/api-propagation-check.py --base-url http://127.0.0.1:8081
```

The gate also honours `DIAMERIS_BASE_URL`. Verified: with both instances up, seeding and
`POST /api/reset`-ing 8081 left 8080's state untouched, and each logs its own `Store:` path at
startup so you can always see which one you are talking to.

## 5. Persistence

One JSON document at `~/.diameris/web-store.json`, guarded by a Swift `actor`, written
atomically (temp file + `FileManager.replaceItem`), with `"schemaVersion": 1`. Money inside the
store is a string too, so `1182.5` survives restarts. Delete the file (or `POST /api/reset`)
for a clean slate.

## 6. Changelog

- **v1** (2026-08-06) — first published contract. Shapes fixed before implementation was
  complete, so Frontend could start. Any change after this point is announced to Frontend
  and `main` and recorded here.
- **v1.9** (2026-08-06) — **`POST /api/expenses/preview`** added, so the Add/Edit Expense sheet's
  "Monthly Equivalent" row needs no client arithmetic. Declines R18's narrow `× 12` exception,
  because the real operation is `× (1/12)` — and at a `.5` boundary a true JS division yields a
  *different value*, not merely different rounding (`1266`: iOS `105`, JS `106`).

- **v1.8** (2026-08-06) — **`run.sh`, `dev.sh` and `verify-server.sh` are idempotent** under a
  concurrent launch (atomic port lock, not check-then-start — the latter was verified to lose the
  race). `dev.sh` reuses an already-serving API instead of starting a second. Bind failures now name
  the port and the `lsof` command instead of printing a Swift trace. See §4.5.

- **v1.7** (2026-08-06) — **R30 completion strings**, plus oracle additions.
  - `accountAllocations[]` gains **`newMonthNote`**, **`onboardingCompletionNote`** and
    **`progressChangeTone`**. Three differences between the two screens, not two: wording,
    structure (replace vs append), **and** condition (New Month is emergency-only). See §2.6.
  - `summary.expensesNegativeDisplay` and `Money.isZero` cover the `-0 RON` sites; the `"+"`
    transfer-row prefixes are guarded the same way.
  - `POST /api/golden/seed` gains `targetCaption`, `savingsStrategy`, `savingsMode`.
  - **Oracle chaining**: `POST /api/golden/seed` accepts **`continuesFrom`** — the base scenario
    **inline**, as a one-element array. Inline rather than a scenario id so the oracle never reads
    `golden-vectors.json` and stays a pure function of its input. The base is replayed in full
    (applying its plan when its own `phase` says to), then the child's `newMonth` runs against the
    resulting balances, with any accounts the child declares layered on top (S16's Joint).
    A base with its own `continuesFrom` recurses. The merged-input form also still works.

    ```json
    { "monthlyIncome": "9000",
      "newMonth": { "income": "9000",
                    "accountBalancesEnteredByUser": { "emergency": "1182.5", "savings": "3547.5" } },
      "continuesFrom": [ { "monthlyIncome": "9000", "phase": "onboarding",
                           "savings": { … }, "accounts": [ … ], "expenses": [ … ] } ],
      "accounts": [], "expenses": [] }
    ```
    Verified: S02 → `2365` / `7095` at `4% → 8%`; S16 (chained + an extra Joint account omitted
    from the reconcile dict) → `jointBalance 5000`, i.e. the R10 guard holding.

- **v1.6** (2026-08-06) — **`DIAMERIS_PORT` / `DIAMERIS_STORE` env vars + `Web/verify-server.sh`**
  (R29), so the Verify harness and the propagation gate run against an isolated instance on 8081
  with a disposable store. Fixes the race where one agent's `POST /api/reset` wiped the store
  another was reading mid-session. `api-propagation-check.py` takes `--base-url` (or
  `DIAMERIS_BASE_URL`). See §4.5.

- **v1.5** (2026-08-06) — two defects found by driving the live app, both in code paths whose only
  shape in `golden-vectors.json` was the degenerate one. Fixed, and now covered by
  `NonDegenerateShapeTests`.
  - **`dashboard.emergencyFund.targetCaption` dropped `(capped at X)`.** `EmergencyProgressCard`
    (`:71-85`) builds **two** captions; with a hard cap set the server was serving only the
    uncapped wording. Now `"Target: 3× monthly income (capped at 20,000 RON)"`. The unreachable
    `?? "Target"` fallback is deleted. Also: the multiplier now renders via `Int(multiplier)`
    (truncating), matching every iOS call site.
  - ⚠️ **`expensesScreen.categories` was missing two of its four grouping steps**, so expenses with
    **no `categoryId` produced no group at all** — the tab rendered its empty state under a
    non-zero header total. Dangling-category groups were missing too. Both now emitted, ordered
    known → dangling → uncategorized.
  - ⚠️ **`ExpenseCategoryGroup` gains `id` and `name`, and `category` is now optional.** See §2.5.

- **v1.4** (2026-08-06) — **`Money.isZero` added** to every money object, for the `-0 RON` guard
  (R28). `display` cannot be used as a zero test in either direction: `-0.004` → `"-0 RON"` and
  `0.4` → `"0 RON"`. Pinned by `NegativeZeroTests`.

- **v1.3** (2026-08-06) — R25–R27 and the last gate items. `api-propagation-check.py`: **28/28,
  exit 0**.
  - ⚠️ **`account.subtitleParts` is now `[{text, tone}]`**, not `string[]` (R27). `tone` ∈
    `secondary` | `accentPrimary` | `accentSecondary`. The leading `"• "` belongs to the part, so
    never split on the bullet. Two source details worth knowing: with a hard cap the third part
    reads `"• 3× income (max 30,000 RON)"` (`SettingsSheet.swift:428-437`), and the multiplier badge
    is gated on `emergencyMultiplier != nil`, **not** on `accountType == "emergency"`.
  - **`reference.savingsConstants` gains `snapThreshold` (0.02)** alongside `step`,
    `accessibilityStep`, `snapValues`, `greatRateRange`.
  - ⚠️ **`reference.savingsConstants.presets` is dead code.** It is `Domain`'s 5-value array and is
    referenced by **no view**; `SavingsSlider` snaps to the **7** values in `snapValues`. Use
    `snapValues`. (Same status as Domain's `recommendationText` — see `DOMAIN-CONTRACT.md §2`.)
  - **`AccountExpenseTransfer.expenseNames: string[]` documented.** It was always on the wire; the
    summary screen's `"for Food, Rent"` caption depends on it.
  - **R25/R26 — `transferPlan.accountAllocations` is an ordered ARRAY and must stay one.** In Split
    mode with the emergency fund at target, the emergency share overflows entirely to savings and
    **the same account appears TWICE** (`+1,182 RON` and `+3,548 RON`), while Emergency Fund is
    absent from the list rather than present with a zero. A client keying rows by `accountId` would
    collapse them and silently lose the second row. `split.actualEmergencyAllocation` /
    `actualSavingsAllocation` **sum** the matching rows for this reason.
  - **R26 — `unallocatedRemainingMoney` is a dev-tools diagnostic, NOT a user warning.** Correcting
    v1.1: do **not** replace the "All amounts add up correctly" banner. We mirror the iOS defect —
    the money vanishes and `isBalanced` stays `true`. A warning iOS doesn't show is a divergence.
    Pinned by `MirroredDefectTests`, which **fails if the values ever reconcile correctly**.
  - **`split` carries both the *requested* and the *resolved* amounts, which legitimately differ.**
    Settings' "Total Monthly" is `requestedTotal` / per-side `resolvedAmount` (unchanged when the
    fund is at target); the transfer plan shows `actual*Allocation` (where the overflow redirects).
    Don't collapse them.

- **v1.2** (2026-08-06) — R7 + R12–R18 propagated; `api-propagation-check.py` reports
  **25/25, 0 outstanding**. Breaking renames are marked ⚠️.
  - **R7 — formatter locale pinned to `en_US`, process-wide.** `editing` is now `"1182.5"`, not
    `"1182,5"`, and grouping/negative form no longer depend on the host machine. ⚠️ **Not
    `en_US_POSIX`** — that locale has grouping *disabled*, so `AmountFormatter`'s forced `","`
    separator had nothing to apply and every amount silently lost its thousands separator
    (`"9000 RON"`). Caught by the ground-truth suite. Implemented by overriding `AppleLocale` in
    `UserDefaults`' volatile argument domain (env vars do **not** work on macOS; Foundation reads
    user defaults), so no change to `Utilities` was needed.
  - **R12 — `reference.expenseIcons` is 37 entries, not 18**, ending at `sparkles`. Plus two new
    and *different* palettes: `reference.categoryIcons` (12) and `reference.categoryColors` (10).
    The grids overlap on only 5 symbols and `calendar` is in the category grid but not the expense
    one, so a shared array breaks a screen.
  - **R13 — `settings.savings.savingsSliderPositions`** (46 entries) and
    **`splitSliderPositions`** (46), each carrying `percentage`, `percent`, `percentDisplay`,
    resolved `savings` money, `isRecommended`, `showsGreatRateBadge`, `isSnapValue`. Dragging is an
    index lookup. `reference.savingsConstants` gains `step` (0.01), `accessibilityStep` (0.05),
    `snapValues` (7 drag-snap targets) and `greatRateRange`.
  - **R18.1 — `settings.savings.split`**: per-side `inputMode`/`percentDisplay`/`resolvedAmount`,
    plus `requestedTotal`, `scaleRatio`, `wasScaledDown`, `actualEmergencyAllocation`,
    `actualSavingsAllocation`. Split percentages resolve against **`availableIncome`, not gross
    income** — 10% of 4,730 is `473`, verified.
  - **R18.2/18.3 — on each emergency `Account`**: `emergencyTargetUncapped`, `isCapActive`, and
    `multiplierOptions` (4 options, each with `"3×"` display, its caption — "Minimum recommended" /
    "Standard protection" / "Enhanced protection" / "Maximum security" — and its own resolved
    `target`/`targetUncapped`). `reference.emergencyMultiplierOptions` replaces
    `emergencyMultiplierRange`.
  - **R14/R18.6 — on every `Account`**: `isReconcilable` (New Month step 2 edits
    `emergency|savings|personal` only) and `wasLastMonthDisplay`.
  - **R18.8 — `account.balanceEditorValue`.** ⚠️ The Settings account editor uses
    `TextField(format: .number)`, **not** `AmountFormatter`, so it groups (`"2,365"`) and shows
    `"0"` rather than blank. `Money.editing` is wrong for that one field — use this.
  - **R18.9 — `reference.accountSuggestions`** (3 chips). ⚠️ The chip labelled **"Emergency"
    creates a `.savings` account**, and all three labels are unlocalized English. Both are real iOS
    bugs, reproduced faithfully and logged in `PARITY-GAPS.md`.
  - **R18 — `settings.savings.boostedPercentDisplay`**, always present (render the row only when
    `boostEnabled`, as `SettingsSheet` does).
  - ⚠️ **R23 — `account.subtitle` is replaced by `account.subtitleParts: string[]`**
    (`["Emergency", "3× income"]`). iOS renders 2–3 inline elements with their own colours and an
    8px gap; it was never one string, so no concatenation is served at all.
  - **R17 — `X-Diameris-Now` request header** (ISO-8601) overrides "now" for
    `dashboard.currentMonthDisplay`, so month-title assertions don't flake at month boundaries.
    Custom categories now tie-break on `createdAt` then `name` (all customs share `sortOrder` 100).
  - **R5 — `PUT /api/categories/:id`** added (409 on a default category).
  - **New: `POST /api/golden/seed`** — the test oracle for `golden-vectors.json`. Takes a scenario
    input verbatim, persists nothing, and returns outputs keyed with the fixture's own
    `expected.raw`/`display`/`percent`/`flags` names.

- **v1.1** (2026-08-06) — implementation complete and verified end to end. Two additions, both
  backwards compatible:
  1. **`POST /api/new-month/preview` gained `unallocatedRemainingMoney`** (`Money | null`) —
     surfaces money that the plan could not place because no account fills the destination role.
     Previously that money was silently dropped from the balance update.
  2. **Documented that `editing` uses the host locale's decimal separator** (§0.1). Discovered by
     a failing test expecting `"1182.5"` and getting `"1182,5"`; the server is faithful to iOS
     here (`GROUND-TRUTH.md` shows `3547,5` on device), so the guidance is: treat `editing` as
     display-only and never parse it.

  3. **Documented the null convention** (top of this doc): null fields are *omitted*, not sent as
     `null`. Type them as optional properties. This corrects v1, which showed `"field": null` in
     examples without saying the key would actually be absent.

  One thing *not* to be surprised by: `transferPlan.summary` groups with the host locale's
  separator (`"Income: 9.000 | ..."` on a comma locale), because `TransferPlan.summary` uses a
  bare `NumberFormatter` without forcing `","` the way `formatForDisplay` does. It is a Domain
  string that no iOS view renders; prefer the individual `Money.display` fields.
