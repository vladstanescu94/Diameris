# DESIGN TOKENS — Diameris

Complete token extraction from `Packages/Core/DesignSystem/Sources/DesignSystem/`, the asset catalog,
and every hardcoded value found in feature code. The `--css` column is a *suggested* custom-property
name for the web port; adopt it wholesale so the tokens stay greppable.

Source files:
`Colors.swift` (89 L) · `Spacing.swift` (44 L) · `CornerRadius.swift` (51 L) · `Animation.swift` (103 L) ·
`ComponentSize.swift` (113 L) · `IconSize.swift` (56 L) · `GlassComponents.swift` (55 L)

---

## 1. Colors

### 1.1 Brand accents — adaptive

Defined programmatically via `Color(light:dark:)`, which wraps a `UIColor` dynamic provider keyed on
`traitCollection.userInterfaceStyle` (`Colors.swift:65-74`). **Not read from the asset catalog at runtime.**

| Token | Light | Dark | Tailwind equivalent | `--css` |
|---|---|---|---|---|
| `DiamerisColors.accentPrimary` | `#D946EF` | `#E879F9` | fuchsia-500 / fuchsia-400 | `--accent-primary` |
| `DiamerisColors.accentSecondary` | `#06B6D4` | `#22D3EE` | cyan-500 / cyan-400 | `--accent-secondary` |
| `DiamerisColors.accentPrimaryLight` | `#D946EF` (fixed, non-adaptive) | — | — | `--accent-primary-light` |
| `DiamerisColors.accentPrimaryDark` | `#E879F9` (fixed, non-adaptive) | — | — | `--accent-primary-dark` |
| `DiamerisColors.accentSecondaryLight` | `#06B6D4` (fixed) | — | — | `--accent-secondary-light` |
| `DiamerisColors.accentSecondaryDark` | `#22D3EE` (fixed) | — | — | `--accent-secondary-dark` |

References: `Colors.swift:13-16, 19-20, 26-29, 32-33`.

**Asset catalog cross-check** — `Diameris/Resources/Assets.xcassets/` contains `AccentPrimary.colorset`,
`AccentSecondary.colorset` and `AccentColor.colorset` with sRGB float components that decode to exactly
the same hexes:

| Colorset | Light components | → hex | Dark components | → hex |
|---|---|---|---|---|
| `AccentPrimary` / `AccentColor` | r .851 g .275 b .937 | `#D946EF` | r .910 g .475 b .976 | `#E879F9` |
| `AccentSecondary` | r .024 g .714 b .831 | `#06B6D4` | r .133 g .827 b .933 | `#22D3EE` |

`AccentColor` == `AccentPrimary` (the app tint). ⚠️ These colorsets are **dead weight** — no code
references `Color("AccentPrimary")`. `Docs/DesignGuidelines.md:243-254` prescribes the asset-catalog
approach; the code moved to programmatic. Values agree, so no functional discrepancy.

### 1.2 Semantic colors

| Token | Value | Resolves to | `--css` |
|---|---|---|---|
| `DiamerisColors.positive` | `= accentSecondary` | `#06B6D4` / `#22D3EE` | `--color-positive` |
| `DiamerisColors.negative` | `Color.red` (system) | `#FF3B30` light / `#FF453A` dark | `--color-negative` |
| `DiamerisColors.warning` | `Color.orange` (system) | `#FF9500` light / `#FF9F0A` dark | `--color-warning` |
| `DiamerisColors.neutral` | `Color.secondary` (system) | `rgba(60,60,67,0.6)` / `rgba(235,235,245,0.6)` | `--color-neutral` |

`Colors.swift:40-49`. The `.red`/`.orange`/`.secondary` hexes above are Apple's documented
`systemRed` / `systemOrange` / `secondaryLabel` values — **not** stated in the repo; verify against a
running app if exactness matters.

### 1.3 System colors used directly in feature code (must be mapped)

| SwiftUI color | iOS value (light / dark) | Where used | `--css` |
|---|---|---|---|
| `.primary` (label) | `#000000` / `#FFFFFF` | all body text | `--label-primary` |
| `.secondary` (secondaryLabel) | `rgba(60,60,67,.6)` / `rgba(235,235,245,.6)` | ubiquitous — subtitles, captions | `--label-secondary` |
| `.tertiary` (tertiaryLabel) | `rgba(60,60,67,.3)` / `rgba(235,235,245,.3)` | `EmergencyProgressCard:52`, `SavingsSlider:143,155`, `ReconcileAccountsStep:121`, `SettingsSheet:395,669` | `--label-tertiary` |
| `.green` (systemGreen) | `#34C759` / `#30D158` | `TransferPlanScreen:222,232,260,373,383`, `AccountRow:282,288,318` | `--color-green` |
| `.orange` (systemOrange) | `#FF9500` / `#FF9F0A` | `ExpensesScreen:83,94,107`, `SavingsScreen:295,314,322`, `EmergencyMultiplierPicker:78,101,110,136`, `AccountRow:282,288`, `TransferPlanScreen:260,373,393`, `SettingsSheet:646` | `--color-orange` |
| `.red` (systemRed) | `#FF3B30` / `#FF453A` | `SettingsSheet:335` (split total over budget) | `--color-red` |
| `.yellow` (systemYellow) | `#FFCC00` / `#FFD60A` | `SavingsScreen:286` (bolt), `TransferPlanScreen:284` (lightbulb), `AccountRow:301` (star) | `--color-yellow` |
| `.purple` (systemPurple) | `#AF52DE` / `#BF5AF2` | `AccountType.personal` colour, `AccountBalancesRow:131` (joint), `TransferPlanScreen:416` | `--color-purple` |
| `.pink` (systemPink) | `#FF2D55` / `#FF375F` | `AccountType.joint` colour | `--color-pink` |
| `.cyan` (systemCyan) | `#32ADE6` / `#64D2FF` | `CelebrationEffect:30` confetti palette | `--color-cyan` |
| `.white` | `#FFFFFF` | selected-state text (`AccountTypeSelector:147`, `RemainingMoneyPicker:43-59`, `EmergencyMultiplierPicker:73`), slider thumb (`SavingsSlider:102`) | `--color-white` |
| `.gray` | `#8E8E93` | hex-parse fallback (`ExpenseCategoryCard:48,87`, `CategoryManagementView:87,180,202`) | `--color-gray` |
| `.accentColor` | = `AccentColor` = `#D946EF`/`#E879F9` | `IconPicker:243`, `AddCategorySheet:162`, `ExpenseItemRow:75` | `--accent-primary` |

