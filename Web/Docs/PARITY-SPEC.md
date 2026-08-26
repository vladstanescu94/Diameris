# PARITY SPEC — Diameris iOS → Web

Screen-by-screen specification of the **shipped iOS app**, derived from source. Every user-visible
string is quoted verbatim as it appears in code (which is also the localization key — see
`LOCALIZATION.md` for the Romanian column). `file:line` references throughout.

**Read alongside:** `DOMAIN-CONTRACT.md` (all calculations), `DESIGN-TOKENS.md` (all visual values),
`LOCALIZATION.md` (EN/RO strings).

**Convention in this document:**
- `"String"` = literal English text in code. Look it up in `LOCALIZATION.md` for the RO value.
- `⚠️ DISCREPANCY` = the code and `Docs/MVP/*.md` disagree; both are stated.
- `HAPTIC: x` = a `HapticManager` call at that interaction. No web equivalent — drop, but keep the
  visual state change.

---

## 0. Global inventory

### 0.1 What actually ships

| Area | Status |
|---|---|
| Onboarding — 7 steps | ✅ implemented |
| Dashboard tab | ✅ implemented (read-only summary) |
| Expenses tab + categories | ✅ implemented (full CRUD) |
| Insights tab | ❌ hardcoded "Coming soon" placeholder |
| New Month flow (3 steps) | ✅ implemented |
| Settings sheet + account editor | ✅ implemented |
| Dev tools | ✅ `#if DEBUG` only |
| **Loans** (`Docs/MVP/06-Loans.md`) | ❌ **entirely absent** — no `Loan` model, view, or repository. The only occurrence of the word is a test expense literally named `"Car Loan"` (`Domain/Tests/DomainTests/ExpenseEntryTests.swift:295-306`). Loans, if wanted, are just ordinary expenses today. |
| **Budget Analysis** (`Docs/MVP/10-BudgetAnalysis.md`) — health score, benchmarks, recommendations, quick summary | ❌ **entirely absent** |
| **Transfer checklist** (`Docs/MVP/09`) — checkboxes, Copy buttons, "How to transfer", `MonthlyTransferStatus` | ❌ absent; replaced by the New Month flow |
| **Savings rate assessment** (`Docs/MVP/07`) — low/moderate/good/veryGood/excellent + recommendations | ❌ absent |
| **Month history** (`MonthlyRecord` model exists) | ❌ never written or read. It is registered in the schema (`DiamerisApp.swift:24`) and `DashboardViewModel.currentMonthRecord` is declared (`:141`) but **never assigned or read** — verified by grep, those are the only two references outside the model file. |
| **Data export / Reset All Data / Privacy Policy / Support / Version** in Settings (`Docs/MVP/11`) | ❌ absent from the shipped Settings sheet (reset exists only in DEBUG dev tools) |
| **Foundation Models / on-device LLM** | ❌ absent; no `FoundationModels` import anywhere |
| **iPad / `NavigationSplitView` / `ViewThatFits`** | ❌ absent — iPhone-only `NavigationStack` |
| **Reduce Motion handling** | ❌ absent — `accessibilityReduceMotion` never read |

⚠️ **DISCREPANCY (structural):** `Docs/MVP/00-MVP-Overview.md:93-103` specifies **4 tabs**
(Dashboard / Budget / Goals / Transfers) + Settings. The code ships **3 tabs**
(Dashboard / Expenses / Insights) + a bottom-accessory "New Month" button + Settings as a sheet.

### 0.2 Haptics map (all 40 sites)

| Method | iOS effect | Call sites |
|---|---|---|
| `HapticManager.lightTap()` | `UIImpactFeedbackGenerator(.light)` | AccountsScreen add/delete/prompt-add ×4, AccountRow expand toggle, togglePrimarySavings, AddAccountSheet add, AccountTypeSelector select ×2, ExpenseRow (n/a), SavingsScreen boost toggle, SavingsSlider snap, RemainingMoneyPicker select, EmergencyMultiplierPicker multiplier, OnboardingButton just-became-enabled, OnboardingSecondaryButton, ExpenseListView add + expandAll + collapseAll + manageCategories, ExpenseCategoryCard expand, ExpenseItemRow tap + contextMenu edit, AddExpenseSheet new-category + cancel, CategoryManagementView done + add, AddCategorySheet icon + colour + cancel |
| `mediumTap()` | `UIImpactFeedbackGenerator(.medium)` | `OnboardingButton` press, `SavingsSlider` drag end, `ExpenseListView` empty-state button |
| `softTap()` | `UIImpactFeedbackGenerator(.soft)` | `WelcomeScreen` on-appear, `NameScreen` 0.5 s after appear |
| `rigidTap()` | `UIImpactFeedbackGenerator(.rigid)` | **never called** |
| `success()` | `UINotificationFeedbackGenerator(.success)` | `TransferPlanScreen` on-appear + complete button, `CompletionCelebration` on-appear, `AddExpenseSheet` save, `AddCategorySheet` add, `MainTabView.handleNewMonthCompletion` |
| `warning()` | `.warning` | `AddExpenseSheet` delete-tap + delete-confirm, `ExpenseItemRow` contextMenu delete, `CategoryManagementView` swipe-delete |
| `error()` | `.error` | **never called** |
| `selectionChanged()` | `UISelectionFeedbackGenerator` | `OnboardingContainerView` on step change, `ExpenseRow` account menu, `EmergencyMultiplierPicker` hard-cap toggle, `FrequencyPicker` change, `CategoryPicker` change, `ExpenseItemRow` toggle |

### 0.3 Global formatting rules

**Money and percentages use two DIFFERENT rounding rules. Do not unify them.** (Agrees with
`GROUND-TRUTH.md` §26 and §35.)