### 1.4 Category palette (data, not design tokens)

The 8 default categories carry their own `colorHex` — see `DOMAIN-CONTRACT.md §6`:
`#3B82F6` `#8B5CF6` `#F59E0B` `#10B981` `#EC4899` `#EF4444` `#22C55E` `#06B6D4`.

The **custom-category picker** offers 10 swatches (`CategoryManagementView.swift:120-131`), in this order:

| # | hex | comment in code | `--css` |
|---|---|---|---|
| 1 | `#3B82F6` | Blue | `--cat-blue` |
| 2 | `#8B5CF6` | Purple | `--cat-purple` |
| 3 | `#F59E0B` | Amber | `--cat-amber` |
| 4 | `#10B981` | Emerald | `--cat-emerald` |
| 5 | `#EC4899` | Pink | `--cat-pink` |
| 6 | `#EF4444` | Red | `--cat-red` |
| 7 | `#22C55E` | Green | `--cat-green` |
| 8 | `#06B6D4` | Cyan | `--cat-cyan` |
| 9 | `#F97316` | Orange | `--cat-orange` |
| 10 | `#6366F1` | Indigo | `--cat-indigo` |

Default selection: `#3B82F6`. These are Tailwind 500-weights. Swatch size **36×36pt**, circular, with a
white `checkmark` overlay when selected (`:179-188`).

⚠️ **DISCREPANCY:** `Docs/MVP/04-Categories.md:436-455` specifies a **17-colour** palette
(adds Yellow `#EAB308`, Lime `#84CC16`, Teal `#14B8A6`, Sky `#0EA5E9`, Violet `#8B5CF6`,
Purple `#A855F7`, Fuchsia `#D946EF`, Rose `#F43F5E`) with human-readable names shown in the UI. The
code ships **10** unnamed swatches. Port the code's 10.

### 1.5 Hex parsing

Two different parsers exist:
- `Color(hex: UInt)` — `Colors.swift:56-61`, bit-shift, used for the brand accents.
- `Color(hex: String)?` — **defined in the Expenses feature**, `ExpenseCategoryCard.swift:134-150`.
  Trims whitespace, strips `#`, **requires exactly 6 chars** else returns `nil`, `Scanner.scanHexInt64`.
  So `#FFF` and 8-digit `#RRGGBBAA` are unsupported; callers fall back to `.gray`.

---

## 2. Spacing — 8pt grid

`Spacing.swift:4-25`. Matches `Docs/DesignGuidelines.md:360-368` exactly.

| Token | pt | `--css` | Notes |
|---|---|---|---|
| `Spacing.xxs` | 4 | `--space-xxs` | badge vertical padding, tight VStacks |
| `Spacing.xs` | 8 | `--space-xs` | |
| `Spacing.sm` | 12 | `--space-sm` | |
| `Spacing.md` | 16 | `--space-md` | **default**; the padding inside `glassCard()` |
| `Spacing.lg` | 24 | `--space-lg` | screen-level horizontal padding |
| `Spacing.xl` | 32 | `--space-xl` | major section gaps, `.padding(.top)` above CTAs |
| `Spacing.xxl` | 48 | `--space-xxl` | `ExpenseListView` empty-state vertical padding |

Convenience view modifiers: `paddingSm()` = 12, `paddingMd()` = 16, `paddingLg()` = 24 (`:29-44`).

**Hardcoded spacing found outside the scale** (fix or reproduce deliberately):
`.padding(.vertical, 2)` in `AccountRow.swift:182,193` (badge) and `RemainingMoneyPicker.swift:45`
(VStack spacing 2); `.padding(.horizontal, 6)` in `DevDebugView.swift:267`.

---

## 3. Corner radius

`CornerRadius.swift:4-16`. Matches `DesignGuidelines.md:374-379`.

| Token | pt | `--css` | Used for |
|---|---|---|---|
| `CornerRadius.small` | 8 | `--radius-sm` | chips, tags, inline inputs, icon-picker cells |
| `CornerRadius.medium` | 12 | `--radius-md` | buttons, small cards, `CurrencyAmountField`, `OnboardingTextField`, `ExpenseRow` |
| `CornerRadius.large` | 16 | `--radius-lg` | **`glassCard()` default**, `AccountRow`, `ExpenseCategoryCard`, prompt cards |
| `CornerRadius.xl` | 24 | `--radius-xl` | large containers — *declared, never used in feature code* |

Also: `RoundedRectangle.small/.medium/.large/.xl` statics and `clipSmall()/clipMedium()/clipLarge()`
helpers (`:20-51`). `Capsule()` (fully rounded) is used for badges, progress tracks and pills —
`--radius-full: 9999px`. `RoundedRectangle(cornerRadius: 2)` for confetti particles
(`CelebrationEffect.swift:39`).

---

## 4. Typography

The project uses **only** SwiftUI semantic text styles — no `Font.system(size:)` for text, except the
three exceptions listed below. Values are the iOS **Large** (default) Dynamic Type sizes; every one
scales with the user's setting, which the web port should mirror with `rem` units off a
user-adjustable root size.

| SwiftUI style | Size (Large) | Weight | Line height | Suggested CSS | Where used |
|---|---|---|---|---|---|
| `.largeTitle` | 34 pt | regular | 41 pt | `--font-large-title: 2.125rem/1.21` | Welcome title, TransferPlan "Your First Month", income hero, Expenses total |
| `.title` | 28 pt | regular | 34 pt | `--font-title: 1.75rem/1.21` | `OnboardingHeader` title (non-hero), Insights placeholder |
| `.title2` | 22 pt | regular | 28 pt | `--font-title2: 1.375rem/1.27` | amount fields, `SalaryEntryStep` heading, impact amounts, icon-picker glyphs, `PrimaryAccountCard` balance |
| `.title3` | 20 pt | regular | 25 pt | `--font-title3: 1.25rem/1.25` | Welcome subtitle, `OnboardingTextField` input, `ReconcileAccountsStep` heading, split-mode % labels, account icons |
| `.headline` | 17 pt | **semibold** | 22 pt | `--font-headline: 1.0625rem/1.29; font-weight:600` | section titles, card titles, account names, amounts in transfer cards, currency code |
| `.body` | 17 pt | regular | 22 pt | `--font-body: 1.0625rem/1.29` | expense names, category names, amount inputs |
| `.callout` | 16 pt | regular | 21 pt | `--font-callout: 1rem/1.31` | *not used anywhere* |
| `.subheadline` | 15 pt | regular | 20 pt | `--font-subheadline: 0.9375rem/1.33` | most secondary labels, summary rows, transfer rows, toggles |
| `.footnote` | 13 pt | regular | 18 pt | `--font-footnote: 0.8125rem/1.38` | *not used anywhere* |
| `.caption` | 12 pt | regular | 16 pt | `--font-caption: 0.75rem/1.33` | hints, helper text, progress %, chevrons, badges |
| `.caption2` | 11 pt | regular | 13 pt | `--font-caption2: 0.6875rem/1.18` | Primary/Auto-Save badges, small chevrons, type descriptions |

Weight/design modifiers observed: `.fontWeight(.bold)`, `.semibold`, `.medium`, `.regular`;
`.bold(isTotal)`; `.fontDesign(.rounded)`; `.monospacedDigit()`; `.font(.headline.monospacedDigit())`;
`.font(.body.monospacedDigit())`; `.font(.caption.weight(.semibold))`; `.font(.caption.bold())`.

**Hardcoded font sizes (violations of the no-magic-numbers rule — reproduce as-is):**

| Value | Location | Purpose |
|---|---|---|
| `.system(size: 48, weight: .bold, design: .rounded)` | `SavingsSlider.swift:51` | the big savings-% number |
| `.system(size: IconSize.hero)` = 80 | `WelcomeScreen.swift:56` | hero `sparkles` glyph |
| `.system(.largeTitle, design: .rounded, weight: .bold)` | `ExpenseListView.swift:96` | Expenses total |

Rounded-design (SF Pro Rounded) is used for: the savings-% number, the income hero amount
(`TransferPlanScreen:100`), and the Expenses total. Web equivalent: a rounded-terminal font stack, or
accept SF fallback.

`DesignGuidelines.md:160-161` mandates **minimum 11 pt** and body 17 pt — the code honours both.

---

## 5. Icon sizes

`IconSize.swift:4-22` + view modifiers `iconSm()`…`iconHero()` (`:26-55`), each implemented as
`font(.system(size: …))`.

| Token | pt | `--css` | Where used |
|---|---|---|---|
| `IconSize.sm` | 16 | `--icon-sm` | *modifier never called* |
| `IconSize.md` | 24 | `--icon-md` | `ExpenseItemRow` icon frame, `ExpenseCategoryCard` divider inset math |
| `IconSize.lg` | 32 | `--icon-lg` | `ReconcileAccountsStep` header icon (`iconLg()`), `CategoryRow` / `ExpenseCategoryCard` / `AddCategorySheet` icon frames |
| `IconSize.xl` | 48 | `--icon-xl` | `SalaryEntryStep` header icon (`iconXl()`) |
| `IconSize.xxl` | 64 | `--icon-xxl` | `OnboardingHeader` default icon (`iconXxl()`), Insights placeholder |
| `IconSize.hero` | 80 | `--icon-hero` | `AnimatedCheckmark` (`iconHero()`), `WelcomeScreen` sparkles, `OnboardingHeader(useHeroIcon: true)` |