- **Money → half-even (banker's) rounding to 0 decimals.** `AmountFormatter.formatForDisplay` →
  **`"14,303 RON"`**: comma grouping, zero decimals, space, then the *currency code* (never the symbol).
  `NumberFormatter`'s default `roundingMode` is `.halfEven`. JS `Intl.NumberFormat`, `Math.round` and
  `toFixed` all round half-**up** and will disagree on exact `.5` values.
- **Percentages → truncation, never rounding.** Every one is `"\(Int(x * 100))%"`, and Swift's
  `Int(Double)` truncates toward zero. So `0.119` → `11%`, `0.259` → `25%`. Sites: the emergency ring
  and `AccountRow` progress, `progressChangeDisplay` ("86% → 92%"), the expense-breakdown badges, the
  savings slider, and every Settings rate row.
  **Empirically confirmed on device, twice** (`GROUND-TRUTH.md`): the dashboard renders Streaming as
  **2%** where `120 / 4270 = 2.81%` (rounding would give 3%), and the EF ring as **4%** where
  `1182 / 27000 = 4.38%`. Two independent observations where truncation and rounding disagree — so this
  is measured, not inferred from source.
- Money **input** renders via `AmountFormatter.formatForEditing` → no grouping, up to 2 decimals,
  **empty string when the value is 0**. Parsing replaces `,`→`.`; `"1,234"` becomes **1.234**.
- **Storage keeps full `Decimal` precision** — only *display* rounds. A stored `1182.5` shows as
  `1,183 RON` but continues to compound as `1182.5` in every later calculation.
- The Dashboard title is `DateFormatters.monthYear` → `"December 2025"` (locale-formatted).
- No loading state exists anywhere — data is synchronous from SwiftData. No error state is ever shown to
  the user; all `try? context.save()` failures are silent (one `print` in
  `MainTabView.swift:330`).

### 0.3.1 Dark mode — **pure token substitution, no per-screen divergence**

**Assertion, verified by exhaustive grep:** no screen branches on appearance. The codebase contains
**zero** occurrences of `@Environment(\.colorScheme)`, `colorScheme`, or `preferredColorScheme`.
No view has a dark-specific layout, string, icon, spacing or component. Dark mode is produced entirely
by (a) the two adaptive brand colours and (b) SwiftUI/UIKit semantic colours resolving themselves.

So: implement one set of components, swap the token values under
`@media (prefers-color-scheme: dark)`, and you are done. There is no per-screen exception list.

**Backgrounds** are not set by the app — they come from the container, which is why they differ by
screen. This is a system consequence of `Form`/`List` vs `ScrollView`, *not* a dark-mode divergence:

| Screens | Container | Light | Dark |
|---|---|---|---|
| Dashboard, Expenses tab, all 7 onboarding screens, all 3 New Month steps | `ScrollView` in `NavigationStack` → `systemBackground` | `#FFFFFF` | **`#000000`** |
| Settings, AccountEditorSheet, AddExpenseSheet, AddCategorySheet, CategoryPicker | `Form` → `systemGroupedBackground` | `#F2F2F7` | **`#000000`** |
| — its rows/sections | `secondarySystemGroupedBackground` | `#FFFFFF` | `#1C1C1E` |
| CategoryManagementView, DevDebugView | `List` → same grouped pair as above | | |

Dark backgrounds are **pure black `#000000`**, not dark grey — matching the observation in
`13-dashboard-dark.jpg`. Only *grouped* rows lift to `#1C1C1E`. Do not use a grey page background.

**Elements that are intentionally NOT adaptive** — identical bytes in both appearances. These are the
complete list; each is deliberate, so keep them fixed rather than "fixing" them:

| Element | Value | Where | Note |
|---|---|---|---|
| Selected-state text/icons on a coloured fill | `.white` | `AccountTypeSelector:147,151`, `RemainingMoneyPicker:43,49,53,60`, `EmergencyMultiplierPicker:73`, `AddCategorySheet:186` | white on accentSecondary / orange — legible in both modes |
| Savings slider thumb | `Circle().fill(.white)` | `SavingsSlider:102` | stays pure white on black in dark mode |
| Savings slider thumb shadow | `.black.opacity(0.15)`, radius 4, y 2 | `SavingsSlider:104` | ⚠️ the app's **only** shadow, and it is effectively invisible against the `#000000` dark background. Reproduce as-is for parity; do not substitute a light shadow. |
| The 8 default category colours | fixed hexes `#3B82F6`…`#06B6D4` | `Domain/Entities/Category.swift` | no dark variants — category icons render identically |
| The 10 custom-category swatches | fixed hexes | `CategoryManagementView:120-131` | same |

Everything else resolves automatically: `.primary`, `.secondary`, `.tertiary`, `.green`, `.orange`,
`.red`, `.yellow`, `.purple`, `.pink`, `.cyan`, `.accentColor`, and every `.opacity()` derived from
them, plus `.glassEffect` itself. Their light/dark values are tabulated in `DESIGN-TOKENS.md §1.2-1.3`.

(`CelebrationEffect.swift:206`'s `Color.black.opacity(0.1)` is inside a `#Preview` block and does not
ship — excluded from the table above.)

---

## 1. App root & launch gating

`Diameris/AppDelegate/DiamerisApp.swift:44-90`

- Single `WindowGroup` → `RootView`, with the shared `ModelContainer` (7 models, on-disk).
- `RootView` is a `ZStack`:
  - `MainTabView()` shown when `showMainTab == true`, `.transition(.opacity)`
  - `OnboardingContainerView` overlaid when `!onboardingCompleted`, `.transition(.opacity)`
- `onboardingCompleted` is `@AppStorage("onboardingCompleted")`, default `false`.
- Cross-fade animation: `.easeInOut(duration: AnimationDuration.medium /* 0.4 s */)` on both
  `onboardingCompleted` and `showMainTab` (`:62-63`).
- `onAppear`: if already completed, set `showMainTab = true` immediately (no animation on first paint).
- `onChange(onboardingCompleted)`: if it flips to `false` (dev reset), set `showMainTab = false`.
- **Completion sequence** (`:78-89`), reproduce the ordering:
  1. `KeyboardHelper.dismiss()`
  2. `await 100 ms`
  3. `showMainTab = true`  ← main UI fades in *under* the still-visible onboarding
  4. `await 50 ms`
  5. `onboardingCompleted = true` ← onboarding fades out
  On web: no keyboard delay needed, but keep the ~150 ms overlap so the cross-fade reads the same.

**Web:** `localStorage["onboardingCompleted"]`.

---

## 2. Onboarding

### 2.0 Container — `Onboarding/Views/OnboardingContainerView.swift`

> ### ⚠️ 7 screens, 5 dots — both numbers are correct
>
> This trips everyone. There are **7 onboarding screens**, and the progress indicator has **5 dots**.
> The indicator deliberately covers only the middle five, because the first and last screens hide it
> entirely (`OnboardingContainerView.swift:82-88`:
> `currentStep != .welcome && currentStep != .transferPlan`).
>
> | Screen | rawValue | Indicator | Dot |
> |---|---|---|---|
> | 1. Welcome | 0 | **hidden** | — |
> | 2. Name | 1 | shown | 1 of 5 |
> | 3. Income | 2 | shown | 2 of 5 |
> | 4. Accounts | 3 | shown | **3 of 5** |
> | 5. Expenses | 4 | shown | 4 of 5 |
> | 6. Savings | 5 | shown | **5 of 5** |
> | 7. Transfer Plan | 6 | **hidden** | — |
>
> Matches the screenshots exactly (accounts = dot 3 of 5, savings = dot 5 of 5, welcome and the final
> screen show no indicator). The arithmetic behind it: `totalSteps` is passed as
> `allCases.count - 2` = **5** (`OnboardingContainerView.swift:76`) and the dot index is
> `max(0, rawValue - 1)` (`OnboardingProgressIndicator.swift:13-15`) — subtracting welcome from the
> front and transferPlan from the back.
>
> Note screen 7 reaches dot "5 of 5" only conceptually — the bar is already full at Savings and then
> disappears. **There is no 6th or 7th dot, and no "Step X of 7" text anywhere.** `GROUND-TRUTH.md`
> previously said "5 steps" while listing 7 screens; both halves were right, and this table is the
> reconciliation.

- `NavigationStack` wrapping the current step, with a toolbar containing **only** the progress indicator
  at `.principal` placement.
- Steps enum (`OnboardingViewModel.swift:35-43`), `allCases` order **is** the flow order:

  | rawValue | case | Screen | Name used in `GROUND-TRUTH.md` |
  |---|---|---|---|
  | 0 | `welcome` | §2.1 | Welcome |
  | 1 | `name` | §2.2 | Name |
  | 2 | `income` | §2.3 | Income |
  | 3 | `accounts` | §2.4 | Accounts |
  | 4 | `expenses` | §2.5 | Expenses |
  | 5 | `savings` | §2.6 | Savings |
  | 6 | `transferPlan` | §2.7 | **"summary"** — same screen; the code's case name is `transferPlan` |

- **There is no Back button and no back navigation.** `advance()` only moves forward
  (`OnboardingViewModel.swift:60-66`); nothing decrements `currentStep`.
  ⚠️ **DISCREPANCY:** `Docs/MVP/01-Onboarding.md:295` requires "**Back navigation:** Allow going back to
  previous steps".
- Toolbar visibility: `.visible` only when `currentStep != .welcome && != .transferPlan`, else `.hidden`
  (`:82-88`).
- Tapping anywhere on the container dismisses the keyboard (`:23-24`).
- `HAPTIC: selectionChanged()` on every step change (`:25-27`).
- Screen transition: `.animation(SpringPreset.smooth /* response .5, damping .8 */, value: currentStep)`
  with the asymmetric transition in `DESIGN-TOKENS.md §7.5`.
- Each screen is keyed `.id(viewModel.currentStep)` so it is fully rebuilt (entrance animations re-run).

**`advance()` behaviour** (`:51-58`): dismisses the keyboard, waits **150 ms**, *then* changes the step.
On web the delay is unnecessary; skip it.

**`canAdvance` per step** (`:72-89`):

| Step | Rule |
|---|---|
| `welcome` | always `true` |
| `name` | `1 <= trimmedName.count <= 50` (whitespace/newline-trimmed) |
| `income` | `monthlyIncome > 0` |
| `accounts` | `accounts.contains { $0.isPrimary }` |
| `expenses` | always `true` |
| `savings` | always `true` |
| `transferPlan` | always `true` |

No inline error messages exist anywhere in onboarding — the Continue button is simply disabled
(dimmed to `Opacity.dimmed` = 0.7).
⚠️ **DISCREPANCY:** `Docs/MVP/01-Onboarding.md:319-321` requires "Real-time validation with inline
errors" and "Clear error messages".

### 2.0.1 Progress indicator — `Components/OnboardingProgressIndicator.swift`

- `totalSteps` passed in = `OnboardingStep.allCases.count - 2` = **5**
  (`OnboardingContainerView.swift:76`).
- `adjustedStepIndex = max(0, currentStep.rawValue - 1)` → name=0 … savings=4.
- `progress = adjustedStepIndex / (totalSteps - 1)` → 0, 0.25, 0.5, 0.75, 1.0.
- Layout, `ZStack(alignment: .leading)`, frame **280 × 24**:
  1. Track: `Capsule`, `Color.secondary.opacity(0.3)`, 280 × **4**
  2. Fill: `Capsule`, brand gradient (leading→trailing), width `280 * (progress + 0.05)`, height 4
     — the `+0.05` guarantees a visible sliver at step 1
  3. Dots: `HStack(spacing: 0)` with `Spacer()` between, total width 280. Per dot:
     - `isCompleted = index <= adjustedStepIndex` → fill `accentPrimary`, else `secondary.opacity(0.3)`
     - `isCurrent` → diameter **12** (else **8**), scale `1.10`, plus an 18 pt ring
       `stroke(accentPrimary.opacity(0.5), lineWidth: 2)`
     - dot animation `SpringPreset.snappy`
- Container animation `SpringPreset.responsive` on `currentStep`.
- **No "Step X of 6" text** anywhere. ⚠️ **DISCREPANCY:** `Docs/MVP/01-Onboarding.md:294` requires
  "Show step X of 6"; the code shows 5 dots and no text.

### 2.0.2 Shared onboarding components

**`OnboardingHeader`** — `Components/OnboardingHeader.swift`
`VStack(spacing: Spacing.md /*16*/)`: icon → title → optional subtitle.
- Icon: `iconXxl()` (64 pt) or `iconHero()` (80 pt) when `useHeroIcon`; tinted by `iconColor`;
  `.symbolEffect(.bounce, value: iconAppeared)`; starts at scale `0.3` / opacity 0.
- Title: `.largeTitle` if `useHeroIcon` else `.title`, `.bold`, centred, wraps; slides up 15 pt.
- Subtitle: `.subheadline`, `.secondary`, centred, wraps; slides up 10 pt.
- Entrance: icon `SpringPreset.bouncy` (no delay) → title `SpringPreset.responsive.delay(0.1)` →
  subtitle `SpringPreset.smooth.delay(0.2)`.
- `accessibilityElement(children: .combine)`.

**`OnboardingButton`** — `Components/OnboardingButton.swift:6-40`
`.buttonStyle(.glassProminent)`, label `.headline`, `frame(maxWidth: .infinity, minHeight: 50)`.
`opacity = isEnabled ? 1.0 : 0.7`; `.disabled(!isEnabled)`.
`HAPTIC: mediumTap()` on press (fires **before** the action).
`HAPTIC: lightTap()` when `isEnabled` transitions false→true.

**`OnboardingSecondaryButton`** (`:43-63`) — `.buttonStyle(.glass)`, label `.subheadline`, same
`maxWidth`/`minHeight: 50`. `HAPTIC: lightTap()`.

**`OnboardingTextField`** — `Components/OnboardingTextField.swift`
`VStack(alignment: .leading, spacing: Spacing.xs /*8*/)`: optional title (`.subheadline`, `.secondary`,
hidden when empty) → `TextField(prompt, text:)` with `.title3`, `padding(16)`,
`.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))`.
`textInputAutocapitalization` = `.words` when keyboardType is `.default`, else `.never`.

---

### 2.1 Welcome — `Views/WelcomeScreen.swift`

Root: `VStack(spacing: Spacing.xl /*32*/)`, `padding(Spacing.lg /*24*/)`.

**Order:** `Spacer` → hero icon → content → value bullets → `Spacer` → CTA.

1. **Hero icon** (`:32-62`), `accessibilityHidden`:
   - glow: `Circle` `accentPrimary.opacity(0.2)`, 140×140, `blur(20)`, scale 0.5→1, fade in
   - container: `Circle` `accentPrimary.opacity(0.15)` 120×120 + `sparkles` glyph at 80 pt,
     `accentPrimary`, `.symbolEffect(.pulse, options: .repeating)` (infinite)
   - both scale 0.3→1, opacity 0→1
2. **Content** (`VStack spacing 16`, `padding(.horizontal, 16)`):
   - Title `.largeTitle .bold`, centred: **"Take control of your money"**
   - Subtitle `.title3`, `.secondary`, centred, wraps: **"In the next few minutes, we'll build your personalized transfer plan — so payday becomes effortless."** (note the em dash `—`)
3. **Value bullets** (`VStack(alignment: .leading, spacing: 16)`, `padding(.horizontal, 24)`).
   Each bullet: `HStack(spacing: 12)` of a 24 pt-wide icon (`.body`, tinted) + `.subheadline .secondary` text.
   Entrance: `SpringPreset.responsive.delay(d)`, sliding in from `x: -15`.

   | # | icon | colour | text | delay |
   |---|---|---|---|---|
   | 1 | `target` | accentSecondary | "Set savings goals that fill automatically" | 0.1 |
   | 2 | `arrow.left.arrow.right` | accentPrimary | "Know exactly where to transfer your money" | 0.2 |
   | 3 | `chart.line.uptrend.xyaxis` | accentSecondary | "Watch your progress grow" | 0.3 |
4. **CTA**: `OnboardingButton("Let's Go", isEnabled: true)` → `advance()`. Slides up 20 pt.

**Entrance timing** (`:145-159`): icon `bouncy.delay(0.3)`; content `smooth.delay(0.3 + 0.2 = 0.5)`;
button `responsive.delay(0.3 + 0.4 = 0.7)`. `HAPTIC: softTap()` immediately.

⚠️ **DISCREPANCY:** `Docs/MVP/01-Onboarding.md:33-39` specifies "Welcome to Diameris" /
"Your personal budget planner" / "Let's set up your budget in just a few steps." / button
"Get Started". **None of those strings ship.**

---

### 2.2 Name — `Views/NameScreen.swift`

`VStack(spacing: 32)`, `padding(24)`. Order: `Spacer` → header → text field → `Spacer` → Continue.

- Header: icon `person.circle.fill` (accentPrimary), title **"First, let's get acquainted"**,
  subtitle **"What should we call you?"**
- Field: `OnboardingTextField("", text: $viewModel.name, prompt: "Your name")` — no visible title label.
  `.submitLabel(.continue)`; pressing return advances **if** `canAdvance`.
- Continue: `OnboardingButton("Continue", isEnabled: canAdvance)`;
  `accessibilityHint("Continues to the next step")`.
- Entrance: `SpringPreset.smooth.delay(0.3)` for field + button (slide up 20 pt).
  `HAPTIC: softTap()` at `+0.5 s` via `DispatchQueue.main.asyncAfter`.
- **Focus is not auto-set** (`@FocusState isNameFocused` is declared and bound but never set to `true`).

⚠️ **DISCREPANCY:** Doc specifies title "What should we call you?" and helper "We'll use this to
personalize your experience." — code uses "What should we call you?" as the *subtitle* and has no helper.

---

### 2.3 Income — `Views/IncomeScreen.swift`

`VStack(spacing: 32)`, `padding(24)`. Order: `Spacer` → header → input section → helper → `Spacer` → Continue.

- Header: icon `banknote.fill` (accentSecondary);
  title = interpolated **"Nice to meet you, \(trimmedName)!"**;
  subtitle **"How much lands in your account each month after taxes?"**
- Input section (`VStack(alignment: .leading, spacing: 8)`):
  - Label `.subheadline .secondary`: **"Monthly net income"**
  - `CurrencyAmountField(amount: $monthlyIncome, currency: $currency)` — **with** the currency picker
    (this is the only place the user can change currency during onboarding).
    `accessibilityLabel("Monthly income amount")`
- Helper `.caption .secondary`, centred, wraps: **"This is your starting point — we'll help you decide where every unit goes."**
- Continue: `OnboardingButton("Continue", isEnabled: monthlyIncome > 0)`;
  `accessibilityHint("Continues to the expenses step")` — ⚠️ wrong hint, the next step is Accounts.
- Entrance: `SpringPreset.smooth.delay(0.3)`.
- **No maximum-amount validation.** ⚠️ Doc caps income at 1,000,000 (`01:112`) / 10,000,000 (`02:213`).

**`CurrencyAmountField`** — `SharedUI/Components/CurrencyAmountField.swift`
`HStack(spacing: 12)` → `padding(16)` → `.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))`
- **With picker** (`showCurrencyPicker: true`): a `Menu` (`.buttonStyle(.glass)`) labelled
  `currency.rawValue` (`.headline`) + `chevron.up.chevron.down` (`.caption`). Menu items are
  `Currency.allCases` shown by `displayName` → "Romanian Leu (RON)", "Euro (EUR)", "US Dollar (USD)".
  `accessibilityLabel("Currency: \(displayName)")`, `accessibilityHint("Double tap to change currency")`.
- **Without picker**: plain `Text(currency.rawValue)` `.headline` with `padding(.horizontal, 12)`.
- Amount field: `TextField("0", …)` `.title2 .semibold`, `keyboardType(.decimalPad)`,
  `multilineTextAlignment(.trailing)`, `accessibilityLabel("Amount")`.
  On appear, seeds text from `formatForEditing(amount)` **only if `amount > 0`**.
  On every keystroke: `amount = AmountFormatter.parse(text)`.

---

### 2.4 Accounts — `Views/AccountsScreen.swift`

`ScrollView` → `VStack(spacing: 32)`, `padding(24)`, `.scrollIndicators(.hidden)`.

**Order:** header → Your Accounts → Recommended → helper → Continue.

1. **Header**: icon `building.columns.fill` (accentSecondary), title **"Where does your money live?"**,
   subtitle **"Set up your accounts. We recommend an emergency fund and savings account."**
2. **Your Accounts** (`VStack(alignment: .leading, spacing: 16)`):
   - `Text("Your Accounts").font(.headline)`
   - One `AccountRow` per account (see §2.4.1), staggered `responsive.delay(index * 0.1)`, sliding up 15 pt
   - `Button` `.buttonStyle(.glass)`: `Label("Add Another Account", systemImage: "plus.circle.fill")`
     `.subheadline`; `accessibilityHint("Opens a sheet to add a new account")`; `HAPTIC: lightTap()`
3. **Recommended** (`:136-231`) — only the prompts still needed:
   - `Text("Recommended").font(.headline).foregroundStyle(.secondary)` shown when either prompt shows;
     `.transition(.opacity.animation(.easeOut(0.25)))`
   - `GlassEffectContainer(spacing: 24)` wrapping a `VStack(spacing: 16)`:
     - **Emergency prompt** (`glassEffectID "emergencyPrompt"`), shown when `!hasEmergencyAccount`.
       Card = `VStack(alignment:.leading, spacing:12)`, `padding(16)`,
       `.glassEffect(in: .rect(cornerRadius: 16))`:
       - Row: `shield.fill` (accentSecondary) + `Text("Emergency Fund").subheadline.medium` + `Spacer` +
         `Button("Add")` `.caption`, `.buttonStyle(.glassProminent)`, `.tint(accentPrimary)`,
         `.disabled(hasEmergencyAccount)`
       - `Text("Protects you from unexpected expenses. Recommended: 3-6 months of income.").caption.secondary`
       - Tap Add → append `.emergency(multiplier: 3.0)`, guarded against double-add,
         `withAnimation(.bouncy)`, `HAPTIC: lightTap()`
     - **Savings prompt** (`glassEffectID "savingsPrompt"`), shown when `!hasPrimarySavingsAccount`.
       Same structure: `banknote.fill`, `Text("Savings Account")`, `Button("Add")`,
       `Text("Build wealth over time. After emergency fund is full, savings go here.")`.
       Tap Add → append `.savings(isPrimarySavings: true)`.
   - When a prompt is satisfied it disappears and the container **morphs** the remaining card
     (glassEffectID). On web: animate the container height + cross-fade the removed card.
4. **Helper**: `HStack(spacing: 8)` `info.circle` `.caption` (accentSecondary) +
   `Text("Your primary account is where your salary lands").caption.secondary`
5. **Continue**: `OnboardingButton("Continue", isEnabled: accounts.contains(\.isPrimary))`,
   `padding(.top, 32)`

**Entrance** (`:346-358`): content `smooth.delay(0.3)`; accounts `responsive.delay(0.5)`;
prompts `responsive.delay(0.6)`.

**Mutation rules** (`:260-340`) — reproduce exactly:
- `addAccount(name:type:)` — returns early if `type == .emergency && hasEmergencyAccount`.
  If emergency → `emergencyMultiplier = 3.0`. If savings **and** no primary savings yet →
  `isPrimarySavings = true`.
- `handleTypeChange(accountId:newType:)` — returns early if changing to `.emergency` while one exists.
  Then: set type; if emergency → `multiplier = 3.0`, else `multiplier = nil` **and** `hardCap = nil`.
  If savings and no primary savings → `isPrimarySavings = true`; if not savings → `isPrimarySavings = false`.
  ⚠️ Note the guard reads `viewModel.hasPrimarySavingsAccount` **during** the mutation closure, so
  changing the *current* primary-savings account to savings again keeps it primary.
- `togglePrimarySavings(accountId:)` — clears `isPrimarySavings` on **all** accounts, then sets it on the
  target. `HAPTIC: lightTap()`.
- `deleteAccount(id:)` — `removeAll { $0.id == id }`. Delete button is `nil` (hidden) for the primary
  account, so the primary can never be removed. `withAnimation(SpringPreset.responsive)`,
  `HAPTIC: lightTap()`.

#### 2.4.1 `AccountRow` — `Components/AccountRow.swift`

`GlassEffectContainer(spacing: 0)` → `VStack(spacing: 0)` → `.glassEffect(in: .rect(cornerRadius: 16))`,
`glassEffectID("card-\(account.id)")`. `accessibilityElement(children: .combine)`.

**Main row** (`HStack(spacing: 16)`, `padding(16)`, whole row tappable):
- Icon: `ZStack` of `Circle().fill(accountType.color.opacity(0.15))` 44×44 + the type glyph `.title3`
  in `accountType.color`. `accessibilityHidden`.
- Content (`VStack(alignment:.leading, spacing: 4)`):
  - **Name**: `Text(account.name).font(.headline)`. **Tapping the name enters inline edit**, replacing it
    with `TextField("Account name", text:)` `.headline`, `.textFieldStyle(.plain)`; `onSubmit` commits
    and exits edit mode. ⚠️ There is no cancel/blur commit — tapping elsewhere leaves the field open with
    uncommitted text.
  - Badges (only when displaying, not editing), each `.transition(.opacity.animation(.easeOut(0.25)))`:
    - `isPrimary` → `Text("Primary")` `.caption2 .medium`, `accentPrimary`, `padding(.horizontal, 8)`,
      `padding(.vertical, 2)`, `accentPrimary.opacity(0.15)` background, `Capsule`
    - `isPrimarySavings` → `Text("Auto-Save")`, same but `accentSecondary`
  - **Type selector**: `AccountTypeSelector(compact: true, disableEmergency: hasExistingEmergency)`
- Trailing (`HStack(spacing: 12)`):
  - `chevron.down` `.caption .secondary`, rotates 180° when expanded, `.easeOut(0.25)` — shown **only**
    for `emergency` / `savings` types
  - Delete `Button` → `xmark.circle.fill` `.secondary`, `.buttonStyle(.plain)`,
    `accessibilityLabel("Remove \(account.name)")` — hidden when `onDelete == nil` (primary account)

**Tap on the main row** toggles expansion (`withAnimation(.bouncy)`, `HAPTIC: lightTap()`) — but only if
`accountType == .emergency || .savings`.

**Expanded content** — `Divider().padding(.horizontal, 16)` then a `VStack(spacing: 16)` with
`padding(.horizontal, 16)` and `padding(.bottom, 16)`:

*If emergency:*
1. `Text("Target: months of income").caption.secondary` + `EmergencyMultiplierPicker` (§2.4.2)
2. `Text("Current balance").caption.secondary` + `BalanceInputField`:
   `HStack(spacing: 12)` of `Text(currency)` `.subheadline .medium .secondary` +
   `TextField("0")` `.subheadline`, `.decimalPad`, trailing-aligned; `padding(12)`,
   `Color.secondary.opacity(0.1)` background, radius 8. Seeds from `formatForEditing` if `> 0`.
3. If `emergencyProgress != nil`: progress block —
   `HStack` of `Text("Progress").caption.secondary` + `Spacer` +
   `Text("\(Int(progress*100))%")` `.caption .medium`, coloured **green if `>= 1.0` else orange**,
   `.contentTransition(.numericText())`; then `ProgressView(value: progress)` tinted the same,
   `.easeOut(0.25)`.

*If savings:*
- When **not** primary savings: a `Button` (`.buttonStyle(.plain)`) row —
  `star.fill` (yellow) + `Text("Set as Primary Savings").subheadline` + `Spacer` +
  `chevron.right` `.caption .secondary`
- When primary savings: `HStack(spacing: 8)` `checkmark.circle.fill` (green) +
  `Text("This account receives automatic savings").caption.secondary`

**Accessibility label** (`:333-349`) is built as
`"<name>, <typeDisplayName>"` + `", primary account"` + `", primary savings"` +
`", target <formatted>"` (⚠️ these three suffixes are **hardcoded English**, not localized).

#### 2.4.2 `EmergencyMultiplierPicker` — `Components/EmergencyMultiplierPicker.swift`

`VStack(spacing: 12)`: segmented picker → target display → hard-cap section.

- **Multiplier buttons**: `HStack(spacing: 8)` over **`[3.0, 4.0, 5.0, 6.0]`**. Each is
  `Text("\(Int(option))×")` (note the multiplication sign `×`, U+00D7) `.subheadline`,
  weight `.semibold` when selected else `.regular`, colour `.white` when selected else `.primary`,
  `maxWidth: .infinity`, `padding(.vertical, 12)`, background
  `RoundedRectangle(8).fill(selected ? Color.orange : .clear)`. `.buttonStyle(.plain)`,
  `withAnimation(SpringPreset.responsive)`, `HAPTIC: lightTap()`.
  ⚠️ **DISCREPANCY:** `Docs/MVP/05-EmergencyFund.md:89-91` and `11-Settings.md:233` specify a
  **1–12** range with stops **1 / 2 / 3 / 6 / 12**. The code ships **3 / 4 / 5 / 6**.
- **Target display** row:
  - `Text("Target:").caption.secondary`
  - If the cap is *active* (`cap < calculated`): the calculated target `.caption` **strikethrough**
    `.secondary`, then the effective target `.caption .medium` in **orange**
  - Else just the effective target `.caption .medium` orange
  - `.contentTransition(.numericText())`, `.easeOut(0.25)` on both `multiplier` and `hardCap`
  - `Spacer`, then `multiplierDescription` `.caption .secondary`, `lineLimit(1)`,
    `minimumScaleFactor(0.8)`, `.contentTransition(.interpolate)`:

    | multiplier | text |
    |---|---|
    | 3.0 | "Minimum recommended" |
    | 4.0 | "Standard protection" |
    | 5.0 | "Enhanced protection" |
    | 6.0 | "Maximum security" |
    | other | `""` |
- **Hard cap section**:
  - `Toggle` labelled `Text("Set maximum").subheadline`, `.tint(.orange)`,
    `accessibilityHint("Caps the emergency fund target at a fixed amount")`.
    On enable: `hardCap = calculatedTarget` and the text field seeds to that value.
    On disable: `hardCap = nil`, text cleared. `withAnimation(SpringPreset.responsive)`,
    `HAPTIC: selectionChanged()`.
  - When enabled: `HStack(spacing: 12)` of `Text("Max:").caption.secondary` +
    a boxed input (`padding(12)`, `secondary.opacity(0.1)`, radius 8) containing
    `TextField("0")` `.subheadline`, `.decimalPad`, trailing-aligned,
    `accessibilityLabel("Maximum amount")`, then `Text(currency).subheadline.secondary`.
    **On every keystroke:** `hardCap = parsed > 0 ? parsed : nil`, and **if `parsed <= 0` the toggle
    turns itself off**. `.transition(.opacity.combined(with: .move(edge: .top)))`.

#### 2.4.3 `AccountTypeSelector` — `Components/AccountTypeSelector.swift`

**Compact (used in `AccountRow`)**: a `Menu` (`.buttonStyle(.plain)`) whose label is a pill —
`HStack(spacing: 8)` of the selected type's glyph `.caption` (accentSecondary), the
`displayName` `.caption .primary` (`lineLimit(1)`, `fixedSize`), and `chevron.up.chevron.down`
`.caption2 .secondary`; `padding(.horizontal, 12)`, `padding(.vertical, 8)`,
background `Capsule().fill(Color.secondary.opacity(0.1))`.
`accessibilityLabel("Account type")`, `accessibilityValue(displayName)`.
Menu items: all 6 `AccountType` cases as `Label(displayName, systemImage: icon)`.
When `disableEmergency`, the Emergency item is rendered **disabled** with the label
**`"\(displayName) (only one allowed)"`** — ⚠️ built by string interpolation, so the
`" (only one allowed)"` suffix is **not localized**.
`HAPTIC: lightTap()` on selection.

**Full (used in `AddAccountSheet`)**:
- `Text("Account type").subheadline.secondary`
- `LazyVGrid` 2 flexible columns, spacing 12. Each cell is an `AccountTypeButton`:
  `VStack(spacing: 8)` of glyph `.title3` → `displayName` `.caption .medium` →
  `description` `.caption2`, `lineLimit(2)`, centred. `maxWidth: .infinity`, `padding(12)`,
  background `RoundedRectangle(12)`.
  - Selected: fg `.white`, description `.white.opacity(0.8)`, bg `accentSecondary`
  - Unselected: fg `accentSecondary`, description `.secondary`, bg `Color.secondary.opacity(0.1)`
  - Disabled: `opacity(0.5)`, `.disabled(true)`,
    `accessibilityHint("Only one emergency account allowed")`
  - `accessibilityAddTraits(.isSelected)` when selected

#### 2.4.4 `AddAccountSheet` — `Components/AddAccountSheet.swift`

Presented from "Add Another Account". `NavigationStack` → `ScrollView` →
`VStack(alignment: .leading, spacing: 24)`, `padding(24)`, `.scrollIndicators(.hidden)`.
`navigationTitle("Add Account")`, `.navigationBarTitleDisplayMode(.inline)`,
`.presentationDetents([.medium])` → **modal at ~50 % height**.

Order:
1. `OnboardingTextField("Account Name", text: $accountName, prompt: "e.g., Joint Account")`
2. `AccountTypeSelector(compact: false)` — initial selection **`.other`**
3. Quick suggestions: `Text("Quick suggestions").caption.secondary` then `HStack(spacing: 12)` of three
   `.buttonStyle(.glass)` chips with `.caption` labels:

   | chip title | sets accountType to |
   |---|---|
   | `Joint` | `.joint` |
   | `Emergency` | **`.savings`** ⚠️ **BUG** — an "Emergency" chip that creates a *savings* account (`:65`) |
   | `Travel` | `.savings` |

   ⚠️ Chip titles are **raw literals, not localized** (`:61-72`).
   Tapping a chip sets both the name **and** the type.

Toolbar: `.cancellationAction` → `Button("Cancel")`; `.confirmationAction` → a `Button` whose label is
`Image(systemName: "plus")`, `.buttonStyle(.glassProminent)`, `.tint(accentPrimary)`,
`.disabled(trimmedName.isEmpty)`.
Add → `onAdd(trimmedName, accountType)`, `HAPTIC: lightTap()`, then dismiss (which resets
`accountName = ""` and `accountType = .other`).

⚠️ **DISCREPANCY:** `Docs/MVP/01-Onboarding.md:191-203` / `08-Accounts.md:160-181` specify a
**"Purpose (optional)"** field in this sheet. The code has none — `purpose` is only ever set by the
static factories.

---

### 2.5 Expenses (onboarding) — `Views/ExpensesScreen.swift`

`ScrollView` → `VStack(spacing: 32)`, `padding(24)`, `.scrollIndicators(.hidden)`.

**Order:** header → expenses list → impact display → helper → action buttons.

1. **Header**: icon `creditcard.fill` (accentPrimary), title **"Where does your money go?"**,
   subtitle **"A quick look at your main expenses. Don't worry about being exact — estimates are fine."**
2. **Expenses list**: `GlassEffectContainer` → `VStack(spacing: 12)` of one `ExpenseRow` per seeded
   expense. Fixed 4 rows (see `DOMAIN-CONTRACT.md §6`): Food/`cart.fill`, Rent/`house.fill`,
   Gas/`fuelpump.fill`, Streaming/`tv.fill`. Each row fades+slides in from `x: +30` with
   `responsive.delay(0.3 + index*0.1)`.
   `accessibilityElement(children: .contain)`, `accessibilityLabel("Expense categories")`.
   ⚠️ `rowsAppeared` is a fixed 4-element array (`:10`) — a 5th expense would never animate in.
3. **Impact display** — shown **only if `monthlyIncome > 0`** (`:74-88`).
   `VStack(spacing: 12)`, `maxWidth: .infinity`, `padding(16)`, radius 12,
   background `accentSecondary.opacity(0.1)` when `availableForGoals > 0` else `Color.orange.opacity(0.1)`.
   `.animation(.smooth, value: availableForGoals)`.
   - Header row: `HStack(spacing: 8)` glyph — `arrow.right.circle.fill` (accentSecondary) if positive,
     else `exclamationmark.triangle.fill` (orange) — + `Text("After expenses").subheadline.secondary`
   - Amount row: `HStack(alignment: .firstTextBaseline, spacing: 8)` —
     formatted `availableForGoals` `.title2 .bold`, coloured accentSecondary/orange,
     `.contentTransition(.numericText())`; then `Text("available for your goals").subheadline.secondary`
   - `availableForGoals = max(0, monthlyIncome - Σ expense.amount)` (`:36-38`)
4. **Helper**: `info.circle` `.caption .secondary` +
   `Text("By default, expenses are paid from your main account").caption.secondary`
5. **Action buttons** (`VStack(spacing: 12)`, `padding(.top, 32)`):
   - `OnboardingButton("Continue", isEnabled: true)`;
     `accessibilityHint("Continues to the accounts step")` — ⚠️ wrong, accounts came before
   - `OnboardingSecondaryButton("Skip for now")` → see the exact semantics below;
     `accessibilityHint("Skips expense entry and continues")`

> ### "Skip for now" — exact resulting state (the two buttons do DIFFERENT things)
>
> Only **two** screens have a skip button — expenses and savings (verified: those are the only two
> `OnboardingSecondaryButton` call sites in `Views/`). **Neither jumps to the summary**; both call
> `advance()`, which moves exactly **one** step (`OnboardingViewModel.swift:60-66`).
>
> **Expenses skip** (`ExpensesScreen.swift:136-141`):
> ```
> for index in viewModel.expenses.indices { viewModel.expenses[index].amount = 0 }
> viewModel.advance()          // → savings
> ```
> - The 4 seeded rows are **kept in memory** with `name`, `icon` and `categoryId` intact; only `amount`
>   is forced to `0`. (They are already 0 unless the user typed something — so skip's real effect is to
>   **discard anything already entered**.)
> - At save time, `for expense in expenses where expense.amount > 0` (`OnboardingViewModel.swift:178`)
>   means **zero `Expense` rows are persisted**. So: kept at 0 in memory, discarded on write.
> - Net effect on the plan: `totalExpenses = 0`, so `availableIncome == income`.
>
> **Savings skip** (`SavingsScreen.swift:481-484`):
> ```
> viewModel.savingsAllocation = SavingsAllocationEntry()   // fresh defaults
> viewModel.advance()          // → transferPlan
> ```
> - ⚠️ **Savings does NOT become 0.** It is *reset to the defaults*: `percentage = 0.25`,
>   `allocationMode = .prioritized`, `savingsInputMode = .percentage`, `boostEnabled = false`
>   (`DOMAIN-CONTRACT.md §2`). **Skipping the savings screen still saves 25 % of available income.**
> - Like the expenses skip, its real effect is **destructive**: any slider/mode/boost changes the user
>   made on that screen are thrown away and replaced by 25 % prioritized.
> - A `SavingsAllocation` row **is** persisted, carrying those defaults.
>
> So the two buttons are asymmetric: one zeroes its data, the other restores a non-zero default. Both
> are "discard my edits", neither is "opt out of the feature".

**Entrance** (`:151-165`): rows `responsive.delay(0.3 + i*0.1)`; content `smooth.delay(0.5)`;
impact `bouncy.delay(0.5 + 0.1 = 0.6)`.

#### 2.5.1 `ExpenseRow` (onboarding) — `Components/ExpenseRow.swift`

`VStack(spacing: 8)`, `padding(16)`, `.glassEffect(in: .rect(cornerRadius: 12))`,
`accessibilityElement(children: .combine)`.

- **Main row** `HStack(spacing: 16)`: glyph `.title3 .secondary` in a 32 pt-wide frame
  (`accessibilityHidden`) → `Text(name).font(.body)` `lineLimit(1)` `minimumScaleFactor(0.8)` →
  `Spacer(minLength: 12)` → `HStack(spacing: 8)` of `Text(currency.rawValue).subheadline.secondary`
  + `TextField("0")` `.body .medium`, `.decimalPad`, trailing-aligned, **width 60**,
  `accessibilityLabel("\(name) amount")`.
- **Account selector** — rendered only when `!accounts.isEmpty`. A `Menu` (`.buttonStyle(.glass)`)
  labelled `HStack(spacing: 4)`: `Text("From:").caption.secondary` +
  `Text(selectedAccountName)` `.caption .medium`, coloured `.secondary` when `linkedAccountId == nil`
  else `accentPrimary`, + `chevron.up.chevron.down` `.caption2 .secondary`. Followed by `Spacer`.
  - `selectedAccountName` = the linked account's name, or **`"Main"`** when nil.
  - Menu contents: a `"Main"` item (with a `checkmark` `Label` when selected), `Divider()`, then every
    **non-primary** account by name (checkmark when selected).
  - `HAPTIC: selectionChanged()` on pick.

---

### 2.6 Savings — `Views/SavingsScreen.swift`

`ScrollView(.vertical)` → `VStack(spacing: 32)`, `padding(24)`.

**Order:** header → allocation-mode picker → allocation section → savings-flow info → savings preview → action buttons.

`availableIncome = max(0, monthlyIncome - Σ expense.amount)` (`:15-18`).
`canEnableBoost = (percentage * boostMultiplier) <= 1.0` (`:21-24`).
`onChange(percentage)`: if boost is on and `!canEnableBoost`, **auto-disable boost** with
`withAnimation(.bouncy)` (`:41-48`).

1. **Header**: icon `banknote.fill` (accentSecondary), title **"How much do you want to save?"**,
   subtitle **"Savings are calculated from your income after expenses."**
2. **Allocation mode** (`VStack(alignment: .leading, spacing: 12)`):
   - `Text("Allocation Strategy").font(.headline)`
   - `Picker("Allocation Strategy", selection: $allocationMode).pickerStyle(.segmented)` with
     `AllocationMode.allCases` → segments **"Priority"** and **"Split"**
   - `Text(allocationMode.description).caption.secondary` → "Emergency fund fills first, then savings"
     / "Fixed amounts to each account every month"
3. **Allocation section** — branches on mode.

   **A. Prioritized** (`:102-131`), `VStack(alignment: .leading, spacing: 16)`:
   - `Text("Monthly Savings").font(.headline)`
   - `Picker("Savings Type", selection: $savingsInputMode).pickerStyle(.segmented)` →
     **"Percentage"** / **"Fixed Amount"**
   - If `.percentage`: `SavingsSlider` (§2.6.1) then the **boost card** (§2.6.2)
   - If `.fixedAmount`: `CurrencyAmountField(amount: $fixedAmount, showCurrencyPicker: false)`

   **B. Split** (`:143-250`), `VStack(alignment: .leading, spacing: 16)`:

   > ⚠️ **Cross-check disagreement — the default split input mode is `Fixed Amount`, not Percentage.**
   > `GROUND-TRUTH.md` records Split's defaults as "Emergency **10 %** / Savings **15 %**". Those are the
   > correct *percentage* values, but they are **not what a first-time user sees**. Both per-side input
   > modes default to `.fixedAmount` (`SavingsAllocationEntry.swift:58,61`):
   >
   > | Field | Default | Visible on first entry to Split? |
   > |---|---|---|
   > | `splitEmergencyInputMode` | **`.fixedAmount`** | yes — segment "Fixed Amount" is selected |
   > | `splitEmergencyAmount` | `0` | yes — the amount field shows **empty** (`formatForEditing(0)` = `""`) |
   > | `splitEmergencyPercentage` | `0.10` | **no** — only after switching the segment to "Percentage" |
   > | `splitSavingsInputMode` | **`.fixedAmount`** | yes |
   > | `splitSavingsAmount` | `0` | yes — empty field |
   > | `splitSavingsPercentage` | `0.15` | **no** |
   >
   > So switching Priority → Split with no further interaction gives **two empty Fixed Amount fields and
   > a total of 0**, not 10 %/15 %. The 10 %/15 % appear the moment either segment is toggled to
   > Percentage. The walkthrough must have toggled them — which is worth knowing, because a web
   > implementation that defaults to Percentage would show 473/710 RON allocated where iOS shows nothing.
   >
   > Arithmetic confirmed against `availableIncome = 4,730`: 10 % → `473.0` exactly (displays
   > **`473 RON`**); 15 % → `709.5`, which half-even-rounds to **`710 RON`** (710 is even). The `709.5`
   > case is a good golden-vector candidate — it is exactly where JS `Math.round`/`toFixed` would agree by
   > luck but `.5`-down cases would not.

   - `Text("Monthly Amounts").font(.headline)`
   - **Emergency block** — only when `hasEmergencyAccount`:
     - `Label("Emergency Fund", systemImage: "shield.fill").subheadline.secondary`
     - `Picker("Emergency Fund", selection: $splitEmergencyInputMode).pickerStyle(.segmented)` →
       Percentage / Fixed Amount
     - If `.percentage`: a row with `Text("\(Int(pct*100))%")` `.title3 .bold`, accentSecondary,
       `.monospacedDigit()`; `Spacer`; and — only if `availableIncome > 0` — the resolved amount
       `.subheadline .secondary`. Below it `Slider(value:, in: 0.05...0.50, step: 0.01)`
       `.tint(accentSecondary)`.
     - If `.fixedAmount`: `CurrencyAmountField(showCurrencyPicker: false)`
   - **Savings block** — only when `hasPrimarySavingsAccount`. Identical structure with
     `Label("Savings", systemImage: "banknote.fill")` and `Picker("Savings", …)`.
   - If **neither** account exists:
     `Text("Add an emergency or savings account first to use split mode.").subheadline.secondary`,
     centred, `padding(.vertical, 16)`
4. **Savings flow info** (`:330-357`) — shown when `hasEmergencyAccount || hasPrimarySavingsAccount`.
   `VStack(alignment: .leading, spacing: 12)`, `padding(16)`, `.glassCard()`
   (→ 32 pt total inner padding):
   - Header: `info.circle` `.caption` (accentSecondary) +
     `Text("How your savings are distributed").caption.medium.secondary`
   - Flow items (`flowItem(number:text:icon:)` = `HStack(spacing: 12)` of a **20×20** `Circle`
     filled `accentSecondary.opacity(0.2)` containing the number `.caption .bold`, then the icon
     `.caption` accentSecondary, then the text `.caption .secondary`):

     | mode | # | icon | text |
     |---|---|---|---|
     | prioritized, has emergency | 1 | `shield.fill` | "Emergency fund fills first until target reached" |
     | prioritized, has savings | 2 (or 1 if no emergency) | `banknote.fill` | "Remaining savings go to your savings account" |
     | split, emergency, `.percentage` | 1 | `shield.fill` | "Percentage of income to emergency each month" |
     | split, emergency, `.fixedAmount` | 1 | `shield.fill` | "Fixed amount to emergency each month" |
     | split, savings, `.percentage` | 2 (or 1) | `banknote.fill` | "Percentage of income to savings each month" |
     | split, savings, `.fixedAmount` | 2 (or 1) | `banknote.fill` | "Fixed amount to savings each month" |

     Each `.transition(.opacity.animation(.easeOut(0.25)))`.
5. **Savings preview** (`:430-459`) — shown only when `monthlyIncome > 0` **and** the computed amount
   `> 0`. `VStack(alignment: .leading, spacing: 12)`, `maxWidth: .infinity` leading,
   `padding(16)`, background `accentSecondary.opacity(0.1)`, radius 12:
   - `Text("This month's savings").subheadline.secondary`
   - `HStack`: formatted amount `.title2 .bold` accentSecondary +
     `Text("going to your accounts").subheadline.secondary`
   - Amount = `calculateSavings(availableIncome:)` in prioritized mode;
     `min(splitTotal(availableIncome:), availableIncome)` in split mode (`:461-469`)
6. **Action buttons** (`VStack(spacing: 12)`, `padding(.top, 32)`):
   - `OnboardingButton("Continue", isEnabled: true)`
   - `OnboardingSecondaryButton("Skip for now")` → **resets `savingsAllocation` to a fresh
     `SavingsAllocationEntry()`** (i.e. back to 25 % prioritized percentage) then advances (`:481-484`)

**Entrance**: everything on `SpringPreset.smooth.delay(0.3)`, sliding up 15 pt.

#### 2.6.1 `SavingsSlider` — `Components/SavingsSlider.swift`

Own constants (`:15-18`): `minimumPercentage 0.05`, `maximumPercentage 0.50`,
`recommendedPercentage 0.25`, `snapThreshold 0.02`.
`effectivePercentage = boostEnabled ? percentage * boostMultiplier : percentage` — ⚠️ **no `min(1.0,…)`
cap** unlike Domain. `savingsAmount = availableIncome * effectivePercentage`.

`VStack(spacing: 16)`:
1. Percentage display: `HStack(alignment: .lastTextBaseline)` —
   `Text("\(Int(percentage*100))")` at **`.system(size: 48, weight: .bold, design: .rounded)`**,
   accentPrimary, `.contentTransition(.numericText())`; then `Text("%")` `.title2 .semibold .secondary`.
   `.animation(SpringPreset.responsive, value: displayPercentage)`.
2. `Text("That's \(formattedAmount)/month")` `.headline .secondary` (interpolated string).
3. **Custom slider** in a `GeometryReader`, container height 24:
   - Track: `Capsule` `Color.secondary.opacity(0.15)`, height **8**
   - Fill: `Capsule` with the brand gradient, width `max(0, thumbPosition + 12)`, height 8
   - Recommended marker: `Circle` accentSecondary, **6×6**, offset to the 25 % position `- 3`
   - Thumb: `Circle().fill(.white)` **24×24**, `shadow(black 15 %, radius 4, y 2)`,
     overlaid `Circle().stroke(accentPrimary, lineWidth: 2)`, `scaleEffect(isDragging ? 1.1 : 1.0)`,
     offset `thumbPosition - 12`
   - Drag (`DragGesture(minimumDistance: 0)` **on the thumb only**):
     `newPercentage = 0.05 + clamp(x/width, 0, 1) * 0.45`, then **snapped** to the first of
     `[0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40]` within `0.02` (`HAPTIC: lightTap()` on snap).
     `HAPTIC: mediumTap()` on drag end.
     ⚠️ The track itself is not tappable — only dragging the thumb works.
4. Min/mid/max labels: `Text("5%")` `.caption .tertiary` — `Spacer` —
   `Text("25% recommended")` `.caption` accentSecondary — `Spacer` — `Text("50%")` `.caption .tertiary`.
   ⚠️ `"5%"` and `"50%"` are **raw literals, not localized**.
5. Recommendation badge — shown when `0.20 <= percentage <= 0.30`:
   `HStack(spacing: 4)` `checkmark.circle.fill` + `Text("Great savings rate!")` `.caption .medium`,
   both accentSecondary; `padding(.vertical, 8)`, `padding(.horizontal, 12)`,
   `accentSecondary.opacity(0.1)`, `Capsule`, `.transition(.scale.combined(with: .opacity))`.
   Whole component animates `.easeOut(0.25)` on that predicate.

Accessibility: `children: .ignore`, `accessibilityLabel("Savings percentage")`,
`accessibilityValue("\(displayPercentage) percent, \(amount) per month")`, and an
`accessibilityAdjustableAction` stepping by **0.05** clamped to [0.05, 0.50].

#### 2.6.2 Boost card — `SavingsScreen.swift:256-324`

`GlassEffectContainer(spacing: 0)` → `VStack(spacing: 12)` → `padding(16)` →
`.glassEffect(in: .rect(cornerRadius: 16))`, `glassEffectID("boostCard")`.

- **Toggle**, `.tint(accentPrimary)`, `.disabled(!canEnableBoost && !boostEnabled)`. Label:
  `HStack` of `bolt.fill` — **yellow when on, `.secondary` when off** — then
  `VStack(alignment: .leading, spacing: 4)`:
  - `Text("Savings Boost").subheadline.medium`
  - `Text(boostDescription).caption`, coloured `.secondary` if `canEnableBoost` else **orange**:
    - `canEnableBoost` → **"Triple your savings temporarily"**
    - else → **"Lower your savings rate to enable boost"**
  - The setter refuses to turn on when `!canEnableBoost`; `withAnimation(.bouncy)`,
    `HAPTIC: lightTap()`.
- **Warning** — shown only while boost is on: `HStack` `exclamationmark.triangle` `.caption` orange +
  `Text("Boost is great for catching up, but not sustainable long-term").caption.secondary`;
  `padding(12)`, `Color.orange.opacity(0.1)`, radius 8.
  The card **morphs** (grows) as the warning appears — `glassEffectID` + container.

⚠️ **DISCREPANCY:** `Docs/MVP/07-Savings.md:322-324, 409` explicitly defers Savings Boost to **Phase 2**.
It ships. Conversely, the doc's entire savings-rate **assessment/recommendation** system
(`07:129-180`) does **not** ship. And **split allocation mode** — arguably the largest savings feature
in the code — appears in **no** MVP doc.

---

### 2.7 Transfer Plan (onboarding payoff) — `Views/TransferPlanScreen.swift`

`ZStack` of the scroll content + a `CompletionCelebration` overlay (`allowsHitTesting(false)`).
`ScrollView` → `VStack(spacing: 24)`, `padding(.horizontal, 24)`, `.scrollIndicators(.hidden)`.
**No progress indicator** (toolbar hidden on this step).

**Order:** header → income hero → transfer cards → remaining money → verification → tip → complete button.

1. **Header** (`VStack(spacing: 16)`, `padding(.top, 24)`):
   - `AnimatedCheckmark()` — `checkmark.circle.fill` at 80 pt, accentSecondary, entering with
     `SpringPreset.bouncy` from scale 0.1 / rotation −30° / opacity 0
   - `Text("Your First Month")` `.largeTitle .bold`
   - `Text("Here's your personalized transfer plan, \(trimmedName)!")` `.title3 .secondary`, centred
2. **Income hero card** (`VStack(spacing: 8)`, `maxWidth: .infinity`, `padding(24)`, `.glassCard()`):
   - `Text("Monthly Income").subheadline.secondary`
   - Formatted `transferPlan.income` `.largeTitle .bold .fontDesign(.rounded)` in accentSecondary
3. **Transfer cards**: `GlassEffectContainer(spacing: 16)` → `VStack(spacing: 16)`:
   - `Text("Your Transfers").font(.headline)`, leading-aligned
   - One `AccountAllocationCard` per `transferPlan.accountAllocations`, staggered
     `responsive.delay(i * 0.1)`, sliding in from `x: +20`
   - One `ExpenseTransferCard` per `transferPlan.accountExpenseTransfers`, continuing the stagger index
   - `primaryAccountCard`, last in the stagger

   **`AccountAllocationCard`** (`:347-404`) — `VStack(alignment: .leading, spacing: 12)`,
   `padding(16)`, `.glassCard()`:
   - Row: type glyph in `accountType.color` + `Text(accountName).subheadline.medium` + `Spacer` +
     formatted amount `.headline .bold`
   - If `progressChangeDisplay != nil` (emergency only): `HStack` of
     `Text("86% → 92%")` `.caption`, **green if `isComplete` else orange**,
     `.contentTransition(.numericText())`; and when `isComplete`, additionally
     `HStack(spacing: 4)` `checkmark.circle.fill` `.caption` green + `Text("Target reached!").caption` green
   - If `accountType == .emergency && targetAmount != nil`:
     `ProgressView(value: progressAfter ?? 0)` tinted **green if complete else orange**,
     `.easeOut(0.25)`; then `Text("Target: \(formattedTarget)").caption.secondary`

   **`ExpenseTransferCard`** (`:408-436`) — `VStack(alignment: .leading, spacing: 12)`,
   `padding(16)`, `.glassCard()`:
   - Row: `arrow.right.circle.fill` **`.purple`** + `Text("Transfer to \(accountName)")` `.subheadline .medium`
     + `Spacer` + amount `.headline .bold`
   - `Text("for \(expenseNames.joined(separator: ", "))")` `.caption .secondary`

   **`primaryAccountCard`** (`:162-193`) — `VStack(alignment: .leading, spacing: 12)`,
   `padding(16)`, `.glassCard()`:
   - Row: `building.columns.fill` accentPrimary + `Text("Stays in Primary").subheadline.medium` +
     `Spacer` + formatted `remainsInPrimary` `.headline .bold`
   - `Text("For automatic bill payments").caption.secondary`
4. **Remaining money** — shown **only if `transferPlan.remainingMoney > 0`** (`:199-215`).
   `GlassEffectContainer(spacing: 16)` → `VStack(spacing: 16)`:
   - `Text("Remaining Money").font(.headline)`, leading
   - Card (`padding(16)`, `.glassCard()`): `dollarsign.circle.fill` **`.green`** +
     `Text("Available after savings").subheadline.medium` + `Spacer` +
     formatted amount `.headline .bold` **green**
   - `Text("Where should this go?").caption.secondary` + `RemainingMoneyPicker` (§2.7.1)
5. **Verification row** (`:257-279`): `HStack(spacing: 12)`, `padding(16)`, `maxWidth: .infinity`,
   radius 12, background `Color.green.opacity(0.1)` if balanced else `Color.orange.opacity(0.1)`:
   - glyph `checkmark.circle.fill` green / `exclamationmark.triangle.fill` orange
   - `Text("Total: \(formattedIncome)")` `.subheadline .medium`
   - if balanced, additionally `Text("All accounted for!").caption.secondary`,
     `.transition(.opacity.animation(.easeOut(0.25)))`
6. **Tip row**: `HStack(spacing: 12)`, `padding(16)`, leading —
   `lightbulb.fill` **yellow** +
   `Text("Tip: Do these transfers right after payday for best results!").caption.secondary`
7. **Complete button**: `OnboardingButton("Start Using Diameris", isEnabled: true)`,
   `padding(.top, 32)`, `padding(.bottom, 24)`.
   `HAPTIC: success()` then `onComplete()` → `viewModel.save(context:)` + the root's completion sequence.

**Entrance timing** (`:319-342`), with `T = accountAllocations.count + accountExpenseTransfers.count + 1`:
- `showCelebration = true` and `HAPTIC: success()` immediately
- header `bouncy.delay(0.3)`
- income `smooth.delay(0.2)`
- transfers `responsive.delay(0.4)`
- remaining `smooth.delay(0.5 + T * 0.1)`
- verification `smooth.delay(0.5 + (T+1) * 0.1)`

**`CompletionCelebration`** — `SharedUI/Components/CelebrationEffect.swift:174-202`:
`HAPTIC: success()`, then rings immediately and confetti after **0.2 s**. Rings =
3 concentric `Circle().stroke(...)` (accentPrimary lw 3; accentSecondary lw 2;
accentPrimary@50 % lw 1.5) in a 200×200 frame, each scaling 0.1 → **2.5** and fading to 0 with
`.easeOut(1.0)` at delays 0 / 0.15 / 0.3. Confetti: see `DESIGN-TOKENS.md §7.6`.

#### 2.7.1 `RemainingMoneyPicker` — `Components/RemainingMoneyPicker.swift`

`VStack(spacing: 12)` of one button per available destination.
**Available destinations** are assembled as (`:20-32`):
```
destinations = [.primary]
if hasSavingsAccount   -> insert .primarySavings at index 0
if hasPersonalAccount  -> append .personal
```
So the order is `[primarySavings?, primary, personal?]` — note `.primary` ("Keep in Primary") always
sits **between** the two optionals.

#### Default selection — `.primarySavings`

`OnboardingViewModel.swift:29`: `var remainingMoneyDestination: RemainingMoneyDestination = .primarySavings`.
The picker has no separate default; it renders whatever the view model holds.

**So in the normal path (a savings account exists, which the Accounts screen actively prompts for),
`.primarySavings` is inserted at index 0 and is therefore the FIRST card, already highlighted** —
accentSecondary fill, white text, trailing `checkmark.circle.fill`. The user does not need to tap
anything; tapping "Primary Savings" is a no-op that reselects the current value.

> ⚠️ **Edge case — no savings account: nothing appears selected, and the remaining money is silently
> lost.** If the user skipped the savings-account prompt, `hasSavingsAccount == false`, so
> `.primarySavings` is **not** in `availableDestinations` — but it is still the *selected* value. The
> picker then shows "Keep in Primary" (+ "Personal Account" if present) with **no card highlighted at
> all**, because no rendered destination equals the selection.
>
> It gets worse at save time. `OnboardingViewModel.save` (`:215-230`) switches on the destination and
> only credits an account if one matches:
> ```
> case .primarySavings: if let i = accounts.firstIndex(where: { $0.isPrimarySavings }) { += remainingMoney }
> ```
> With no primary-savings account **no branch fires**, and the primary account was already
> *assigned* `remainsInPrimary` a few lines earlier — so `plan.remainingMoney` is credited to **nothing**
> and vanishes. The transfer plan still displays it under "Remaining Money", so the screen shows money
> the database will not contain.
>
> Reproduce the *display* faithfully; the web port should decide deliberately whether to reproduce the
> loss. My recommendation: keep it for numeric parity and log it in `PARITY-GAPS.md` as an upstream bug,
> rather than silently diverging. Note this is unreachable in the default flow (the Accounts screen
> prompts for a savings account and most users accept), which is why it has survived.

Each button (`.buttonStyle(.plain)`): `HStack(spacing: 12)`, `padding(16)`, background
`RoundedRectangle(12)` filled `accentSecondary` when selected else `Color.secondary.opacity(0.1)`
(`.easeOut(0.25)`):
- glyph (`banknote.fill` / `person.fill` / `building.columns.fill`) — `.white` when selected else accentSecondary
- `VStack(alignment: .leading, spacing: 2)`: `displayName` `.subheadline .medium` and
  `description` `.caption` — `.white` / `.white.opacity(0.8)` when selected, else `.primary` / `.secondary`
- `Spacer`, then `checkmark.circle.fill` `.white` when selected,
  `.transition(.opacity.animation(.easeOut(0.25)))`

`withAnimation(SpringPreset.responsive)` on select; `HAPTIC: lightTap()`.

Strings: "Primary Savings" / "Add to your savings for future goals";
"Keep in Primary" / "Leave in your main account"; "Personal Account" / "For flexible spending".

⚠️ **DISCREPANCY:** the whole onboarding Transfer Plan screen has no counterpart in `Docs/MVP/01`, whose
Step 6 is a simple completion summary ("✓ You're all set!" / "Monthly Income: …" / "Expenses: …" /
"Accounts: 2" / "[Start Planning]"). **None of those strings ship.**

### 2.8 What onboarding persists

`OnboardingViewModel.save(context:)` (`:160-243`), in order:
1. `UserProfile(name: trimmedName, currencyCode:, remainingMoneyDestination:)`
2. `Income(name: "Salary", amount: monthlyIncome, frequency: .monthly)`
3. One `Expense` **for each expense with `amount > 0`** (zero-amount seeds are discarded)
4. **Balances are pre-applied as if the user made every transfer** (`:191-230`):
   - for each `plan.accountAllocations`: `+= allocation.amount`
   - for each `plan.accountExpenseTransfers`: `+= transfer.amount`
   - primary account: **`= plan.remainsInPrimary`** (assignment, not `+=`)
   - if `remainingMoney > 0`, add it to the destination account per `remainingMoneyDestination`
     (primarySavings / first personal / primary)
5. One `Account(from: entry, sortOrder: index)` per account, in array order
6. `SavingsAllocation(from: savingsAllocation)`
7. `try? context.save()` — **failures are silent**

⚠️ Step 4's ordering matters: the primary balance is *assigned* before the remaining-money step, so
`.primary` as the destination results in `remainsInPrimary + remainingMoney`.
⚠️ `Account(from:)` **does not preserve** the onboarding `AccountEntry.id` (see `DOMAIN-CONTRACT.md §5`),
so any `Expense.linkedAccountId` written in step 3 points at an ID that no persisted `Account` has —
**expense→account links made during onboarding are silently broken**. Confirm and decide before porting.

---

## 3. Main shell — `Diameris/Features/Main/MainTabView.swift`

`TabView` with three `Tab`s, `.tabBarMinimizeBehavior(.onScrollDown)`, plus
`.tabViewBottomAccessory { … }`.

| Tab label | systemImage | Content |
|---|---|---|
| **"Dashboard"** | `chart.pie.fill` | `DashboardView` (§4) |
| **"Expenses"** | `list.bullet.rectangle` | `ExpenseListView` (§5) |
| **"Insights"** | `lightbulb.max` | `InsightsPlaceholder` (§6) |

**Bottom accessory** (`:77-92`): a `Button` whose label is `HStack` of `calendar.badge.plus` +
`Text("New Month")`, `frame(maxWidth: .infinity)`, `contentShape(.rect)`.
`.disabled(!dashboardViewModel.hasCompletedOnboarding)`.
Tap → `refreshAllData()` then `openNewMonthFlow()` (sets `showNewMonthSheet = true`).

**Sheets** (`:52-64`): `NewMonthSheet` (§7), `SettingsSheet` (§8), `DevDebugView` (`#if DEBUG`, §9).

**Data flow** (`:102-302`) — reproduce this contract:
- `onAppear`: `setupDataObserver()` → `refreshAllData()` → `setupExpensesCallbacks()`
- `DataObserver` subscribes to `ModelContext.didSave`; **every save triggers a full
  `refreshAllData()`**, which re-derives both view models from `@Query` results.
- `loadDashboardData()` (`:120-180`) bails out with `hasCompletedOnboarding = false` if no
  `UserProfile` exists; otherwise copies profile/income/accounts/expenses/allocation into
  `DashboardViewModel`, using `?? <default>` for every allocation field
  (0.25 / false / 3.0 / .prioritized / .percentage / 0 / .fixedAmount / 0 / 0.10 / .fixedAmount / 0 / 0.15).
  Expenses are filtered to `isEnabled` and mapped with **`expense.monthlyAmount`** (annual expenses are
  divided by 12 here).
- `loadExpensesData()` (`:190-228`) merges `@Query` custom categories with any optimistic local ones not
  yet in the query (`:197-202`) — a deliberate anti-flicker measure. Expenses are mapped with their
  **raw `amount`** and real `frequency`.
- `onDisappear`: `dataObserver.stopObserving()`.

**Expense/category mutations** are injected as callbacks (`:230-302`) — add/update/delete/toggle expense,
add/delete category — each fetching by `#Predicate { $0.id == id }` with `fetchLimit = 1` and calling
`try? context.save()`.

---

## 4. Dashboard tab — `Packages/Features/Dashboard/Sources/Dashboard/DashboardView.swift`

`NavigationStack` → `ScrollView`, `.scrollIndicators(.hidden)`.
`navigationTitle(viewModel.currentMonthDisplay)` → e.g. **"December 2025"** (locale-formatted).

**Toolbar** (`.topBarTrailing`), an `HStack(spacing: 12)`:
- `Button("Settings", systemImage: "gearshape")` — only when the callback is non-nil
- `#if DEBUG` `Button("Developer Tools", systemImage: "hammer.fill")`

**Body** — `if hasCompletedOnboarding` then the content, else the empty state.

**Empty state** (`:110-116`): `ContentUnavailableView` with
`Label("No data yet", systemImage: "chart.bar.doc.horizontal")` and description
`Text("Complete onboarding to start tracking your finances")`.

**Content** (`:68-108`) — `VStack(spacing: 16)`, `padding(.horizontal, 16)`, `padding(.vertical, 12)`:

### 4.1 `SummaryCard`

`VStack(alignment: .leading, spacing: 16)`, `.glassCard()`.
- `Label("Monthly Summary", icon: chart.pie.fill in accentPrimary)`, title `.headline`
- `Divider()`
- `VStack(spacing: 12)` of `SummaryRow`s. Each row: label (left) + `Spacer` + amount (right),
  `.subheadline` normally / `.headline` + bold for the total row; label colour `.secondary` normally,
  `.primary` for the total.

  | label | value | style | colour |
  |---|---|---|---|
  | "Income" | `monthlyIncome` | neutral | `.primary` |
  | "Expenses" | `totalExpenses` | negative | `DiamerisColors.negative` (red) |
  | "Savings" | `transferPlan.totalSavings` | positive | `DiamerisColors.positive` (teal) |
  | *(Divider)* | | | |
  | "Personal Spending" | `transferPlan.remainingMoney` | neutral, `isTotal` | `.primary` |

  Negative-style rows are prefixed with a literal **`"-"`** when `amount > 0` (`:96-99`) →
  `"-5,555 RON"`.

⚠️ **DISCREPANCY:** the row is labelled "Personal Spending" but is bound to
`transferPlan.remainingMoney`, which is money *not yet* assigned to any account — it goes wherever
`remainingMoneyDestination` says, which may well be savings.

### 4.2 `EmergencyProgressCard` — rendered only when all three of
`emergencyAccount`, `emergencyProgress`, `emergencyTarget` are non-nil.

`HStack(spacing: 16)` + trailing `Spacer`, `.glassCard()`:
- `ProgressRing.large(progress:, showLabel: true, color: progressColor)` — 80 pt, lineWidth 8,
  centre label `"\(Int(progress*100))%"` `.caption .semibold` in `progressColor`,
  `.contentTransition(.numericText())`. Ring: background `Circle().stroke(secondary@15 %, lw 8)`;
  fill `Circle().trim(0…progress).stroke(color, StrokeStyle(lw 8, lineCap: .round))`
  rotated **−90°**. Animates in with `SpringPreset.smooth`, and again on any progress change.
  `accessibilityLabel("\(Int(progress*100)) percent complete")`.
- `progressColor` (`:56-64`): `>= 1.0` → `positive` (teal); `>= 0.5` → `accentSecondary`;
  else → `warning` (orange). ⚠️ `positive` **is** `accentSecondary`, so the first two branches are
  visually identical — the 0.5 threshold has no visible effect.
- Info column (`VStack(alignment: .leading, spacing: 8)`):
  - `Label("Emergency Fund", icon: shield.fill in progressColor)`, title `.headline`
  - Balance `.subheadline .secondary`: `"<current> / <target>"` (literal `" / "` separator)
  - Target `.caption .tertiary`, one of:
    - `"Target: \(multiplierInt)× monthly income"`
    - `"Target: \(multiplierInt)× monthly income (capped at \(capFormatted))"` when a hard cap exists

### 4.3 `AccountBalancesSection` — `Components/AccountBalancesRow.swift`

`GlassEffectContainer(spacing: 12)` → `VStack(spacing: 12)`:
- `Label("Account Balances", icon: building.columns.fill in accentPrimary)` `.headline`, leading
- **Primary card** (if a primary account exists) — `PrimaryAccountCard`, `.glassCard()`:
  `HStack` of a `VStack(alignment:.leading, spacing: 4)` containing
  `Label(account.name, icon: type glyph .subheadline in accentPrimary)` with the name `.subheadline .secondary`,
  then the balance `.title2 .bold`; then `Spacer`; then
  `Text("Primary")` `.caption .secondary`, `padding(.horizontal, 12)`, `padding(.vertical, 4)`,
  `Color.secondary.opacity(0.1)` in a `Capsule`.
- **Other accounts** — `LazyVGrid` of **2 flexible columns**, spacing 12, containing one
  `SecondaryAccountCard` each. Filter: `!isPrimary && accountType != .emergency` (emergency has its own
  card above). Card = `VStack(alignment: .leading, spacing: 8)`, `maxWidth: .infinity` leading,
  `.glassCard()`: `Label(name, icon: type glyph .caption in iconColor)` with the name
  `.caption .secondary` `lineLimit(1)`; then the balance `.subheadline .bold` `lineLimit(1)`
  `minimumScaleFactor(0.8)`.
  `iconColor` uses the **card-local** mapping in `:124-137` (see `DOMAIN-CONTRACT.md §1` for the
  three-way colour inconsistency).
- If there are no other accounts, the grid is omitted entirely (no placeholder).

### 4.4 `ExpenseBreakdownCard`

`VStack(alignment: .leading, spacing: 16)`, `.glassCard()`:
- `Label("Expense Breakdown", icon: chart.pie.fill in accentSecondary)` `.headline`
- If no expenses with `amount > 0`: `Text("No expenses set").subheadline.secondary`
- Else `VStack(spacing: 8)` of the **top 5** (`sortedExpenses.prefix(5)`, sorted by amount descending,
  `amount > 0` only). Each `BreakdownExpenseRow` = `HStack(spacing: 12)`:
  - expense glyph `.body .secondary` in a **32 pt** frame
  - `Text(name).subheadline`
  - `Spacer`
  - formatted amount `.subheadline .secondary`
  - `Text("\(percentage)%")` `.caption .secondary`, `padding(.horizontal, 8)`,
    `padding(.vertical, 4)`, `Color.secondary.opacity(0.1)` in a `Capsule`.
    `percentage = Int((amount / totalExpenses) * 100)` via `Double`, **truncated**; `0` when
    `totalExpenses <= 0`.

**The Dashboard is entirely read-only** — no taps, no navigation, no edit affordances.
⚠️ **DISCREPANCY:** `Docs/MVP/02-Income.md:134` ("Tap to edit"), `05:169` ("Tap for detail view"),
`10` (health score, benchmarks, recommendations, quick summary) — none of it ships.

---

## 5. Expenses tab — `Packages/Features/Expenses/Sources/Expenses/Views/ExpenseListView.swift`

`NavigationStack` → `ScrollView` → `VStack(spacing: 16)`, `padding(.horizontal, 16)`,
`padding(.vertical, 12)`, `.scrollIndicators(.hidden)`.
`navigationTitle("Expenses")`.
`.searchable(text: $viewModel.searchText, prompt: "Search expenses")`.

**Toolbar:**
- `.primaryAction`: `Button("Add Expense", systemImage: "plus")` → `HAPTIC: lightTap()`,
  `startAddingExpense()` (clears `editingExpense`, opens the sheet)
- `.secondaryAction`: `Menu("Options", systemImage: "ellipsis.circle")` containing
  - `Label("Expand All", systemImage: "rectangle.expand.vertical")` → `expandAll()` in
    `withAnimation(SpringPreset.responsive)`, `HAPTIC: lightTap()`
  - `Label("Collapse All", systemImage: "rectangle.compress.vertical")` → `collapseAll()`
  - `Divider()`
  - `Label("Manage Categories", systemImage: "folder.badge.gearshape")` → opens §5.3

**Order:** summary header → frequency toggle → (category list | empty state).

### 5.1 Summary header + frequency toggle

> ✅ **The Dashboard total and the Expenses-tab total are EQUAL BY CONSTRUCTION — one value, not two.**
> (Confirms `DECISIONS.md` R3 as amended; the original R3 asked for two API fields. One field.)
>
> They look different in isolation because the normalisation happens in different places, but both
> evaluate to *the sum of `monthlyAmount` over enabled expenses*:
>
> | | Expression | Input it receives |
> |---|---|---|
> | Dashboard | `expenses.reduce(0) { $0 + $1.amount }` (`DashboardViewModel.swift:176-178`) | **already** filtered and normalised — `MainTabView.swift:147-155` passes `expenses.filter { $0.isEnabled }` with `amount: expense.monthlyAmount` |
> | Expenses tab | `expenses.filter { $0.isEnabled }.reduce(0) { $0 + $1.monthlyAmount }` (`ExpensesViewModel.swift:272-276`) | **raw** — `MainTabView.swift:205-217` passes `amount: expense.amount` with the real `frequency` |
>
> The Dashboard's `reduce` over a raw `amount` is not a bug: its `amount` field is *defined* as the
> monthly-equivalent by the time it arrives. Adding an annual or disabled expense keeps the two equal.
>
> **The real quirk nearby: search narrows the rows but NOT the header total.** `displayTotal` reads
> `expenses` (`ExpensesViewModel.swift:271-289`) while `expenseGroups` reads `filteredExpenses`
> (`:291-292`). So typing in the search field shrinks the category list while the big number above it
> keeps showing the unfiltered total. Reproduce this — it is the shipped behaviour.

**Summary** (`:89-104`) — `VStack(spacing: 12)`, `maxWidth: .infinity`, `padding(.vertical, 16)`,
`.glassCard()`:
- `Text("Total \(selectedFrequencyView.displayName) Expenses")` `.subheadline .secondary`

  > ### ⚠️ This header is FULLY ENGLISH in Romanian — both words, for two separate reasons
  >
  > Renders **"Total Monthly Expenses"** / **"Total Annual Expenses"** in EN *and* RO. It is not
  > partially translated. Two independent lookup failures stack:
  >
  > **1. The wrapper never resolves.** The code is `"Total \(x) Expenses".localized`
  > (`ExpenseListView.swift:91`). Interpolation happens **first**, producing an ordinary `String`;
  > `.localized` then calls `String.LocalizationValue(self)`, which treats that whole runtime string as
  > a literal key. So the runtime key is `"Total Monthly Expenses"`.
  > Xcode's *static* extractor, however, saw the source interpolation and wrote the key
  > **`"Total %@ Expenses"`** into the catalog — with a perfectly good Romanian value,
  > `"Cheltuieli %@ totale"`. Runtime key ≠ catalog key, so it never matches.
  > **That translation is dead** — same orphan family as `app.Other = "Altele"` (`LOCALIZATION.md` §3.2).
  > Do not ship it; do not "wire it up".
  >
  > **2. The inner word never resolves either.** `Frequency.displayName` is *Domain* code
  > (`Frequency.swift:33-38`) returning `"Monthly".localized`, which binds **Domain's** bundle.
  > `Monthly` and `Annual` are **absent from the Domain catalog** — verified. The
  > `Monthly → "Lunar"` / `Annual → "Anual"` entries live in the **`expenses`** catalog, which
  > `displayName` never reads. So `displayName` returns its key: **"Monthly"**, in both languages.
  >
  > ⚠️ **Consequence beyond this header:** the Monthly|Annual **segmented control** (§5.1) shows
  > **English in Romanian too**, on iOS, because it renders the same `frequency.displayName`.
  > Rendering it untranslated is therefore *correct parity*, not a missing translation.
  >
  > The `expenses` catalog's `Annual → "Anual"` **is** live — but only at
  > `ExpenseItemRow.swift:60`, whose `"Annual".localized` binds the Expenses bundle for the
  > `(Annual)` caption. So `(Anual)` is correct there while the segment above stays `Annual`.
  > Reproduce that inconsistency; it is what ships.
- `Text(formattedDisplayTotal)` at `.system(.largeTitle, design: .rounded, weight: .bold)`,
  `.monospacedDigit()`, `.contentTransition(.numericText())`,
  `.animation(SpringPreset.smooth, value: displayTotal)`
- `displayTotal` = `totalMonthlyExpenses` or `totalAnnualExpenses`, both **enabled-only**
  (`ExpensesViewModel.swift:272-288`)

**`FrequencyPicker`** — `Components/FrequencyPicker.swift`:
`Picker("Frequency", selection:).pickerStyle(.segmented)` over `Frequency.allCases` with
`Label(displayName, systemImage: icon)` → segments **"Monthly"** (`calendar`) and
**"Annual"** (`calendar.badge.clock`). `HAPTIC: selectionChanged()` on change.

### 5.2 Category list / empty state

**Empty state** (`:151-164`) — shown when `expenseGroups.isEmpty`. `ContentUnavailableView`:
`Label("No Expenses Yet", systemImage: "list.bullet.rectangle")`;
description `Text("Add your first expense to start tracking your budget.")`;
action `Button("Add Expense", systemImage: "plus")` `.buttonStyle(.glassProminent)`,
`HAPTIC: mediumTap()`. `padding(.vertical, 48)`.

**Grouping** (`ExpensesViewModel.swift:291-327`), reproduce exactly:
1. Filter by search (see below), then bucket by `categoryId`; `nil` → uncategorized.
2. Emit a group for each of `allCategories` (defaults + custom, sorted by `sortOrder`) **that has
   expenses**, in that order.
3. Then emit a group per **unknown** `categoryId` (category deleted/not loaded), with `category: nil`
   and `id: categoryId`.
4. Then, if any, the uncategorized group with the sentinel id
   `00000000-0000-0000-0000-000000000000`.

**Search** (`:330-345`) matches, via `localizedStandardContains` (case- and diacritic-insensitive):
expense `name`, the resolved category `name` (including custom), or `notes`.

**`ExpenseCategoryCard`** — `Components/ExpenseCategoryCard.swift`:
`VStack(spacing: 0)`, `.glassEffect(in: .rect(cornerRadius: 16))`.
- **Header** — a `Button` (`.buttonStyle(.plain)`), `padding(16)`, whole row tappable:
  `HStack(spacing: 12)`:
  - category glyph `.title2` in `Color(hex: colorHex) ?? .gray`, frame **32×32**;
    falls back to `questionmark.circle.fill` / `.gray` for `category == nil`
  - `VStack(alignment: .leading, spacing: 4)`:
    - `Text(categoryName).headline.primary` — `category?.name` or **"Uncategorized"**
    - `Text("\(enabledCount)/\(expenses.count) " + "enabled")` `.caption .secondary`
      ⚠️ String-concatenation of a localized `"enabled"` fragment — awkward but reproducible; RO word
      order cannot be adjusted.
  - `Spacer`
  - group total `.headline.monospacedDigit()` `.primary` (monthly or annual per the toggle;
    **enabled-only**)
  - `chevron.right` `.caption.weight(.semibold)` `.secondary`, rotated **90°** when expanded
  - Tap → `isExpanded.toggle()` in `withAnimation(SpringPreset.snappy)`, `HAPTIC: lightTap()`
- **Expanded**: `Divider().padding(.horizontal, 16)` then `LazyVStack(spacing: 0)` of
  `ExpenseItemRow`s each with `padding(.horizontal, 16)`, separated by
  `Divider().padding(.leading, Spacing.md + IconSize.md + Spacing.sm)` = **`16 + 24 + 12 = 52 pt`**
  inset (omitted after the last row). Wrapper `padding(.vertical, 12)`.
- Expansion state lives in `viewModel.expandedCategories: Set<UUID>` keyed by `group.id`.

**`ExpenseItemRow`** — `Components/ExpenseItemRow.swift`:
A `Button` (`.buttonStyle(.plain)`) → `HStack(spacing: 12)`, `padding(.vertical, 8)`:
- expense glyph `.title3`, `.primary` if enabled else `.secondary`, frame **24×24**
- `Text(name).font(.body)`, same enabled/disabled colouring
- `Spacer`
- `VStack(alignment: .trailing, spacing: 4)`:
  - `displayAmount` (`monthlyAmount` or `annualAmount` per the toggle) as `.body.monospacedDigit()`
  - when `expense.frequency == .annual && displayFrequency == .monthly`:
    `Text("(\("Annual".localized))")` `.caption .secondary` → renders **`(Annual)`**
- `Toggle("", isOn:)` `.labelsHidden()` `.tint(.accentColor)` → `HAPTIC: selectionChanged()` then
  `onToggle(newValue)`
- Tap anywhere else → `HAPTIC: lightTap()`, `onTap()` → opens the edit sheet
- `.contextMenu`: `Label("Edit", systemImage: "pencil")` (`HAPTIC: lightTap()`) and a destructive
  `Label("Delete", systemImage: "trash")` (`HAPTIC: warning()`).
  ⚠️ **Delete from the context menu has no confirmation** — it fires immediately. (The sheet's delete
  button *does* confirm.)

All mutations are **optimistic**: `ExpensesViewModel` updates its local array first, then awaits the
persistence callback (`:377-436`).

### 5.3 `AddExpenseSheet` — `Views/AddExpenseSheet.swift`

`NavigationStack` → `Form`. `navigationTitle` = **"Edit Expense"** when editing, else
**"Add Expense"**; `.navigationBarTitleDisplayMode(.inline)`.

Sections in order:
1. **header "Details"**
   - `TextField("Name", text: $input.name)`
   - `CurrencyAmountField(amount: $input.amount, currency: $viewModel.currency, showCurrencyPicker: false)`
   - `FrequencyPicker(selection: $input.frequency)`
2. **Monthly equivalent** — only when `frequency == .annual && amount > 0`:
   a row `Text("Monthly Equivalent")` + `Spacer` + formatted `amount * (1/12)` `.secondary`
3. **header "Category"**
   - `CategoryPicker(selection: $input.categoryId, categories: viewModel.allCategories)` —
     a `Picker("Category")` with a `Text("None").tag(nil)` first entry, then
     `Label(name, systemImage: icon)` per category. `HAPTIC: selectionChanged()` on change.
   - `Button` → `Label("New Category...", systemImage: "plus.circle")` (note the three literal dots,
     not an ellipsis character) → opens `AddCategorySheet`; on creation the new id is assigned to
     `input.categoryId`. `HAPTIC: lightTap()`.
4. **header "Account"**, footer `Text("Choose which account this expense is paid from.")` — only when
   `!viewModel.accounts.isEmpty`:
   - `Picker("Pay From", selection: $input.linkedAccountId)` with `Text("Primary").tag(nil)` then
     `Label(name, systemImage: type icon)` for every **non-primary** account
5. **header "Icon"** — `IconPicker(selection: $input.icon)`:
   `LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12)` over **37 symbols**, listed in
   source order in `DESIGN-TOKENS.md §9.3`. Each cell: glyph `.title2` in a 44×44 frame, background
   `Color.accentColor.opacity(0.2)` when selected else `.clear`, radius 8, `.buttonStyle(.plain)`,
   `accessibilityLabel(icon)` (⚠️ the raw SF Symbol name — poor VoiceOver copy).
   `HAPTIC: lightTap()`.

   > ⚠️ **The two icon grids are DIFFERENT lists. Do not share one array between them.**
   >
   > | Grid | Screen | Count | Source |
   > |---|---|---|---|
   > | `IconPicker` | Add/Edit **Expense** | **37** | `AddExpenseSheet.swift:193-231` |
   > | category icons | New **Category** | **12** | `CategoryManagementView.swift:133-137` |
   >
   > Both counts and orderings were re-extracted programmatically from source. They overlap on only
   > 5 symbols (`heart.fill`, `bolt.fill`, `leaf.fill`, `gift.fill`, `calendar`… note `calendar` is in
   > the category grid but **not** the expense grid), so sharing a list breaks whichever screen loses.
   >
   > `GROUND-TRUTH.md` records the expense grid as 18 symbols — that is the **above-the-fold count**
   > on an iPhone viewport (the adaptive 44 pt grid fits ~6 per row, so ~3 rows are visible before the
   > Form section scrolls). The 18th symbol in source order is `creditcard.fill`, which is consistent
   > with the observation. The full list is 37; the screenshot is not wrong, just clipped.
6. **header "Notes"** — `TextField("Notes", text: $notesText, axis: .vertical)` `.lineLimit(3...6)`.
   On change, `input.notes = newValue.isEmpty ? nil : newValue`.
7. *(no header)*, footer `Text("Disabled expenses won't be included in your budget calculations.")`
   — `Toggle("Enabled", isOn: $input.isEnabled)`
8. **Delete section** — only when editing: a `Button(role: .destructive)` centred
   `Text("Delete Expense")`. `HAPTIC: warning()` → opens the confirmation.

**Toolbar:** `.cancellationAction` `Button("Cancel")` (`HAPTIC: lightTap()`, dismiss);
`.confirmationAction` `Button("Save")` (`HAPTIC: success()` → `await saveExpense(input)`),
`.disabled(!input.isValid)`.

**Validation** — `ExpenseInput.isValid` (`ExpensesViewModel.swift:151-153`):
`!name.trimmed.isEmpty && amount > 0`. **That is the only rule** — no length limits, no maximum amount.
⚠️ `Docs/MVP/03-Expenses.md:299-304` specifies name ≤ 100 chars, amount ≤ 10,000,000, and explicitly
allows **amount == 0** ("user may want to track a suspended expense"); the code **rejects 0**.

**Delete confirmation** — `.confirmationDialog("Delete Expense", titleVisibility: .visible)`:
message `Text("Are you sure you want to delete this expense? This action cannot be undone.")`;
buttons `Button("Delete", role: .destructive)` (`HAPTIC: warning()`, delete, dismiss) and
`Button("Cancel", role: .cancel)`.

**Defaults for a new expense** (`ExpenseInput()`): `name ""`, `amount 0`, `frequency .monthly`,
`icon "dollarsign.circle.fill"`, `categoryId nil`, `linkedAccountId nil`, `isEnabled true`, `notes nil`.

### 5.4 `CategoryManagementView` — `Views/CategoryManagementView.swift`

`NavigationStack` → `List`. `navigationTitle("Categories")`, `.inline`.

Sections:
1. header `Text("Default Categories")`, footer `Text("Default categories cannot be deleted.")` —
   one `CategoryRow(isDefault: true)` per `ExpenseCategory.defaults` (the 8, in `sortOrder`)
2. header `Text("Custom Categories")` — only when `!customCategories.isEmpty`; each
   `CategoryRow(isDefault: false)` with a trailing `swipeActions` destructive
   `Label("Delete", systemImage: "trash")` → `HAPTIC: warning()`, `await onDeleteCategory?(id)`.
   ⚠️ **No confirmation**, and **no reassignment** of the expenses that referenced it — they become
   "unknown category" groups (see §5.2 step 3).
   `Docs/MVP/04:474` says they should "Become uncategorized"; in the code they keep the dangling id and
   render as a header-less group with a `questionmark.circle.fill` icon and the label "Uncategorized".

**`CategoryRow`**: `HStack(spacing: 16)`, `padding(.vertical, 8)`, `contentShape(Rectangle())`:
glyph `.title2` in `Color(hex: colorHex) ?? .gray`, frame **32×32** → `Text(name).font(.body)` →
`Spacer` → when default, `Text("Default")` `.caption .secondary`, `padding(.horizontal, 12)`,
`padding(.vertical, 4)`, `.secondary.opacity(0.2)`, `Capsule`.
⚠️ Rows are **not tappable** — categories cannot be edited or renamed, only created and deleted.

**Toolbar:** `.cancellationAction` `Button("Done")` (`HAPTIC: lightTap()`, dismiss);
`.primaryAction` `Button` with `Image(systemName: "plus")` → `AddCategorySheet`.

### 5.5 `AddCategorySheet` — `CategoryManagementView.swift:111-250`

`NavigationStack` → `Form`. `navigationTitle("New Category")`, `.inline`.

Sections:
1. header `Text("Category Name")` — `TextField("Name", text: $name)`
2. header `Text("Icon")` — `LazyVGrid(.adaptive(minimum: 44), spacing: 12)` over **12** symbols
   (⚠️ **not** the 37-symbol expense grid — see the warning in §5.3), cell 44×44, `.title2`, selected
   bg `Color.accentColor.opacity(0.2)`, radius 8. Default `star.fill`. `HAPTIC: lightTap()`.
   Source order, `CategoryManagementView.swift:133-137`:

   | # | symbol | # | symbol | # | symbol |
   |---|---|---|---|---|---|
   | 1 | `star.fill` | 5 | `gift.fill` | 9 | `bell.fill` |
   | 2 | `heart.fill` | 6 | `tag.fill` | 10 | `clock.fill` |
   | 3 | `bolt.fill` | 7 | `bookmark.fill` | 11 | `calendar` |
   | 4 | `leaf.fill` | 8 | `flag.fill` | 12 | `folder.fill` |

3. header `Text("Color")` — same adaptive grid over **10** hexes; each is a **36×36** `Circle` filled
   with the colour, overlaid `checkmark` `.caption.bold` `.white` when selected. Default `#3B82F6`
   (swatch 1). `HAPTIC: lightTap()`. Exact values and order, `CategoryManagementView.swift:120-131`:

   | # | hex | name in code | # | hex | name in code |
   |---|---|---|---|---|---|
   | 1 | `#3B82F6` | Blue | 6 | `#EF4444` | Red |
   | 2 | `#8B5CF6` | Purple | 7 | `#22C55E` | Green |
   | 3 | `#F59E0B` | Amber | 8 | `#06B6D4` | Cyan |
   | 4 | `#10B981` | Emerald | 9 | `#F97316` | **Orange** |
   | 5 | `#EC4899` | Pink | 10 | `#6366F1` | **Indigo** |

   The last two read as orange and indigo in `15-manage-categories.jpg` / the New Category screenshot —
   confirmed as `#F97316` and `#6366F1`. All ten are Tailwind 500-weights. Note these are *not* the
   same set as the 8 default-category colours: swatches 9–10 are picker-only, and the defaults'
   `#3B82F6…#06B6D4` are swatches 1–8 in the same order.
4. header `Text("Preview")` — `HStack(spacing: 16)`: selected glyph `.title2` in the selected colour,
   frame **32×32**, then `Text(name.isEmpty ? "Category Name" : name).font(.body)`
   (the placeholder reuses the section-header string).

**Toolbar:** `Button("Cancel")` (`HAPTIC: lightTap()`); `Button("Add")` (`HAPTIC: success()`),
`.disabled(!isValid)` where `isValid = !name.trimmed.isEmpty`.
Add sequence (`:223-246`): generate a fresh `UUID`, trim the name, **await** the persistence callback,
then on the main actor append to `customCategories`, invoke `onCategoryCreated?(id)`, and dismiss.
`sortOrder` is always **100**.
⚠️ **No uniqueness check.** `Docs/MVP/04:425` requires "A category with this name already exists".

---

## 6. Insights tab — `MainTabView.swift:337-357`

`NavigationStack` → `VStack(spacing: 24)`, `maxWidth/maxHeight: .infinity`,
`navigationTitle("Insights")`:
- `lightbulb.max` at `iconXxl()` (64 pt) in accentPrimary
- `Text("Insights")` `.title .bold`
- `Text("Coming soon")` `.subheadline .secondary`

Nothing else. This is the placeholder for the entire `Docs/MVP/10-BudgetAnalysis.md` feature set.

---

## 7. New Month flow — `Dashboard/Views/NewMonthSheet.swift`

Presented as a sheet from the tab-bar accessory. `.presentationDetents([.large])`.
`NavigationStack`; `navigationTitle` = **`"Step \(rawValue) of 3"`**, `.inline`.
`.interactiveDismissDisabled(currentStep != .salaryEntry)` — **the sheet cannot be swipe-dismissed on
steps 2 and 3**; on web, disable backdrop-click dismissal there.

**Toolbar** `.cancellationAction`:
- step 1 → `Button("Cancel")` → dismiss
- steps 2–3 → `Button("Back", systemImage: "chevron.left")` → `goBack()`

Steps (`:23-35`), with their unused `title` property (the nav bar shows "Step N of 3" instead):

| rawValue | case | `title` (declared but never rendered) |
|---|---|---|
| 1 | `salaryEntry` | "How much did you receive?" |
| 2 | `reconcileAccounts` | "Update your account balances" |
| 3 | `transferPlan` | "Your Transfer Plan" |

**`onAppear` setup** (`:106-113`): `enteredIncome = viewModel.monthlyIncome`;
`accountBalances[id] = account.currentBalance` for every account;
`calculatedPlan = calculateTransferPlan(withIncome: enteredIncome)` (no reconciled overrides yet).

> ⚠️ **Step 2's prefill is the account's plain persisted `currentBalance` — NOT a projection.**
> `NewMonthSheet.swift:109` is literally `accountBalances[account.id] = account.currentBalance`.
> It does **not** add the previous month's planned allocation, and it does not pre-apply anything.
> The field shows exactly what is in storage; the user overwrites it with their real bank balance.
> Implementing a projection here produces wrong numbers throughout the rest of the flow. Confirmed
> against `GROUND-TRUTH.md` §208-211, which observed the raw stored values in the live app.

**Advance** (`:115-136`), `withAnimation(SpringPreset.responsive)`:
- from step 1 → recalculate the plan with `enteredIncome` **and** the current `accountBalances`, go to 2
- from step 2 → recalculate again with the (now user-edited) balances, go to 3
- from step 3 → no-op

**Back** (`:138-149`): 3→2, 2→1, 1 no-op. Entered values are preserved.

**Complete** (`:151-167`): if `calculatedPlan == nil`, just dismiss. Otherwise emit
`NewMonthCompletionData(income:, transferPlan:, reconciledBalances:)` and dismiss.

### 7.1 Step 1 — `SalaryEntryStep.swift`

`VStack(spacing: 32)`, `padding(.horizontal, 24)`, `padding(.vertical, 16)`;
tapping the background dismisses the keyboard.
Order: `Spacer` → header → amount input → last-month hint → `Spacer` → `Spacer` → Continue
(note the **double** `Spacer`, which pushes the CTA to roughly the bottom third).

- Header (`VStack(spacing: 12)`): `dollarsign.circle.fill` `iconXl()` (48 pt) accentPrimary;
  `Text("How much did you receive?")` `.title2 .semibold`, centred
- `CurrencyAmountField(amount: $income, currency: $currencyBinding, showCurrencyPicker: false)`
- Hint — only when `lastMonthIncome > 0`: `Text("Last month: \(formatted)")` `.subheadline .secondary`
- Continue: `Button` → `Text("Continue")`, `maxWidth: .infinity`, `padding(.vertical, 12)`,
  `.buttonStyle(.glassProminent)`, `.disabled(income <= 0)`

### 7.2 Step 2 — `ReconcileAccountsStep.swift`

`VStack(spacing: 24)`, `padding(.vertical, 16)`; background tap dismisses the keyboard.

- Header block (`VStack(spacing: 12)`, `padding(.horizontal, 24)`):
  - `arrow.triangle.2.circlepath` `iconLg()` (32 pt) accentSecondary
  - `Text("Update your account balances")` `.title3 .bold`
  - `Text("Did you use any savings this month?")` `.subheadline .secondary`
- `ScrollView` (`.scrollIndicators(.hidden)`) → `VStack(spacing: 16)`, `padding(.horizontal, 24)`, of one
  `ReconcileAccountCard` per **reconcilable** account — filter:
  `accountType == .emergency || .savings || .personal` (`:30-36`).
  ⚠️ Primary, joint and other accounts are **not** reconcilable and keep their stored balance.

  > **On the observation that "only Savings and Emergency Fund appear, Main Account is absent":** both
  > halves are right but for different reasons. `primary` is excluded **by the filter** — Main Account can
  > never appear here. A `personal` account **would** appear; it was simply absent from the walkthrough's
  > data. So the rule is "emergency + savings + personal", and the observed two-card screen is the
  > filter plus that particular dataset, not the complete rule.
- Continue: `Button("Continue")`, `maxWidth: .infinity`, `padding(.vertical, 12)`,
  `.buttonStyle(.glassProminent)`, `padding(.horizontal, 24)` — **never disabled**

**`ReconcileAccountCard`** (`:90-134`) — `VStack(alignment: .leading, spacing: 12)`, `.glassCard()`:
- `HStack`: `Label(account.name, icon: type glyph in iconColor)`, name `.headline`; `Spacer`;
  `Text("Current balance")` `.caption .secondary`
- `CurrencyAmountField(amount: $balance, currency:, showCurrencyPicker: false)`
- `Text("was \(formattedStoredBalance) last month")` `.caption .tertiary`

  > ⚠️ **The caption is misleading: "was X last month" shows the account's CURRENT balance, not a
  > historical one.** `ReconcileAccountsStep.swift:119` formats `account.currentBalance` — the *same*
  > value that prefills the field directly above it. So on first open the caption and the input always
  > show the identical number (observed: field `7095` with caption "was 7,095 RON last month"; field
  > `2365` with "was 2,365 RON last month"). It only *looks* historical once the user edits the field,
  > because the caption keeps showing the stored value while the field shows the new one.
  >
  > There is no month-over-month history to read from — `MonthlyRecord` is never written
  > (`DOMAIN-CONTRACT.md §5`). Reproduce the string verbatim for parity; do not attempt to source a real
  > previous-month figure, because none exists. Worth a `PARITY-GAPS.md` note as misleading upstream copy.
- `iconColor`: emergency → `warning`, savings → `accentPrimary`, personal → `accentSecondary`,
  default `.secondary` (a **fourth** account-colour mapping — see `DOMAIN-CONTRACT.md §1`)
- The binding reads `balances[account.id] ?? account.currentBalance` and writes `balances[account.id]`

### 7.3 Step 3 — `TransferPlanStep.swift`

`VStack(spacing: 24)`, `padding(.vertical, 16)`. `ScrollView` →
`GlassEffectContainer(spacing: 16)` → `VStack(spacing: 16)`, `padding(.horizontal, 24)`.

Order: summary → transfers → primary row → verification badge; then a fixed bottom button.

1. **`TransferPlanSummary`** (`.glassCard()`), `VStack(alignment: .leading, spacing: 12)`:
   - `Label("Your Transfer Plan", icon: list.clipboard.fill in accentPrimary)` `.headline`
   - `HStack`: `Text("Income").secondary` + `Spacer` + amount — `.subheadline`
   - `HStack`: `Text("Expenses").secondary` + `Spacer` + amount prefixed `"-"` when `> 0`,
     coloured `DiamerisColors.negative` — `.subheadline`
   - `Divider()`
   - `HStack`: `Text("Available").bold` + `Spacer` + `transferPlan.availableIncome` `.bold` — `.subheadline`
2. **`TransferPlanTransfers`** (`.glassCard()`) — rendered only when
   `hasAccountAllocations || !accountExpenseTransfers.isEmpty || remainingMoney > 0`.
   `VStack(alignment: .leading, spacing: 16)`:
   - `Text("Transfers to make").font(.headline)`
   - one `AllocationTransferRow` per `accountAllocations`
   - one `ExpenseTransferRow` per `accountExpenseTransfers`
   - `RemainingMoneyRow` when `remainingMoney > 0`

   All three rows share the shape `HStack(spacing: 12)`: glyph `.body` tinted, in a **32 pt** frame →
   `VStack(alignment: .leading, spacing: 4)` of a `.subheadline .bold` title and an optional
   `.caption .secondary` subtitle → `Spacer` → **`"+" + formattedAmount`** `.subheadline .bold` in
   `DiamerisColors.positive`.

   | Row | glyph / colour | title | subtitle |
   |---|---|---|---|
   | `AllocationTransferRow` | `allocation.icon`; primary→`.secondary`, emergency→`warning`, savings→`accentPrimary`, personal→`accentSecondary`, else `.secondary` | `allocation.accountName` | **"Completes fund to 100%!"** when emergency && `isComplete`, else `progressChangeDisplay` ("86% → 92%"), else none |
   | `ExpenseTransferRow` | `arrow.right.circle.fill` accentSecondary | `"Transfer to \(accountName)"` | `"for \(expenseNames.joined(", "))"` |
   | `RemainingMoneyRow` | `banknote.fill`/`person.fill`/`building.columns.fill`; accentPrimary/accentSecondary/`.secondary` | **"Savings"** / **"Personal"** / **"Primary"** | `"remaining money"` |
   > ### 🔍 Narrow-state matrix for the transfer plan — the strings tests miss
   >
   > I enumerated **every** user-visible string in the transfer-plan family (`TransferPlanStep`,
   > `TransferPlanScreen`, `ReconcileAccountsStep`, `SalaryEntryStep` — 37 strings) and checked each
   > against this document: **all 37 are specified, no gaps.** But coverage isn't the risk here —
   > *reachability* is. These are the states that only appear in a narrow window:
   >
   > | # | Condition | Renders | Screen / source |
   > |---|---|---|---|
   > | 1 | emergency && `isComplete` (allocation *exactly finishes* the fund) | **"Completes fund to 100%!"** (`dashboard` → "Completează fondul la 100%!") | New Month, `TransferPlanStep.swift:190` |
   > | 2 | `isComplete`, **any** account type | **"Target reached!"** + green `checkmark.circle.fill` (`onboarding` → "Țintă atinsă!") | Onboarding, `TransferPlanScreen.swift:381` |
   > | 3 | both progresses set, not complete | `progressChangeDisplay` — `"86% → 92%"` | both |
   > | 4 | emergency with **no** `emergencyMultiplier` | **no subtitle at all** — `progressChangeDisplay` is nil unless *both* progresses exist | both |
   > | 5a | fund already full, **Prioritized** mode, account **has** a multiplier | ⚠️ **an "Emergency Fund … +0 RON" row IS rendered** | `TransferCalculator.swift:109-112` appends it because `targetAmount != nil` even though `amount == 0`; `TransferPlanStep.swift:129` iterates `accountAllocations` with **no `amount > 0` filter**, and the `+` prefix at `:177` is unconditional |
   > | 5b | fund already full, **Split** mode | **no emergency row at all** | `TransferCalculator.swift:176-178` sets `emergencyOverflow` and appends **nothing** |
   > | 5c | fund full, Prioritized, account has **no** multiplier | no row | `targetAmount == nil` *and* `amount == 0`, so the append condition fails |
   > | 6 | `!isBalanced` | **New Month: absolutely nothing.** The badge is `if isBalanced` only — there is no warning variant | `TransferPlanStep.swift:333-349` |
   > | 7 | `!isBalanced` | **Onboarding: an orange `exclamationmark.triangle.fill` row**, and "All accounted for!" is omitted | `TransferPlanScreen.swift:257-279` |
   > | 8 | `remainingMoney == 0` | `RemainingMoneyRow` hidden (New Month); whole "Remaining Money" section hidden (onboarding) | both |
   > | 9 | `!hasTransfers` | the entire "Transfers to make" card is hidden | `TransferPlanStep.swift:124` |
   >
   > **⚠️ Rows 1 and 2 are the sibling pair.** The *same* `isComplete` flag produces **two different
   > strings on two different screens**, in **two different catalogs**. They are not interchangeable and
   > must not be unified. Note also that row 1 additionally requires `accountType == .emergency` while
   > row 2 does not — so a completed *savings* target would show "Target reached!" in onboarding and
   > nothing in New Month.
   >
   > **⚠️ Rows 6 and 7 are the asymmetric pair**, and row 6 is the more dangerous: an unbalanced plan in
   > the New Month flow renders **no indication whatsoever**. Do not "improve" it by borrowing
   > onboarding's warning row — that would be a silent divergence.
   >
   > Rows 4, 5, 6 and 9 are all *negative space* — the correct output is nothing. Those are the cases a
   > screenshot suite cannot assert by looking, so they need explicit absence assertions.

   #### Two verified numeric behaviours in this section

   **The emergency allocation is capped at exactly what the fund still needs**, and the remainder spills
   to savings — it is not the requested split amount. Observed in Split mode with the fund 100 short:
   Emergency receives **`+100 RON`** (not the requested 473), and Savings receives
   `1182.5 − 100 = 1082.5` → **`1,082 RON`** (half-even on `.5` → 1082, since 2 is even). The mechanism
   is `calculateEmergencyAllocation`'s `min(remaining, availableSavings)` plus the split-mode
   `emergencyOverflow` path — see `DOMAIN-CONTRACT.md §3`.

   **Two rows can name the same account.** In the case above, "Savings" appears **twice** — once for its
   split allocation and once carrying `remainingMoney`. `accountAllocations` and the remaining-money row
   are separate list entries, and `TransferPlan` is an **ordered list, never a map keyed by account**
   (R25 row 8). Render in array order; do not group, dedupe, or sum by account id. `AccountAllocation.id`
   is a fresh `UUID()` per computation, so it is not a stable React key either — use the array index or a
   composite of (accountId, position).

3. **`PrimaryAccountRow`** (`.glassCard()`): `building.columns.fill` `.secondary` in a 32 pt frame →
   `Text("Primary").subheadline.bold` + `Text("stays for automatic payments").caption.secondary` →
   `Spacer` → `remainsInPrimary` `.subheadline .bold` (**no `+` prefix**, and not tinted)
4. **`TransferPlanVerificationBadge`** — rendered **only when `isBalanced`** (nothing is shown when the
   plan does *not* balance): `HStack(spacing: 12)` `checkmark.circle.fill` in `positive` +
   `Text("All amounts add up correctly").subheadline.secondary`; `padding(12)`, `maxWidth: .infinity`,
   `positive.opacity(0.1)` in a `RoundedRectangle(12)`.
5. **Bottom button** (outside the ScrollView): `Button` →
   `Label("Done - I made the transfers", systemImage: "checkmark")`, `maxWidth: .infinity`,
   `padding(.vertical, 12)`, `.buttonStyle(.glassProminent)`, `padding(.horizontal, 24)`.
   Note the label uses a plain hyphen-minus, not an en dash.

### 7.4 Completion side effects — `MainTabView.handleNewMonthCompletion` (`:306-332`)

1. `HAPTIC: success()`
2. If the stored `Income.amount != data.income`, overwrite it (the entered salary becomes the new
   baseline for **all** future calculations)
3. `updatedBalances = dashboardViewModel.computeUpdatedBalances(from: data)`, which per **R1** now
   delegates to **`Domain/UseCases/BalanceReconciler.updatedBalances(plan:accounts:reconciledBalances:)`**
   (`DashboardViewModel.swift:337-343`). The rule — verified behaviour-identical to the pre-move code:

   > 🚧 **PENDING R10 — do not implement the server path from this subsection yet.** As of this writing
   > `BalanceReconciler` still uses `balances[id, default: 0] += …` (lines 37, 42, 50, 54). R10 requires
   > it to *defend* its precondition by seeding a missing account from `currentBalance` instead of `0`.
   > Re-read this subsection after Backend confirms; the iOS-observable behaviour will not change (see
   > why below), but the server contract will.
   >
   > **The precondition, and why `default: 0` is currently harmless on iOS.**
   > `NewMonthSheet.setupInitialValues` seeds **every** account —
   > `for account in viewModel.accounts { accountBalances[account.id] = account.currentBalance }`
   > (`NewMonthSheet.swift:108-110`) — so the dictionary handed to the reconciler is always complete and
   > the `default: 0` branch is unreachable in the app.
   >
   > Note this is **wider than what step 2 lets you edit**: step 2 renders only `emergency`/`savings`/
   > `personal` (`ReconcileAccountsStep.swift:30-36`), so `primary`, `joint` and `other` are seeded with
   > their persisted balance but never shown. That is correct — and it is exactly the trap. A caller that
   > seeds only the *reconcilable* three would make a Joint account receiving an expense transfer compute
   > `0 + amount`, **silently discarding its existing balance**. Any web/server caller must either seed
   > all accounts as iOS does, or wait for R10's defended version.
   - start from the reconciled balances
   - `+=` every `accountAllocations` amount
   - `+=` every `accountExpenseTransfers` amount
   - `+=` `remainingMoney` to the destination account — **except** for `.primary`, which is a
     deliberate `break` (no-op)
   - finally **assign** `balances[primary] = plan.remainsInPrimary`
4. Write each new balance onto the matching `Account`
5. `try? modelContext.save()`; on failure only a `print` — **no user-visible error**.
   The save triggers `DataObserver` → `refreshAllData()`.

⚠️ **No `MonthlyRecord` is created**, so nothing is archived. Repeating the flow twice in one month
double-applies allocations to the reconciled balances.

⚠️ **DISCREPANCY (whole feature):** `Docs/MVP/09-TransferPlanning.md` describes a *persistent transfer
checklist* — per-transfer checkboxes, a Copy button beside each amount, a `MonthlyTransferStatus`
model, an "All transfers done" state with "[Reset for Next Month]", and a 7-step
"📱 HOW TO TRANSFER" instruction panel. **None of that ships.** The shipped New Month flow instead
edits balances.

---

## 8. Settings — `Diameris/Features/Settings/SettingsSheet.swift`

Presented as a sheet from the Dashboard toolbar. `NavigationStack` → `Form`,
`.scrollIndicators(.hidden)`. `navigationTitle("Settings")`, `.inline`.

**Toolbar:** `Button("Cancel")` → dismiss **without saving**;
`Button("Save")` `.bold()` → `saveChanges()` then dismiss.
All edits are staged in `@State` and only written on Save (`:472-498`).
`onAppear` → `loadCurrentValues()` (`:443-470`).

Sections in order: Profile → Savings → Accounts → Remaining Money.

### 8.1 Profile
header `Text("Profile")`
- `HStack`: `Text("Name")` + `Spacer` + `TextField("Your name", text: $userName)`, trailing-aligned,
  `.secondary`
- `Picker("Currency", selection: $selectedCurrency)` over `Currency.allCases` by `displayName`

### 8.2 Savings
header `Text("Savings")`, footer = `savingsSectionFooter`:
- **"Total exceeds available income. Amounts will be reduced proportionally."** when
  `allocationMode == .split && resolvedSplitTotal > availableIncome && availableIncome > 0`
- else **"Savings are calculated from income after expenses."**

Contents:
- **Allocation mode**: `VStack(alignment: .leading, spacing: 12)` of
  `Picker("Allocation Mode").pickerStyle(.segmented)` (Priority / Split) +
  `Text(allocationMode.description).caption.secondary`
- **If `.prioritized`**:
  - `Picker("Savings Type").pickerStyle(.segmented)` → Percentage / Fixed Amount
  - **If `.percentage`**:
    - `VStack`: `HStack` `Text("Savings Rate")` + `Spacer` + `Text("\(Int(pct*100))%")` `.secondary`
      `.monospacedDigit()`; then `Slider(value:, in: 0.05...0.50, step: 0.01).tint(accentPrimary)`
    - `Toggle("Savings Boost", isOn: $boostEnabled).tint(accentPrimary)` — ⚠️ **no `canEnableBoost`
      guard here**, unlike the onboarding screen; the boost can be enabled at any rate
    - When boost on: `HStack` `Text("Boost Multiplier")` + `Spacer` +
      `Picker` `.segmented` with `Text("2×").tag(2.0)` / `Text("3×").tag(3.0)`, `frame(width: 100)`
    - When boost on: `HStack` `Text("Effective Rate")` + `Spacer` +
      `Text("\(Int(min(100, pct * multiplier * 100)))%")` in accentPrimary `.medium .monospacedDigit()`
  - **If `.fixedAmount`**: `HStack` `Text("Monthly Savings")` + `Spacer` +
    `TextField("0")` `.decimalPad`, trailing, `frame(width: 160)` + `Text(currencyCode).secondary`
- **If `.split`**:
  - **Emergency block** — only when an `.emergency` account exists:
    `Label("Emergency", systemImage: "shield.fill").subheadline`;
    `Picker("Emergency").segmented` (Percentage / Fixed Amount);
    then either a `Text("Rate")` + `%` row with `Slider(0.05...0.50, step: 0.01).tint(accentSecondary)`,
    or a right-aligned `TextField("0")` `frame(width: 160)` + currency code
  - **Savings block** — only when `accountType == .savings || isPrimarySavings` exists (`:61-63`).
    Same structure with `Label("Savings", systemImage: "banknote.fill")` and `Picker("Savings")`
  - **Split total row** — when either block shows: `HStack` `Text("Total Monthly").bold` + `Spacer` +
    formatted `resolvedSplitTotal` `.bold .monospacedDigit()`, coloured **`.red` when
    `resolvedSplitTotal > availableIncome`** else accentPrimary
  - `availableIncome = max(0, income - Σ enabled expenses' monthlyAmount)` (`:49-56`)

### 8.3 Accounts
header `Text("Accounts")`, footer `Text("Tap an account to edit its settings.")`
- one `Button` (`.buttonStyle(.plain)`) per account, sorted by `sortOrder`, opening §8.5.
  Row (`:364-397`): type glyph in `accountType.color` in a 32 pt frame →
  `VStack(alignment: .leading, spacing: 4)`:
  - `Text(account.name).primary`
  - `HStack(spacing: 8)`: `Text(accountType.displayName).caption.secondary`;
    when `isPrimarySavings`, `Text("• " + "Primary")` `.caption` accentPrimary;
    when `emergencyMultiplier != nil`, the multiplier badge
  → `Spacer` → `chevron.right` `.caption .tertiary`
- **Multiplier badge** (`:418-437`) — `.caption` in accentSecondary, built by concatenation:
  - no cap: **`"• 3× income"`** — `"• \(Int(multiplier))× \("income".localized)"`
  - with cap: **`"• 3× income (max 40,000 RON)"`** —
    `"• \(m)× \(income) (\("max".localized) \(capFormatted))"`
  ⚠️ Assembled from the fragments `"income"` and `"max"`, so RO word order is fixed. Uses
  `userProfile?.currencyCode ?? "RON"` (**the saved** currency, not the staged `selectedCurrency`).

> ### ✅ `Emergency␣␣• 3× income` — the gap is LAYOUT, not a double space
>
> Answering the whitespace question directly: **there is no double space in any string.** The subtitle is
> an `HStack(spacing: Spacing.xs)` — an **8 pt layout gap** — containing two-to-three independent `Text`
> views (`SettingsSheet.swift:373-388`):
>
> | # | View | Content | Colour | Condition |
> |---|---|---|---|---|
> | 1 | `Text` | `account.accountType.displayName` → `"Emergency"` | `.secondary` | always |
> | 2 | `Text` | `"• " + "Primary"` | `accentPrimary` | only if `isPrimarySavings` |
> | 3 | `Text` | `emergencyBadgeText(…)` → `"• 3× income"` | `accentSecondary` | only if `emergencyMultiplier != nil` |
>
> Each string contains **single** spaces only — `"• \(m)× \(income)"` (`:433-436`). The runtime snapshot
> showing two separate elements is therefore correct, and the doubled space in a flattened
> accessibility-label reading is a concatenation artefact of joining sibling views, not rendered text.
>
> **For the web:** render 2–3 separate inline elements with an **8 px** gap (`--space-xs`), each with its
> own colour. Do **not** emit `"Emergency  • 3× income"` as one string with two spaces, and do not
> "correct" it to a single space either — both would be wrong, because it is not one string at all.
> Whitespace-tolerant matching is the right call for the assertion; the DOM should have three nodes.

### 8.4 Remaining Money
header `Text("Remaining Money")`, footer `Text("Where leftover money goes after savings allocation.")`
- `Picker("Destination", selection: $remainingDestination).pickerStyle(.menu)` over
  `RemainingMoneyDestination.allCases`, using the **file-private** `displayName`
  (`:698-706`): "Primary Savings" / "Personal Account" / **"Primary Account"**.
  ⚠️ **DISCREPANCY:** Domain's `displayName` for `.primary` is **"Keep in Primary"**; this screen
  shows "Primary Account". Two labels for one case.

### 8.5 `AccountEditorSheet` — `SettingsSheet.swift:503-694`

Presented via `.sheet(item: $selectedAccount)`. `NavigationStack` → `Form`.
`navigationTitle("Edit Account")`, `.inline`. Toolbar `Button("Cancel")` /
`Button("Save").bold()` → `saveAccount()` + dismiss. `onAppear` → `loadAccountValues()`.

Sections:
1. `TextField("Account Name", text: $name)` — no header
2. header `Text("Account Type")` — `Picker("Type")` over all 6 `AccountType` cases as
   `Label(displayName, systemImage: icon)`. ⚠️ **No emergency-uniqueness guard here** — Settings can
   create a second emergency account, which onboarding prevents.
3. Only when `accountType == .savings`: header-less section with
   `Toggle("Primary Savings Account", isOn: $isPrimarySavings).tint(accentPrimary)`, footer
   `Text("The primary savings account receives automatic savings allocation.")`.
   ⚠️ Turning this on does **not** clear the flag on other accounts (unlike onboarding's
   `togglePrimarySavings`) — two primary-savings accounts are possible; the calculator then silently
   uses whichever comes first.
4. Only when `accountType == .emergency` — header `Text("Emergency Fund Target")`,
   footer `Text("The fund target will be capped at this amount regardless of income multiplier.")`
   shown only when the cap toggle is on:
   - `Picker("Target", selection: $emergencyMultiplier)` with four hardcoded rows:
     `Text("3× " + "monthly income")`, `"4× …"`, `"5× …"`, `"6× …"` tagged 3.0/4.0/5.0/6.0.
     ⚠️ Concatenated with the localized fragment `"monthly income"`.
   - When `monthlyIncome > 0`, the target row: `Text("Target Amount")` + `Spacer` + either
     the calculated target **strikethrough `.tertiary`** followed by the effective target `.secondary`
     (when the cap is active), or just the effective target `.secondary`
   - `Toggle("Set maximum amount", isOn: $emergencyHardCapEnabled).tint(.orange)`,
     `accessibilityHint("Caps the emergency fund target at a fixed amount")`
   - When on: `HStack` `Text("Maximum")` + `Spacer` + `TextField("0")` `.decimalPad`, trailing,
     `frame(width: 120)`, `accessibilityLabel("Maximum amount")`
5. header `Text("Balance")` — `HStack` `Text("Current Balance")` + `Spacer` +
   `TextField("0", value: $currentBalance, format: .number)` `.decimalPad`, trailing, `frame(width: 120)`.
   ⚠️ This is the **only** amount field in the app that uses SwiftUI's `format: .number` binding rather
   than `AmountFormatter` — its parsing and display are locale-driven and differ from every other field.

**Save logic** (`:602-613`), reproduce the coercions:
```
account.name             = name
account.accountType      = accountType
account.isPrimarySavings = (accountType == .savings) ? isPrimarySavings : false
account.emergencyMultiplier = (accountType == .emergency) ? emergencyMultiplier : nil
account.emergencyHardCap    = (accountType == .emergency && hardCapEnabled && hardCap > 0) ? hardCap : nil
account.currentBalance   = currentBalance
```
⚠️ `isPrimary` and `sortOrder` are **not editable anywhere in the app** after onboarding.

⚠️ **DISCREPANCY (Settings scope):** `Docs/MVP/11-Settings.md` specifies MANAGE (Accounts, **Categories**),
DATA (**Export Data**, **Reset All Data**), ABOUT (**Version**, **Privacy Policy**, **Support**), a
dedicated Currency picker screen with symbol subtitles, a Savings-rate screen with a
"💡 RECOMMENDATION" block, and an Emergency-target screen with stops **1/2/3/6/12** and its own
recommendation block. The shipped sheet has **none** of those: no export, no reset, no about, no
category link, no recommendation copy, and multiplier stops 3/4/5/6.

---

## 9. Developer tools (`#if DEBUG` only) — `Diameris/Features/Dev/DevDebugView.swift`

Reached from the Dashboard toolbar's `hammer.fill` button, which is itself inside `#if DEBUG`
(`DashboardView.swift:46-50`). Screenshot: `reference-screens/` Developer Tools.

**Recommendation: do NOT port this as a user-facing screen, but DO port two of its actions as a
dev-only affordance.** Arguing it explicitly, since it was left as my call:

- **Against porting as a screen.** The whole view *and* its entry point are compiled out of Release.
  A shipping user cannot reach it and cannot know it exists, so it is not part of "the app the user
  sees" — the standard the team adopted for R6. None of its strings are localized (all 20+ are raw
  English literals), which is itself evidence it was never intended as product surface. Specifying it
  as a parity target would also mean reproducing `Bundle.main.infoDictionary` and a Python-script
  importer, neither of which has a web meaning.