---

## 6. Component sizes

`ComponentSize.swift:4-88`.

| Token | Value | `--css` | Purpose / where |
|---|---|---|---|
| `iconContainer` | 32 | `--size-icon-container` | fixed-width icon column in rows (`ExpenseRow`, `BreakdownExpenseRow`, `TransferPlanStep` rows, `SettingsSheet` account rows) |
| `amountInputWidth` | 60 | `--size-input-amount` | `ExpenseRow` inline amount field |
| `compactInputWidth` | 80 | `--size-input-compact` | *unused* |
| `mediumInputWidth` | 120 | `--size-input-medium` | `AccountEditorSheet` balance & hard-cap fields |
| `balanceInputWidth` | 160 | `--size-input-balance` | `SettingsSheet` savings/split amount fields |
| `progressDot` | 8 | `--size-progress-dot` | onboarding progress dots (inactive) |
| `progressDotMedium` | 12 | `--size-progress-dot-active` | onboarding progress dot (current) |
| `segmentedControlCompact` | 100 | `--size-segmented-compact` | boost-multiplier 2×/3× picker in Settings |
| `minTouchTarget` | 44 | `--size-touch-min` | `AccountRow` icon circle; icon-picker cells; **Apple HIG minimum** |
| `touchTarget` | 48 | `--size-touch` | *declared, unused* |
| `buttonHeight` | 50 | `--size-button-h` | `OnboardingButton` / `OnboardingSecondaryButton` `minHeight` |
| `buttonHeightSmall` | 36 | `--size-button-h-sm` | *declared, unused* (36 is separately hardcoded for colour swatches) |
| `celebrationRingSize` | 200 | `--size-celebration-ring` | `CompletionCelebration` ring frame |
| `confettiWidth` | 8 | `--size-confetti-w` | confetti particle width **and** reused as the velocity range bound (`CelebrationEffect:68-69`) |
| `confettiHeight` | 12 | `--size-confetti-h` | confetti particle height |
| `progressTrackHeight` | 4 | `--size-progress-track-h` | onboarding progress bar height |
| `progressRingSize` | 18 | `--size-progress-ring` | current-dot outer ring |
| `progressBarMaxWidth` | 280 | `--size-progress-bar-w` | onboarding progress bar total width |
| `progressIndicatorHeight` | 24 | `--size-progress-indicator-h` | progress bar container height |
| `progressBarWidthFraction` | 0.6 | — | *declared, unused* |
| `progressMinFillScale` | 0.05 | — | added to `progress` so the fill is visible at 0 % |
| `flowItemNumber` | 20 | `--size-flow-number` | numbered circle in `SavingsScreen` flow list |

### Opacity scale — `ComponentSize.swift:92-113`

| Token | Value | `--css` | Used for |
|---|---|---|---|
| `Opacity.faint` | 0.10 | `--opacity-faint` | tinted card backgrounds, badge pills, verification rows |
| `Opacity.light` | 0.15 | `--opacity-light` | `AccountRow` icon-circle fill, badge backgrounds |
| `Opacity.subtle` | 0.30 | `--opacity-subtle` | inactive progress dots/track; ⚠️ **misused as a scale value** in `OnboardingHeader:40` (`.scaleEffect(iconAppeared ? 1.0 : Opacity.subtle)`) and `OnboardingProgressIndicator:65` |
| `Opacity.half` | 0.50 | `--opacity-half` | ring stroke, confetti scale lower bound |
| `Opacity.medium` | 0.60 | `--opacity-medium` | pressed states |
| `Opacity.dimmed` | 0.70 | `--opacity-dimmed` | `OnboardingButton` disabled opacity |
| `Opacity.high` | 0.85 | `--opacity-high` | *declared, unused* |

Additional hardcoded opacities: `0.1` (many `Color.secondary.opacity(0.1)` backgrounds),
`0.15` (`0.15` shadow, `0.15` track, `0.2` glow/circle fills), `0.2` (`accentPrimary.opacity(0.2)`
welcome glow, `accentSecondary.opacity(0.2)` flow-number circle, `.secondary.opacity(0.2)` Default
badge), `0.8` (`.white.opacity(0.8)` selected descriptions).

`DesignGuidelines.md:95-100` prescribes a content-on-glass opacity ladder of **100 / 70 / 40 / 20 %**;
the code's `Opacity` enum is a *different* ladder (10/15/30/50/60/70/85). ⚠️ Note both.

---

## 7. Motion

### 7.1 Durations — `Animation.swift:4-28`

| Token | Seconds | `--css` |
|---|---|---|
| `AnimationDuration.quick` | 0.15 | `--dur-quick: 150ms` |
| `AnimationDuration.fast` | 0.20 | `--dur-fast: 200ms` |
| `AnimationDuration.appear` | 0.25 | `--dur-appear: 250ms` |
| `AnimationDuration.standard` | 0.30 | `--dur-standard: 300ms` |
| `AnimationDuration.medium` | 0.40 | `--dur-medium: 400ms` |
| `AnimationDuration.slow` | 0.50 | `--dur-slow: 500ms` |
| `AnimationDuration.extended` | 0.60 | `--dur-extended: 600ms` |
| `AnimationDuration.celebration` | 1.00 | `--dur-celebration: 1000ms` |

⚠️ **DISCREPANCY:** `DesignGuidelines.md:456` says "Keep animations under 300ms for responsiveness";
`medium`/`slow`/`extended`/`celebration` all exceed that, and are used (screen transitions, celebration
rings). Also `AnimationDuration.quick` and `.extended` are **never used** in feature code.

`.appear` (0.25 s, `easeOut`) is by far the most-used duration — it is the standard
"content appears/disappears" curve across ~25 sites.

### 7.2 Spring presets — `Animation.swift:31-49`

`Animation.spring(response:dampingFraction:)`. Response ≈ period, damping < 1 ⇒ overshoot.

| Token | response | dampingFraction | Approx CSS | Used for |
|---|---|---|---|---|
| `SpringPreset.snappy` | 0.2 | 0.60 | `cubic-bezier(.34,1.56,.64,1)` 200 ms | button feedback, progress-dot scale, category card expand |
| `SpringPreset.responsive` | 0.3 | 0.70 | ~300 ms w/ slight overshoot | most UI transitions, row staggers, multiplier picker, expand/collapse |
| `SpringPreset.standard` | 0.4 | 0.75 | ~400 ms | content appearance — *declared, unused* |
| `SpringPreset.smooth` | 0.5 | 0.80 | ~500 ms, minimal overshoot | screen transitions (onboarding container), `ProgressRing` fill, numeric totals |
| `SpringPreset.bouncy` | 0.5 | 0.60 | ~500 ms, visible overshoot | celebratory: hero icon, header entrance, checkmark, impact card |
| `SpringPreset.gentle` | 0.6 | 0.85 | ~600 ms, no overshoot | *declared, unused* |

SwiftUI's `.bouncy` / `.smooth` **built-in** presets are *also* used directly (`withAnimation(.bouncy)`
in `SavingsScreen:44,278`, `AccountsScreen:179,212`, `AccountRow:60`; `.smooth` in
`ExpensesScreen:87`) — these are **not** the `SpringPreset` values. `.bouncy` ≈ response 0.5 /
damping 0.7 / extra bounce 0.3; `.smooth` ≈ response 0.5 / damping 1.0.

### 7.3 Stagger delays — `Animation.swift:52-64`

| Token | Seconds | Used for |
|---|---|---|
| `StaggerDelay.fast` | 0.05 | *unused* |
| `StaggerDelay.standard` | 0.10 | per-item delay in every staggered list (`index * 0.1`) |
| `StaggerDelay.comfortable` | 0.15 | celebration ring 2 delay |
| `StaggerDelay.initial` | 0.30 | the initial delay before *any* screen's entrance animation begins; also ring 3 delay |

The pervasive entrance pattern is: `withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial))`
for the main content, then `+ AnimationDuration.fast` (0.2) and `+ AnimationDuration.standard` (0.3)
for successive layers.

### 7.4 Scale & offset — `Animation.swift:67-103`

| Token | Value | Used for |
|---|---|---|
| `ScaleEffect.pressedDeep` | 0.92 | *unused* |
| `ScaleEffect.pressed` | 0.95 | onboarding screen transition scale (`OnboardingContainerView:97,101`) |
| `ScaleEffect.pressedSubtle` | 0.97 | *unused* |
| `ScaleEffect.emphasized` | 1.03 | *unused* |
| `ScaleEffect.pulse` | 1.08 | *unused* |
| `ScaleEffect.prominent` | 1.10 | current progress-dot scale; slider thumb drag scale (hardcoded `1.1`) |
| `SlideOffset.subtle` | 10 pt | subtitle slide-in |
| `SlideOffset.small` | 15 pt | title slide-in, row slide-in, section slide-in |
| `SlideOffset.standard` | 20 pt | button/field slide-in; confetti spawn y = `-20` |
| `SlideOffset.large` | 30 pt | onboarding screen horizontal transition offset; expense row x-offset |
| `SlideOffset.xl` | 40 pt | *unused* |

Other hardcoded scales: `0.5` / `0.3` (welcome glow & icon start), `0.95` (card appear), `0.1`
(checkmark & ring start), `1.2` (confetti max), `2.5` (`CelebrationRingsView.expandedScale`).
Rotation: `-30°` start on `AnimatedCheckmark`; `180°` chevron flip; `90°` chevron rotate;
`±10°/frame` confetti angular velocity.

### 7.5 Screen transition (onboarding)

`OnboardingContainerView.swift:94-103` — asymmetric:
- **insertion**: `opacity` + `scale(0.95)` + `offset(x: +30)`
- **removal**: `opacity` + `scale(0.95)` + `offset(x: -30)`
- driven by `.animation(SpringPreset.smooth, value: currentStep)` (`:40`)

### 7.6 Confetti physics — `CelebrationEffect.swift:17-92`

`particleCount = 50`; `gravity = 0.3` px/frame²; timer at **1/60 s** added to `RunLoop.main` in
`.common` mode. Spawn at `(width/2, -20)`. Per particle: `rotation ∈ [0,360)`,
`scale ∈ [0.5, 1.2]`, `velocity.dx ∈ [-8, 8]`, `velocity.dy ∈ [2, 8]`,
`angularVelocity ∈ [-10, 10]` deg/frame. Colours cycle over
`[accentPrimary, accentSecondary, .yellow, .orange, .pink, .cyan]`.
Particles are **never removed** — the effect runs until the view disappears.