- **For porting two actions.** "Clear All Data & Reset" and "Import from Python Script" are exactly
  what the parity harness needs: a deterministic reset and a deterministic seed. `expenses_import.json`
  is already the golden fixture (`DOMAIN-CONTRACT.md §8.2`). Without them, every Playwright run has to
  reach a known state through the UI.

  **So:** expose them as a dev-only route (e.g. `/__dev`, hidden behind the same build flag as the iOS
  one) with just *reset* and *seed-from-fixture*. Not a `PARITY-GAPS.md` entry, because a gap implies a
  shipped behaviour we chose not to match — this is a non-shipped behaviour, which is a different thing.
  I have written it up as a **tooling requirement**, not a parity gap. Flip that call if you'd rather
  see it enumerated in `PARITY-GAPS.md` for completeness.

Observed "App Info" values, confirmed against `Diameris.xcodeproj/project.pbxproj`:

| Field | Live value | pbxproj key |
|---|---|---|
| Version | **0.1** | `MARKETING_VERSION = 0.1` |
| Build | **1** | `CURRENT_PROJECT_VERSION = 1` |
| Bundle ID | **ro.svc.Diameris** | `PRODUCT_BUNDLE_IDENTIFIER = ro.svc.Diameris` |

⚠️ The project also defines a second app target with `PRODUCT_BUNDLE_IDENTIFIER = "ro.svc.Diameris-QA"`
and `MARKETING_VERSION = 1.0` (the "QA target" from commit `248be49`). The observed 0.1 / ro.svc.Diameris
confirms the walkthrough used the **main** target. If a screenshot ever shows `1.0`, it came from the QA
target and its data store is separate.