### 7.7 Shadows

Only **one** shadow in the entire codebase: `SavingsSlider.swift:104` —
`.shadow(color: .black.opacity(0.15), radius: 4, y: 2)` on the slider thumb.
CSS: `box-shadow: 0 2px 4px rgba(0,0,0,.15)` → `--shadow-thumb`.
Everything else relies on the glass material for depth.

### 7.8 Gradients

Two, both identical in construction — `LinearGradient(colors: [accentPrimary, accentSecondary],
startPoint: .leading, endPoint: .trailing)`:
1. `SavingsSlider.swift:82-89` — filled slider track
2. `OnboardingProgressIndicator.swift:31-39` — progress bar fill

CSS: `linear-gradient(to right, var(--accent-primary), var(--accent-secondary))` →
`--gradient-brand`.

Radial "glow": `WelcomeScreen.swift:41-46` — `Circle().fill(accentPrimary.opacity(0.2))`,
`frame 140×140`, `.blur(radius: 20)`, behind a `120×120` `Circle` filled
`accentPrimary.opacity(0.15)`. CSS: a 140 px circle with `filter: blur(20px)`.

---

## 8. Liquid Glass → web

`GlassComponents.swift`. The single helper is:

```swift
GlassCardModifier(cornerRadius: CornerRadius.large /*16*/, isInteractive: false)
  → content.padding(Spacing.md /*16*/)
           .glassEffect(isInteractive ? .regular.interactive() : .regular,
                        in: .rect(cornerRadius: cornerRadius))
```
Exposed as `.glassCard()`, `.glassCard(cornerRadius:)`, `.glassCardInteractive()` (`:38-53`).
**Every `glassCard()` therefore carries 16 pt of internal padding** — several call sites add
`.padding(Spacing.md)` *and* `.glassCard()`, producing 32 pt total (e.g.
`TransferPlanScreen:185-186, 235-236, 401-402, 433-434`; `SavingsScreen:353-354`). Reproduce faithfully.

Suggested CSS baseline (no exact spec exists in the repo — tune visually against the simulator):
```css
--glass-bg-light: rgba(255,255,255,.55);
--glass-bg-dark:  rgba(28,28,30,.55);
--glass-border:   rgba(255,255,255,.18);
--glass-blur:     20px;
--glass-saturate: 180%;
/* .glass { background: var(--glass-bg-*); backdrop-filter: blur(var(--glass-blur))
            saturate(var(--glass-saturate)); border: .5px solid var(--glass-border);
            border-radius: var(--radius-lg); } */
```

Glass usage inventory (what needs a glass surface on web):

| Construct | Count / locations |
|---|---|
| `.glassCard()` | 14 — SummaryCard, EmergencyProgressCard, PrimaryAccountCard, SecondaryAccountCard, ExpenseBreakdownCard, ExpenseListView summary, TransferPlanStep (×4), TransferPlanScreen (×4), SavingsScreen flow info |
| `.glassEffect(in: .rect(cornerRadius:))` | 6 — `AccountRow` (large), `ExpenseRow` (medium), `ExpenseCategoryCard` (large), `AccountsScreen` emergency/savings prompt cards (large), `SavingsScreen` boost card (large) |
| `.glassEffect(.regular.interactive(), …)` | 2 — `CurrencyAmountField` (medium), `OnboardingTextField` (medium) |
| `.buttonStyle(.glass)` | 6 — Add-Another-Account, suggestion chips, `ExpenseRow` account menu, `CurrencyAmountField` currency menu, `OnboardingSecondaryButton` |
| `.buttonStyle(.glassProminent)` | 8 — `OnboardingButton`, prompt-card Add buttons (×2, tinted `accentPrimary`), `AddAccountSheet` + button, `SalaryEntryStep`/`ReconcileAccountsStep`/`TransferPlanStep` continue buttons, `ExpenseListView` empty-state button |
| `GlassEffectContainer` | 8 — AccountsScreen prompts (spacing `lg`=24), ExpensesScreen list (default), SavingsScreen boost (spacing 0), AccountRow (spacing 0), TransferPlanScreen transfers + remaining (spacing `md`=16), AccountBalancesSection (spacing `sm`=12), TransferPlanStep (spacing `md`=16) |
| `glassEffectID` + `@Namespace` (morph) | 4 IDs — `"emergencyPrompt"`, `"savingsPrompt"` (AccountsScreen), `"boostCard"` (SavingsScreen), `"card-<account.id>"` (AccountRow) |

**`glassEffectID` morphing has no CSS equivalent.** These are shape-to-shape fluid merges when
adjacent glass elements appear/disappear or resize. Closest approximation: FLIP animation on the
container's `height`/`border-radius` with a spring easing, plus a cross-fade of the entering/leaving
child. Where a morph is purely "card grows to reveal detail" (`AccountRow`), an animated
`max-height` + `opacity` on the expanded block is adequate.