Full contents below for completeness.

`NavigationStack` → `List`, `navigationTitle("Developer")`. **No strings here are localized.**
- Section "Onboarding": `LabeledContent("Completed", value: "Yes"/"No")`;
  `Button("Reset Onboarding Flag")`; `Button("Clear All Data & Reset", role: .destructive)` →
  `confirmationDialog("Reset All Data?")` with message
  "This will delete all your data and show onboarding again. This cannot be undone." and buttons
  "Reset Everything" / "Cancel". Deletes `UserProfile`, `Income`, `Expense`, `Account`,
  `SavingsAllocation` — ⚠️ **not** `CustomCategory` or `MonthlyRecord`.
- Section "Import Data": `Label("Import from Python Script", systemImage: "square.and.arrow.down")` →
  reads `expenses_import.json` from the bundle, parses `ExpenseImportData`, **deletes all expenses**,
  re-imports, upserts accounts *by type*, upserts the savings allocation. Result shown in an
  `.alert` titled "Import Successful"/"Import Failed" with a generated message like
  `"Imported 12 expenses, 2 new accounts, 1 updated, savings 25% (boost off)!"`.
  ⚠️ `emergencyFund.targetMultiplier` from the JSON is parsed and **ignored**.
- Section "Data": `NavigationLink("View Stored Data")` → `DataInspectorView` listing
  "User Profiles (n)", "Incomes (n)", "Expenses (n)", "Accounts (n)" with a "PRIMARY" pill.