Other iOS-only visual effects:
- `.symbolEffect(.pulse, options: .repeating)` — `WelcomeScreen:58` (infinite CSS `opacity`/`scale` pulse)
- `.symbolEffect(.bounce, value:)` — `OnboardingHeader:42` (one-shot bounce keyframe)
- `.contentTransition(.numericText())` — 9 sites; needs a rolling-digit or crossfade component
- `.contentTransition(.interpolate)` — `EmergencyMultiplierPicker:123`
- `.tabBarMinimizeBehavior(.onScrollDown)` and `.tabViewBottomAccessory` — `MainTabView:48-51`; iOS 26 tab-bar chrome with no web analogue (render the "New Month" button as a fixed bottom bar)
- `.scrollIndicators(.hidden)` — everywhere; CSS `scrollbar-width: none`
- `.presentationDetents([.medium])` / `([.large])` — sheet heights; map to modal max-height 50 % / 90 %
- `.interactiveDismissDisabled(...)` — block backdrop-click dismissal on New Month steps 2–3

---

## 9. SF Symbol inventory (per screen)

43 distinct symbols. Each needs a web icon equivalent (SF Symbols cannot be redistributed — use
Lucide / Phosphor / Heroicons and record the mapping).

### 9.1 Data-driven (from Domain — same symbol everywhere)

| Symbol | Source | Meaning |
|---|---|---|
| `building.columns.fill` | `AccountType.primary.icon` | bank / primary account |
| `shield.fill` | `AccountType.emergency.icon` | emergency fund |
| `banknote.fill` | `AccountType.savings.icon` | savings |
| `person.fill` | `AccountType.personal.icon` | personal account |
| `person.2.fill` | `AccountType.joint.icon` | joint account |
| `creditcard.fill` | `AccountType.other.icon` | other account |
| `calendar` | `Frequency.monthly.icon` | monthly |
| `calendar.badge.clock` | `Frequency.annual.icon` | annual |
| `car.fill` | `Category.autoTransport.icon` | Auto/Transport |
| `repeat.circle.fill` | `Category.subscriptions.icon` | Subscriptions |
| `sparkles` | `Category.lifestyle.icon` | Lifestyle |
| `house.fill` | `Category.housing.icon` | Housing |
| `pawprint.fill` | `Category.pets.icon` | Pets |
| `heart.fill` | `Category.healthFitness.icon` | Health/Fitness |
| `cart.fill` | `Category.foodGroceries.icon` | Food/Groceries |
| `tv.fill` | `Category.entertainment.icon` | Entertainment |
| `fuelpump.fill` | onboarding "Gas" expense | fuel |
| `questionmark.circle.fill` | `ExpenseCategoryCard:42` | Uncategorized fallback |

### 9.2 Per-screen chrome

| Screen / component | Symbols |
|---|---|
| `MainTabView` tabs | `chart.pie.fill` (Dashboard), `list.bullet.rectangle` (Expenses), `lightbulb.max` (Insights) |
| `MainTabView` accessory | `calendar.badge.plus` (New Month) |
| Insights placeholder | `lightbulb.max` |
| Dashboard toolbar | `gearshape` (Settings), `hammer.fill` (Developer Tools, DEBUG only) |
| Dashboard empty state | `chart.bar.doc.horizontal` |
| `SummaryCard` | `chart.pie.fill` |
| `EmergencyProgressCard` | `shield.fill` |
| `AccountBalancesSection` | `building.columns.fill` + per-account type icons |
| `ExpenseBreakdownCard` | `chart.pie.fill` + per-expense icons |
| `WelcomeScreen` | `sparkles` (hero, pulsing), `target`, `arrow.left.arrow.right`, `chart.line.uptrend.xyaxis` (value bullets) |
| `NameScreen` header | `person.circle.fill` |
| `IncomeScreen` header | `banknote.fill` |
| `AccountsScreen` | `building.columns.fill` (header), `plus.circle.fill` (Add Another), `shield.fill` + `banknote.fill` (prompt cards), `info.circle` (helper) |
| `AccountRow` | type icon, `chevron.down` (expand), `xmark.circle.fill` (delete), `star.fill` (set primary savings), `chevron.right`, `checkmark.circle.fill` |
| `AccountTypeSelector` | type icons + `chevron.up.chevron.down` |
| `AddAccountSheet` | `plus` (confirm) |
| `ExpensesScreen` (onboarding) | `creditcard.fill` (header), `arrow.right.circle.fill` / `exclamationmark.triangle.fill` (impact), `info.circle` |
| `ExpenseRow` | expense icon, `checkmark` (menu selection), `chevron.up.chevron.down` |
| `SavingsScreen` | `banknote.fill` (header), `bolt.fill` (boost), `exclamationmark.triangle` (boost warning), `info.circle`, `shield.fill` + `banknote.fill` (flow items) |
| `TransferPlanScreen` (onboarding) | `checkmark.circle.fill` (hero via `AnimatedCheckmark`), `building.columns.fill`, `dollarsign.circle.fill`, `checkmark.circle.fill` / `exclamationmark.triangle.fill` (verification), `lightbulb.fill` (tip), `arrow.right.circle.fill` (expense transfer) |
| `RemainingMoneyPicker` | `banknote.fill` / `person.fill` / `building.columns.fill`, `checkmark.circle.fill` |
| New Month step 1 (`SalaryEntryStep`) | `dollarsign.circle.fill` |
| New Month step 2 (`ReconcileAccountsStep`) | `arrow.triangle.2.circlepath` + type icons |
| New Month step 3 (`TransferPlanStep`) | `list.clipboard.fill`, `arrow.right.circle.fill`, `building.columns.fill`, `checkmark.circle.fill`, `checkmark` (Done button) |
| New Month toolbar | `chevron.left` (Back) |
| `ExpenseListView` | `plus` (Add), `ellipsis.circle` (Options), `rectangle.expand.vertical`, `rectangle.compress.vertical`, `folder.badge.gearshape`, `list.bullet.rectangle` (empty state) |
| `ExpenseCategoryCard` | category icon, `chevron.right` (rotates 90°) |
| `ExpenseItemRow` | expense icon, `pencil` (Edit), `trash` (Delete) |
| `AddExpenseSheet` | `plus.circle` (New Category…) + `IconPicker` set (below) |
| `CategoryManagementView` | `plus`, `trash` (swipe delete) |
| `AddCategorySheet` | `checkmark` (colour selected) + icon set (below) |
| `SettingsSheet` | type icons, `chevron.right` |
| `DevDebugView` (DEBUG) | `square.and.arrow.down` (import) |

### 9.3 `IconPicker` set — `AddExpenseSheet.swift:193-231` (37 symbols, this exact order)

`dollarsign.circle.fill`, `cart.fill`, `house.fill`, `car.fill`, `fuelpump.fill`, `shield.fill`,
`heart.fill`, `fork.knife`, `cup.and.saucer.fill`, `tshirt.fill`, `pawprint.fill`, `tv.fill`,
`gamecontroller.fill`, `music.note`, `film.fill`, `airplane`, `gift.fill`, `creditcard.fill`,
`phone.fill`, `wifi`, `bolt.fill`, `drop.fill`, `leaf.fill`, `wrench.fill`, `hammer.fill`,
`paintbrush.fill`, `bandage.fill`, `pills.fill`, `dumbbell.fill`, `bicycle`, `bus.fill`,
`train.side.front.car`, `book.fill`, `graduationcap.fill`, `briefcase.fill`, `building.2.fill`,
`sparkles`

Grid: `LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))])`, spacing `Spacing.sm` (12), cells
44×44, selected background `Color.accentColor.opacity(0.2)`, radius `CornerRadius.small` (8).

### 9.4 Category-icon set — `AddCategorySheet` `CategoryManagementView.swift:133-137` (12 symbols)

`star.fill`, `heart.fill`, `bolt.fill`, `leaf.fill`, `gift.fill`, `tag.fill`, `bookmark.fill`,
`flag.fill`, `bell.fill`, `clock.fill`, `calendar`, `folder.fill`

Same 44 pt adaptive grid. Default selection `star.fill`.

⚠️ **DISCREPANCY:** `Docs/MVP/04-Categories.md:477` promises a "Curated subset (~50 relevant icons)"
with SF Symbol *search*; the code ships 12 fixed icons for categories and 37 for expenses, with no search.

---

## 10. Doc-vs-code token reconciliation

| Token | `Docs/DesignGuidelines.md` | Code | Verdict |
|---|---|---|---|
| Primary accent light/dark | `#D946EF` / `#E879F9` (`:214,217`) | same | ✅ |
| Secondary accent light/dark | `#06B6D4` / `#22D3EE` (`:223,226`) | same | ✅ |
| Spacing scale | 4/8/12/16/24/32/48 (`:360-368`) | identical | ✅ |
| Corner radii | 8/12/16/24 (`:374-379`) | identical | ✅ |
| Touch target | 44 min, 48 preferred (`:319-320`) | `minTouchTarget` 44, `touchTarget` 48 (48 unused) | ✅ tokens exist |
| Font min / body | 11 pt / 17 pt (`:160-161`) | `.caption2` 11, `.body` 17 | ✅ |
| Colour delivery | Asset catalog `Color("AccentPrimary")` (`:243-254`) | programmatic `Color(light:dark:)`; colorsets orphaned | ⚠️ different mechanism, same values |
| Animation ceiling | "under 300ms" (`:456`) | 400/500/600/1000 ms tokens in active use | ⚠️ **DISCREPANCY** |
| Spring default | response 0.5 (`:452`) | 6 presets, 0.2–0.6 | ⚠️ elaborated beyond doc |
| Content-on-glass opacity | 100/70/40/20 % (`:95-100`) | `Opacity` = 10/15/30/50/60/70/85 % | ⚠️ **DISCREPANCY** — different ladders |
| Never blur/opacity/background on glass | forbidden (`:87-89`) | followed — no violations found | ✅ |
| Reduce Motion support | required (`:339-342`, `:454`) | **`accessibilityReduceMotion` appears nowhere in the codebase** | ⚠️ **NOT IMPLEMENTED** — the web port should honour `prefers-reduced-motion` |
| `.sensoryFeedback()` for haptics | recommended (`:394-398`, `:455`) | uses imperative `HapticManager` (`UIImpactFeedbackGenerator` etc.) instead | ⚠️ different mechanism |
| `ViewThatFits` / `NavigationSplitView` / iPad | prescribed (`:270-303`) | **neither appears in the codebase**; iPhone-only `NavigationStack` | ⚠️ **NOT IMPLEMENTED** |
| Category colour palette | 17 named colours (`04-Categories.md:436-455`) | 10 unnamed swatches | ⚠️ **DISCREPANCY** |