- Section "App Info": Version / Build / Bundle ID from `Bundle.main.infoDictionary`.

---

## 10. Consolidated discrepancy register

Ordered by porting risk.

| # | Topic | `Docs/MVP` | Code | Action for web |
|---|---|---|---|---|
| 1 | **Loans** | Full feature (`06-Loans.md`, 464 lines) | **absent** | Do not port. Confirm it is out of scope. |
| 2 | **Budget analysis / health score** | Full feature (`10`, 524 lines) | **absent**; Insights = "Coming soon" | Do not port. |
| 3 | **Transfer checklist** | checkboxes, Copy, `MonthlyTransferStatus`, instructions (`09`) | New Month balance-edit flow | Port the code's flow. |
| 4 | **Default categories** | **6**, UUIDs `00000000-…-0001..0006`, Lifestyle=`heart.fill`/`#EC4899`, Housing=`house.fill`/`#F59E0B`, Pets=`pawprint.fill`/`#10B981`, Health=`figure.run`/`#06B6D4`, Subs=`tv.fill`/`#8B5CF6` (`04:62-131`) | **8**, UUIDs `D1A00001-…`, Lifestyle=`sparkles`/`#F59E0B`, Housing=`house.fill`/`#10B981`, Pets=`pawprint.fill`/`#EC4899`, Health=`heart.fill`/`#EF4444`, Subs=`repeat.circle.fill`/`#8B5CF6`, **+ Food/Groceries** `cart.fill`/`#22C55E`, **+ Entertainment** `tv.fill`/`#06B6D4` | **Port the code's 8 with the `D1A0…` UUIDs** — existing user data depends on them. |
| 5 | **Account types** | `checking, savings, emergency, joint, other`; icons `building.columns`, `banknote`, `shield.checkered`, `person.2`, `folder` (`08:40-66`) | `primary, emergency, savings, personal, joint, other`; all `.fill` variants | Port the code's 6. |
| 6 | **Emergency fund model** | separate `EmergencyFund` entity (`currentBalance`, `targetMultiplier` 1–12) | fields on `Account`: `emergencyMultiplier` (3/4/5/6), **`emergencyHardCap`** (new, undocumented), `currentBalance` | Port the code's model, including the hard cap. |
| 7 | **Onboarding shape** | 6 steps: Welcome, Name, Income, **Expenses**, **Accounts**, Completion summary; back navigation; "Step X of 6"; inline validation | 7 steps: welcome, name, income, **accounts**, **expenses**, **savings**, transferPlan; no back nav; 5 dots, no text; no error messages | Port the code's flow. Decide whether to add back navigation. |
| 8 | **Split allocation mode** | **not documented at all** | fully implemented, with percentage/fixed sub-modes per side and proportional scale-down | Port from code; there is no spec to check against. |
| 9 | **Savings Boost** | Phase 2, "documented for context" (`07:322-324`) | ships (3× default, auto-disable when it would exceed 100 %) | Port. Note Settings lacks the auto-disable guard. |
| 10 | **Savings recommendations** | 5-tier assessment + messages + `savingsRecommendation()` (`07:129-180`) | **absent** (only the static "Great savings rate!" badge at 20–30 %) | Do not port. |
| 11 | **`RemainingMoneyDestination.primary` label** | n/a | Domain says **"Keep in Primary"**, `SettingsSheet` says **"Primary Account"** | Pick one; recommend Domain's. |
| 12 | **AccountType colours** | n/a | **4 different mappings** — `AccountType+Color`, `AccountBalancesRow:124`, `TransferPlanStep:195`, `ReconcileAccountsStep:126` | Canonicalise on `AccountType+Color`; note the visual change. |
| 13 | **Expense amount validation** | `amount >= 0` — 0 explicitly allowed (`03:302-304`); name ≤ 100; max 10 M | `amount > 0` required; **no** length or max limits | Port the code's rule, or fix deliberately. |
| 14 | **Category uniqueness** | duplicate names rejected (`04:425`) | no check | Consider adding. |
| 15 | **Category delete → expenses** | "Become uncategorized" (`04:474`) | dangling `categoryId`; renders as an extra "Uncategorized" group | Consider nulling the FK. |
| 16 | **`AddAccountSheet` "Emergency" chip** | n/a | creates a **`.savings`** account (`AddAccountSheet.swift:65`) | Looks like a bug; flag before porting. |
| 17 | **`Account(from: entry)` drops the id** | n/a | `Account.swift:46` regenerates the UUID, breaking onboarding `linkedAccountId` links | Fix in the web port. |
| 18 | **`"Total \(x) Expenses"` localization key** | n/a | interpolated string used as a key → never resolves; RO shows English | Fix in the web port. |
| 19 | **Income currency locales** | `ro_RO` / `de_DE` / `en_US` per currency (`02:76-82`) | none — `AmountFormatter` forces `","` grouping and 0 decimals for all | Port the code's behaviour. |
| 20 | **Currency `symbol`** | shown as a subtitle in the picker (`11:172-178`) | `Currency.symbol` exists but is **never rendered**; the code shows everywhere | Optional improvement. |
| 21 | **`AmountFormatter.parse` comma handling** | n/a | `","` → `"."`, so `"1,234"` = **1.234** | Reproduce or fix deliberately; affects every input. |
| 22 | **`MonthlyRecord`** | month history (`10`) | model exists, **never written or read** | Do not port yet; keep the shape for later. |
| 23 | **Settings scope** | Export, Reset, Version, Privacy, Support, Categories link, recommendation blocks, multiplier 1/2/3/6/12 | none of it; multiplier 3/4/5/6 | Port the code's Settings. |
| 24 | **Reduce Motion** | required (`DesignGuidelines:339-342, 454`) | `accessibilityReduceMotion` **never read** | **Implement `prefers-reduced-motion` on web** — a genuine improvement. |
| 25 | **iPad / adaptive layout** | `NavigationSplitView`, `ViewThatFits`, adaptive grids (`DesignGuidelines:270-303`) | iPhone-only `NavigationStack` | Web is responsive by nature; design breakpoints fresh. |
| 26 | **Animation budget** | "under 300 ms" (`DesignGuidelines:456`) | 400/500/600/1000 ms tokens actively used | Reproduce the code's timings. |
| 27 | **Foundation Models / AI** | every feature doc specifies an FM layer + deterministic fallback | **no FM code at all** | Nothing to port; the "fallback" *is* the shipped behaviour. |
| 28 | **Income cap** | 1,000,000 (`01:112`) vs 10,000,000 (`02:213`) — docs disagree with each other | no cap | Pick a cap if adding validation. |
