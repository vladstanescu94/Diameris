# Ground Truth — observed by driving the live iOS app

Captured 2026-08-06 on iPhone 17 Pro simulator (iOS 26), light + dark.
Screenshots: `Web/Docs/reference-screens/*.jpg`. These are the **visual contract**.

Test data used throughout: name `Vlad`, income `9000 RON`, expenses
Food `1200` / Rent `2500` / Gas `450` / Streaming `120` (total `4270`),
savings `25% Priority/Percentage`, accounts Main (Primary) + Emergency Fund + Savings.

## Verified numbers (the web client MUST reproduce these exactly)

| Quantity | Value | Derivation |
|---|---|---|
| Income | 9,000 RON | user input |
| Monthly expenses | 4,270 RON | 1200+2500+450+120 |
| After expenses ("Available") | 4,730 RON | 9000 − 4270 |
| Savings @ 25% | 1,182 RON displayed / `1182,5` stored | 0.25 × 4730 → **display truncates/rounds to integer, storage keeps the decimal** |
| Personal spending | 3,548 RON displayed / `3547,5` stored | 4730 − 1182.5 |
| Emergency target | 27,000 RON | 3 × 9,000 (3× income default) |
| EF progress after 1 month | 1,182 / 27,000 = **4%** | **truncated** percent, see below |
| EF progress after 2 months | 2,365 / 27,000 = **8%** | 1182.5+1182.5 = 2365 |
| Savings balance after 2 months | 7,095 RON | 3547.5 × 2 |

### The table above is NOT exhaustive — the screenshots are binding too

Reviewer gap 4: six real numbers are legible in the reference images but were missing here.
Added, all from the ground-truth run:

| Where | Values |
|---|---|
| Expenses tab, category totals | Auto/Transport `450 RON`, Subscriptions `120 RON`, Housing `2,500 RON`, Food/Groceries `1,200 RON` |
| Expenses tab, per-category counter | **`1/1 enabled`** on each of the four (Reviewer gap 3) |
| Dashboard, Account Balances (after month 1) | Main Account `4,270 RON`, Savings `3,548 RON` |
| Dashboard, Account Balances (after month 2) | Main Account `4,270 RON`, Savings `7,095 RON` |
| New Month step 2 captions | **"was 3,548 RON last month"** (Savings), **"was 1,182 RON last month"** (Emergency Fund) — Reviewer gap 6 |

**Rule going forward: where a reference screenshot and this table disagree, the screenshot
wins**, and the table is corrected. Anything legible in an image is binding.

### Money format, stated explicitly (Reviewer gap 11b)

Previously only inferable from the table and the images:
- Grouping separator **`,`**, hardcoded in Swift — **not** locale-derived. Grouping *size*
  does come from the locale, which R7 pins.
- **One ASCII space** between the number and the currency code: `9,000 RON`.
- Currency rendered as the **code** (`RON`), never the symbol (`lei`) — `Currency.symbol`
  exists in the code but is unused by every screen.
- Negatives use an **ASCII hyphen** prefix: `-4,270 RON`.
- Zero fraction digits in display; storage keeps full `Decimal` precision.

### Dashboard title locale and timezone (Reviewer gap 1)

The large title is `DateFormatters.monthYear` = `"MMMM yyyy"` over **now**.
- Month name follows the **selected UI language** — `August 2026` (EN) / `august 2026` (RO,
  lowercase, as Romanian does not capitalise month names).
- "Current month" is computed in the **server's local timezone**; the harness must pin a fixed
  date (R17), or this flakes at month boundaries.

### ⚠️ Annual expenses are *deliberately* imprecise — do not "clean up" the raw value

`Frequency.annual.monthlyMultiplier` is `Decimal(1) / 12`, which is **not exact**. So an annual
expense of `1,200` normalises to `99.999…`, not `100`, and a monthly total that looks like it
should be `2,600` is actually `2,599.99…`.

**iOS is identically imprecise** — invisible only because every screen renders the *formatted*
value, which rounds to `2,600 RON`.

Consequences, and they are counter-intuitive:
- **Never assert a clean raw total for a scenario containing an annual expense.** The Reviewer
  originally pinned `2600` and it was **invented, not observed**.
- The only way to obtain exactly `2600` is to **recompute outside Domain** — precisely the
  divergence R2 forbids. So the fixture now asserts `display` for annual scenarios **plus** a
  `rawMustNotEqual` check that the raw value is *not* the clean number. A TypeScript
  reimplementation would produce clean arithmetic and fail — which is the point.
- This also means a "tidier" server-side rounding of `monthlyAmount` would break parity.

### ⚠️ Three different numeric rules. Getting these wrong is the #1 parity risk.

**1. Money amounts → half-even (banker's) rounding to 0 decimals.**
`AmountFormatter.formatForDisplay` uses `NumberFormatter` with `maximumFractionDigits = 0`
and `roundingMode` left at its default, which the Critic verified at runtime is
`.halfEven` (rawValue 4). Confirmed outputs: `1182.5 → "1,182"`, `3547.5 → "3,548"`,
`0.5 → "0"`, `1.5 → "2"`, `2.5 → "2"`, `1183.5 → "1,184"`.
JS `Intl.NumberFormat`/`Math.round`/`toFixed` all round half-**up** and would emit
`1,183`. **Half-even must be hand-written** — or, per our design, never computed in JS at
all because the server formats every amount.

**2. Percentages → truncation, not rounding.**
- Expense breakdown: `Int((amount / total) * 100)` —
  `ExpenseBreakdownCard.swift:54-59`.
- Emergency-fund ring: `Int(animatedProgress * 100)` — `ProgressRing.swift:77`.
Proof from the live app: Gas is 450/4270 = **10.53%** and the app renders **10%**;
rounding would render 11%. So truncation is confirmed, not inferred.
Streaming is 120/4270 = 2.81% → **2%**. I scrolled the live dashboard and confirmed it
renders `2%` (an earlier note here guessed "~3%" — wrong). Both truncation sites are now
verified in the running app, not merely read from source.

**3. `isBalanced` → `abs(total - income) < 0.01`** (`TransferCalculator.swift:71`), which
drives the "All amounts add up correctly" banner. Swift `Decimal` only; never recompute
in JS floats.

## Onboarding — **7 screens**, with a **5-dot** progress indicator

Corrected: this section previously said "5 steps" while enumerating 7 screens. Both numbers are
real and they mean different things — the indicator does **not** cover every screen:

- **7 screens** total: welcome → name → income → accounts → expenses → savings → summary.
- **5 dots**, covering only name → income → accounts → expenses → savings. Welcome and the
  first-month summary show no indicator.
- Verified against the screenshots: on **accounts** the 3rd of 5 dots is active
  (`04-onboarding-accounts.jpg`) and on **savings** the 5th and last is active
  (`06-onboarding-savings.jpg`) — consistent with dots covering screens 2–6 only.

Derive the dot count from the step list; do not hardcode 5 in two places.
Dots use the magenta→cyan gradient for completed/active segments.

1. **Welcome** — sparkle glyph in a soft magenta halo, title "Take control of your money",
   subtitle "In the next few minutes, we'll build your personalized transfer plan — so payday
   becomes effortless.", three bullets with tinted SF Symbols:
   - target/`scope` — "Set savings goals that fill automatically"
   - arrows — "Know exactly where to transfer your money"
   - chart line — "Watch your progress grow"
   CTA: full-width pill **Let's Go** (magenta, prominent).
2. **Name** — "First, let's get acquainted" / "What should we call you?" + text field
   placeholder "Your name". CTA **Continue** (disabled until non-empty).
3. **Income** — "Nice to meet you, {name}!" / "How much lands in your account each month after
   taxes?"; labelled amount field "Monthly net income" with currency suffix `RON`;
   footnote "This is your starting point — we'll help you decide where every unit goes."
4. **Accounts** — "Where does your money live?" / "Set up your accounts. We recommend an
   emergency fund and savings account."
   - Section "Your Accounts". Primary card: "Main Account" + `Primary` pill badge,
     account-type menu (`building.columns.fill` Primary), NOT removable.
   - "Add Another Account" button.
   - Section "Recommended" with two add-cards: **Emergency Fund** ("Protects you from
     unexpected expenses. Recommended: 3-6 months of income.") and **Savings Account**
     ("Build wealth over time. After emergency fund is full, savings go here.") each with **Add**.
   - Added accounts get: coloured icon circle, name, type menu, `Auto-Save` badge (savings),
     disclosure chevron, remove `xmark.circle.fill`.
   - Emergency card accessibility label includes "target 27,000 RON".
   - Footnote "Your primary account is where your salary lands".
5. **Expenses** — "Where does your money go?" / "A quick look at your main expenses. Don't worry
   about being exact — estimates are fine." Four seeded rows, each: icon, name, amount field
   with `RON`, and a **From:** account menu defaulting to `Main`.
   - Food `cart.fill`, Rent `house.fill`, Gas `fuelpump.fill`, Streaming `tv.fill`
   - Live summary card: "After expenses" / "4,730 RON" / "available for your goals"
   - Footnote "By default, expenses are paid from your main account"
   - CTAs: **Continue** and **Skip for now**
6. **Savings** — "How much do you want to save?" / "Savings are calculated from your income
   after expenses."
   - "Allocation Strategy" segmented: **Priority** | Split → caption "Emergency fund fills
     first, then savings"
   - "Monthly Savings" segmented: **Percentage** | Fixed Amount
   - Huge magenta `25` + `%`, caption "That's 1,182 RON/month"
   - Slider 5%…50%, centre tick label "25% recommended", end labels `5%` / `50%`
   - Badge "Great savings rate!" (cyan check, tinted capsule)
   - Switch "Savings Boost" / "Triple your savings temporarily"
   - "How your savings are distributed" numbered steps: ① "Emergency fund fills first until
     target reached" ② "Remaining savings go to your savings account"
   - "This month's savings" / "1,182 RON" / "going to your accounts"
   - CTAs **Continue**, **Skip for now**
7. **First-month summary** — cyan filled check circle, "Your First Month" /
   "Here's your personalized transfer plan, {name}!"
   - Card: "Monthly Income" / "9,000 RON" (cyan, large)
   - "Your Transfers": Emergency Fund `1,182 RON`, sub "0% → 4%", progress bar,
     "Target: 27,000 RON"; then "Stays in Primary" `4,270 RON` / "For automatic bill payments"
   - "Remaining Money": "3,548 RON" / "Available after savings" / "Where should this go?" with
     two selectable cards: **Primary Savings** ("Add to your savings for future goals") and
     **Keep in Primary** ("Leave in your main account")
   - "Total: 9,000 RON" + "All accounted for!"
   - Tip: "Tip: Do these transfers right after payday for best results!"
   - CTA **Start Using Diameris**

## Main app

Tab bar (3 tabs, glass, magenta selected): **Dashboard** `chart.pie.fill`,
**Expenses** `list.bullet.rectangle`, **Insights** `lightbulb.max`.
Bottom accessory above the tab bar: **New Month** pill with `calendar.badge.plus`.
Dashboard toolbar (top-right, glass capsule, 2 items): Settings `gear`, Developer Tools `hammer`.

### Dashboard
Large title = current month + year ("August 2026").
1. **Monthly Summary** card (`chart.pie.fill` magenta): rows Income `9,000 RON`,
   Expenses `-4,270 RON` (red), Savings `1,182 RON` (cyan), divider,
   bold **Personal Spending** `3,548 RON`.
2. **Emergency Fund** card: progress ring with `4%` inside (orange), shield icon + title,
   `1,182 RON / 27,000 RON`, "Target: 3× monthly income".
3. **Account Balances** section header (`building.columns.fill` magenta) — one card per
   account: icon, name, balance, `Primary` pill on the primary account. Primary card is
   full-width and larger; others are compact.
4. **Expense Breakdown** — name, amount, percent-of-total, descending
   All four rows, read off the live app — **these are binding, not illustrative**:
   Rent `2,500 RON` **58%** / Food `1,200 RON` **28%** / Gas `450 RON` **10%** /
   Streaming `120 RON` **2%**.

### Expenses
Large title "Expenses". Toolbar: `+` (Add Expense) and `…` overflow menu.
1. Card "Total Monthly Expenses" / `4,270 RON` (large).
2. Segmented **Monthly** | **Annual** — ⚠️ **bare text, NO icons.**

   This entry previously read "**Monthly** `calendar` | **Annual** `calendar.badge.clock`" and
   **that was wrong.** `FrequencyPicker.swift:17` genuinely is
   `Label(displayName, systemImage: icon)` — so *both this doc and the source* say icons render.
   They don't: **`.pickerStyle(.segmented)` discards the image.** Confirmed by re-reading
   `09-expenses.jpg` and `14-add-expense-sheet.jpg` — bare text in both.

   Two implementers independently added the icons from these two sources before Frontend2 caught
   it against the screenshot. **Screenshot beats source reading — including when the source looks
   unambiguous.**
3. One row per category: coloured icon, category name, "n/m enabled",
   total amount, disclosure chevron. Observed categories: Auto/Transport (car, blue),
   Subscriptions (arrow.triangle.2.circlepath, purple), Housing (house, green),
   Food/Groceries (cart, green).

Category rows **expand inline (accordion), they do not push a new screen.** Expanding
"Housing" reveals its expense rows: name, amount, and a **toggle switch** per expense
(enabled/disabled) — this is what drives the "n/m enabled" counter and the totals.

**Add Expense sheet** (`Cancel` / title `Add Expense` / `Save`, Save disabled until valid):
- Section **Details**: `Name` text field; amount field showing `RON` prefix and `0`;
  segmented **Monthly** `calendar` | **Annual** `calendar.badge.clock`
- Section **Category**: "Category" menu (default `None`) + magenta **New Category...**
  action row with a `plus.circle` glyph
- Section **Account**: "Pay From" menu (default `Primary`), caption
  "Choose which account this expense is paid from."
- Section **Icon**: `IconPicker` — a `LazyVGrid(.adaptive(minimum: 44))` of **37** selectable
  SF Symbols, first one selected with a tinted magenta square background.

  ⚠️ **Corrected: 37, not 18.** I originally wrote 18 because the screenshot is clipped —
  only ~3 rows sit above the fold. Verified in source (`AddExpenseSheet.swift:193-231`,
  37 entries) and the 18th entry *is* `creditcard.fill`, the last one I could see, which is
  why the miscount looked self-consistent. Full order:
  `dollarsign.circle.fill, cart.fill, house.fill, car.fill, fuelpump.fill, shield.fill,
  heart.fill, fork.knife, cup.and.saucer.fill, tshirt.fill, pawprint.fill, tv.fill,
  gamecontroller.fill, music.note, film.fill, airplane, gift.fill, creditcard.fill,
  phone.fill, wifi, bolt.fill, drop.fill, leaf.fill, wrench.fill, hammer.fill,
  paintbrush.fill, bandage.fill, pills.fill, dumbbell.fill, bicycle, bus.fill,
  train.side.front.car, book.fill, graduationcap.fill, briefcase.fill, building.2.fill,
  sparkles`

  **Never infer a list length from a screenshot.** Both grids must come from source, and the
  server serves them so neither client nor spec can drift.

**Expenses `…` overflow menu** (3 items): **Expand All** `rectangle.expand.vertical`,
**Collapse All** `rectangle.compress.vertical`, **Manage Categories** `folder.badge.gearshape`.

⚠️ **Delete confirmation is asymmetric between the two sheets** — walked 2026-08-06, pinned in
both directions:

| Delete action | Confirmation? |
|---|---|
| **Expense** (Add/Edit Expense sheet) | ✅ **confirms** — "cannot be undone" |
| **Custom category** (Manage Categories) | ❌ **none** — row simply disappears |

Easy to harmonise by accident in either direction. Custom categories also appear under a
**Custom Categories** section with a delete affordance, while the 8 defaults keep their `Default`
pills and cannot be deleted.

**Manage Categories sheet** (`Done` / title `Categories` / `+`) — screenshot `15-manage-categories.jpg`.
Section header "Default Categories", footer "Default categories cannot be deleted."
All **8** defaults are listed here even when they have no expenses (the Expenses tab only showed
4 because only 4 had expenses — these are the same 8, so there is no second category list):

| # | Name | SF Symbol | Colour |
|---|---|---|---|
| 1 | Auto/Transport | `car.fill` | blue `#3B82F6` |
| 2 | Subscriptions | `arrow.triangle.2.circlepath` | purple `#8B5CF6` |
| 3 | Lifestyle | `sparkles` | amber `#F59E0B` |
| 4 | Housing | `house.fill` | emerald `#10B981` |
| 5 | Pets | `pawprint.fill` | pink `#EC4899` |
| 6 | Health/Fitness | `heart.fill` | red `#EF4444` |
| 7 | Food/Groceries | `cart.fill` | green `#22C55E` |
| 8 | Entertainment | `tv.fill` | cyan `#06B6D4` |

Each row: coloured icon, name, grey `Default` pill on the right.

**New Category sheet** (`Cancel` / title `New Category` / `Add`, Add disabled until named) —
screenshot `16-new-category-sheet.jpg`. Sections:
- "Category Name" — text field, placeholder `Name`
- "Icon" — grid of **12** symbols, 6 per row, selected one on a tinted magenta rounded square:
  `star.fill, heart.fill, bolt.fill, leaf.fill, gift.fill, tag.fill, bookmark.fill, flag.fill,
  bell.fill, clock.fill, calendar, folder.fill`
  ⚠️ This is a **different, shorter set** than the 18-symbol grid in the Add Expense sheet.
  Do not share one icon list between the two screens.
- "Color" — 10 circular swatches, 6 then 4, selected one shows a white `checkmark`:
  `#3B82F6 #8B5CF6 #F59E0B #10B981 #EC4899 #EF4444 #22C55E #06B6D4 #F97316 #6366F1`
  (last two read as orange and indigo from the screenshot — Analyst to confirm exact hexes
  against `CategoryManagementView.swift:120-131`)
- "Preview" — a live row showing the chosen icon + the typed name (placeholder "Category Name")

**Developer Tools sheet** — screenshot `17-dev-tools.jpg`. Rows:
"Completed: Yes" (onboarding flag), **Reset Onboarding Flag**, **Clear All Data & Reset**,
**Import from Python Script**, **View Stored Data**, then read-only
"Version 0.1", "Build 1", "Bundle ID ro.svc.Diameris".

### ⚠️ Romanian: the word "Annual" renders BOTH ways on the Expenses tab, simultaneously

The same word is looked up from **two different modules**, and only one has the key:

| Site | Module | Key present? | Renders in RO |
|---|---|---|---|
| `ExpenseItemRow.swift:60` — `"Annual".localized` (row caption) | Expenses | ✅ `Anual` | **`(Anual)`** |
| `Frequency.swift:35-36` — `"Annual".localized` (segmented control) | Domain | ❌ absent | **`Annual`** |

So on the Expenses tab in Romanian, **an annual expense row shows the caption `(Anual)` while the
segmented control directly above it reads `Annual`.** Both are correct; the web must reproduce
both. This is visible in a single screenshot, which makes it an unusually good parity target.

**Consequence for implementers: `tDomain` is not a blanket policy even within one screen.** The
served `Frequency.displayName` stays raw; the row caption is translated client-side.

⚠️ **Live trap in `ro.json`:** `'Total %@ Expenses' → 'Cheltuieli %@ totale'` is a translation iOS
can **never render** (the only dead Form-B lookup in the codebase — see `VERIFICATION-LOG.md`
Standing rule #3). If it is wired through `t()`, the web shows Romanian where iOS shows English.
Most other `%@`-keyed entries **do** resolve on iOS and are fine; this one is the exception.

### Insights
Placeholder only: title "Insights", body "Coming soon".

### ⚠️ Split allocation mode — walked 2026-08-06 (this was the big ground-truth hole)

My original walkthrough only ever used **Priority** mode, which is why an entire allocation
mode went unspecified and unservable. Now captured: `18-settings-split-fixed.jpg`,
`19-settings-split-percentage.jpg`.

Selecting **Split** replaces the single savings-rate control with **two independent per-account
blocks**, each with its *own* Percentage | Fixed Amount segmented control:

- Caption under the Priority|Split control changes to **"Fixed amounts to each account every month"**
- **Emergency** block: shield icon + "Emergency", its own Percentage|Fixed Amount segmented,
  then either a `Rate` row showing e.g. `10%` (percentage mode) or an amount field with `RON`
  (fixed mode)
- **Savings** block: same structure, banknote icon + "Savings"
- **Total Monthly** row, value in magenta
- Footnote unchanged: "Savings are calculated from income after expenses."

**Defaults on first switching to Split:** both sides in **Fixed Amount** at `0`, so
Total Monthly is `0 RON`. Switching a side to **Percentage** reveals a default rate —
**Emergency 10%**, **Savings 15%**.

⚠️ **Read that precisely — I have described it loosely elsewhere and caused confusion.**
`SavingsAllocationEntry.swift:58,61` defaults **both** per-side input modes to
`.fixedAmount` with amount `0`. So a first-time user switching Priority → Split sees **two
empty Fixed Amount fields and a total of `0 RON`** — nothing allocated. The 10% / 15% are the
default *rates that appear once a side is toggled to Percentage*; they are **not** the
allocation defaults. My walkthrough toggled both sides, which is why I saw them.
**A web implementation that defaults to Percentage would show 473/710 RON allocated where
iOS shows nothing.**

#### ⚠️ Per-side amounts do not sum to the displayed total (needs one confirmation)

With Emergency 10% and Savings 15% against availableIncome 4,730:

| Side | Raw | Displayed (half-even) |
|---|---|---|
| Emergency | `473.0` | `473 RON` |
| Savings | `709.5` | **`710 RON`** (710 is even) |
| **Total** | `1182.5` | **`1,182 RON`** |

**473 + 710 = 1,183, but the total renders `1,182`.** Each value is rounded independently
from the full decimal, so the displayed parts legitimately do not add up. If real, this must
be reproduced, not "fixed" — and it is a perfect golden vector, since `709.5` sits exactly on
the `.5` boundary where rounding rules diverge.

✅ **CONFIRMED — 🚧 removed.** Verified two independent ways by the Critic:
1. **Source:** `SavingsScreen.savingsPreview` (`:429-458`) is **not** mode-gated, and
   `calculatePreviewSavings()` (`:460-469`) returns `splitTotal` for `.split` — so
   "This month's savings" renders *alongside* the per-side rows at `:172`/`:218`.
2. **Executed** against the real `Domain` + `AmountFormatter` on macOS:
   `473` / `709.5 → 710 RON` / `1182.5 → 1,182 RON`.

⚠️ **Assert all three together or the vector proves nothing.** `473 + 709` also sums to
`1,182`, so a naive-rounding implementation would match the total *and* plausibly match one
side. Only **`473` + `710` + total `1,182`** asserted jointly catches it.

#### Verified split numbers (new golden vectors)

Same base data: income 9,000, expenses 4,270, **availableIncome 4,730**.

| State | Total Monthly shown | Derivation |
|---|---|---|
| Emergency 10% (Percentage), Savings 0 (Fixed) | **473 RON** | 0.10 × 4730 = 473 exactly |
| Emergency 10%, Savings 15% (both Percentage) | **1,182 RON** | (0.10+0.15) × 4730 = 1182.5 → half-even → 1,182 |

Two things this proves:
1. Split percentages resolve against **`availableIncome` (4,730)**, not gross income —
   confirming `availableIncome × percentage` is computed inline per side.
2. The split defaults (10% + 15% = **25%**) are deliberately chosen to match Priority mode's
   25%, so the two modes agree out of the box. `1,182 RON` appears in both — do not treat that
   coincidence as evidence the modes share an implementation.

### ⚠️ AccountEditorSheet — two different number formats on ONE screen

Walked 2026-08-06, screenshot `23-account-editor.jpg`. `Cancel` / **Edit Account** / `Save`.
Sections: name field · **Account Type** (Type menu, `shield.fill` Emergency) ·
**Emergency Fund Target** (Target menu → `3× monthly income`; `Target Amount` → `27,000 RON`;
**Set maximum amount** switch) · **Balance** (`Current Balance`).

**This screen renders the same kind of quantity two incompatible ways, simultaneously:**

| Field | Renders | Formatter | Grouping |
|---|---|---|---|
| Target Amount | **`27,000 RON`** | `AmountFormatter` | `,` — hardcoded in Swift |
| Current Balance | **`2.365`** | SwiftUI `TextField(format: .number)` | `.` — **from the device locale** |

The stored value is `2365` in both cases. Confirms the Critic's finding (R18 item 8):
`SettingsSheet.swift:55` uses `.number`, **not** `formatForEditing`, so this one money input
follows the device locale and has no `RON` suffix. This machine is `en_US@rg=rozzzz`
(US English, Romanian regional formats), which is why it renders `2.365`.

**Consequences the web port must respect:**
- `editing` is **not universal** — for this field the server's `editing` semantics are wrong.
- On a US-formats machine the same field would render `2,365`, so a screenshot comparison of
  this screen is **locale-dependent**. Pin the locale before grading it.
- ⚠️ `2.365` is dangerously readable as "2.365" — a reviewer sees a plausible number and moves
  on. Same hazard as R24's `parseUserInput("9,000 RON") = 9.000`.

Also note the label divergence the Critic flagged: this screen says **"Set maximum amount"**
where onboarding's `EmergencyMultiplierPicker` says **"Set maximum"**, and this one labels the
field **"Maximum"** vs onboarding's **"Max:"**. Four distinct keys for two controls, all in the
main app target's catalog (the fifth catalog).

### ✅ OQ12 answered — Split mode with the emergency fund AT target

Walked 2026-08-06. Setup: emergency balance edited to `27000` (so **100%**,
`27,000 RON / 27,000 RON`), allocation **Split**, Emergency **10%** / Savings **15%**.
Screenshot `24-split-at-target-transferplan.jpg`.

**Two distinct behaviours, and they matter separately:**

**1. Settings' "Total Monthly" is the *requested* total, not the resolved allocation.**
At-target it still shows **`473 RON`** with only Emergency at 10%, and **`1,182 RON`** with
both sides — byte-identical to the not-at-target case. It is purely `splitTotal`; it does
**not** account for the emergency being full. The redirect happens later, at transfer-plan time.

**2. The transfer plan redirects the whole emergency share to savings.** "Transfers to make":

| Row | Amount | Subtitle |
|---|---|---|
| **Savings** | `+1,182 RON` | — |
| **Savings** | `+3,548 RON` | `remaining money` |
| Primary | `4,270 RON` | `stays for automatic payments` |

plus `All amounts add up correctly`.

- **Emergency Fund does not appear at all — but ⚠️ ONLY IN SPLIT MODE.** At target, its `473`
  overflows entirely, so `473 + 709.5 = 1182.5` → **`1,182 RON`** all lands on Savings.

  ⚠️ **This is mode-dependent, and my original note stated it unconditionally — wrong.** The
  Critic's Domain probe found a full fund *does* produce an emergency allocation with
  `amount = 0`, and `TransferPlanStep.swift:129` iterates `accountAllocations` **unfiltered**, so
  iOS renders **"Emergency Fund +0 RON"**. Both observations are correct; they are different code
  paths:

  | Mode | At target | Row rendered? |
  |---|---|---|
  | **Prioritized** | `calculateEmergencyAllocation` returns `targetAmount != nil`, so `amount > 0 \|\| targetAmount != nil` is **true at amount 0** → appended (`:109-112`) | ✅ **"Emergency Fund +0 RON"** with the `"100% → 100%"` note |
  | **Split** | `remaining <= 0` → `emergencyOverflow = requestedAmount` and **nothing is appended** (`:176-178`) | ❌ **no row** |

  My screenshot `24-split-at-target-transferplan.jpg` is **Split**, which is why I saw no row.
  The Critic's probe was prioritized. **Do not implement either as the universal rule.**

  ⚠️ **The seam that makes this deceptive** (Critic): the section gate and the row loop use
  *different* predicates — gate is `!isEmpty && contains { $0.amount > 0 }` (positives only),
  loop is unfiltered. So "the gate filters positives" does **not** imply "the loop shows
  positives". Never filter the row loop.
- ⚠️ **TWO rows carry the same account name "Savings"**, distinguished only by the second's
  `remaining money` subtitle. **A client keying transfer rows by account id or name will
  collapse them into one and lose 3,548 RON from the display.** This is a new instance of the
  R25 confusable family — same account, two semantically different rows. Render the plan as an
  **ordered list**, never as a map keyed by account.

Also confirmed on this run: the emergency ring reads **`100%`** exactly at target (so 100 is
reachable; `Int(1.0 × 100) = 100`), and step 2's captions echoed the *current* balances again —
"was 7,095 RON last month" / "was 27,000 RON last month".

### ✅ S13 answered — Split with the emergency fund NEAR target (100 short)

Walked 2026-08-06, screenshot `25-split-near-target-transferplan.jpg`. Setup: emergency
reconciled to `26900` (100 short of the 27,000 target), Split, Emergency 10% / Savings 15%.

"Transfers to make" — **three** rows:

| Row | Amount | Subtitle |
|---|---|---|
| **Emergency Fund** | `+100 RON` | **"Completes fund to 100%!"** |
| **Savings** | `+1,082 RON` | — |
| **Savings** | `+3,548 RON` | `remaining money` |
| Primary | `4,270 RON` | `stays for automatic payments` |

plus `All amounts add up correctly`.

**Three things this pins:**

1. **The emergency allocation is capped at exactly what is needed** — `100`, not the requested
   `473`. The remainder spills to savings.
2. **The spill is `1182.5 − 100 = 1082.5`, displayed `1,082 RON`** — half-even rounding **down**,
   because 1082 is even. This is a strong discriminator: half-up would render `1,083`. Together
   with `3547.5 → 3,548` (rounding *up* to even) it brackets the rule from both sides in one
   screen.
3. ⚠️ **A new string appears only in this state: "Completes fund to 100%!"** — a completion
   callout shown when the allocation finishes the fund. It is absent both when the fund is
   already full (see the at-target section: Emergency has no row at all) and when the allocation
   falls short. Easy to miss entirely, since it exists only in a narrow window.

Note again **two rows named "Savings"** (R25 row 8) — here alongside a *third* row for Emergency,
so the ordered-list requirement holds with three distinct entries, two sharing an account.

### Settings (modal sheet, `Cancel` / title `Settings` / `Save`)
- **Profile**: Name (text field), Currency (menu → "Romanian Leu (RON)")
- **Savings**: Priority|Split segmented + caption; Percentage|Fixed Amount segmented;
  "Savings Rate" `25%` + slider; "Savings Boost" switch;
  footnote "Savings are calculated from income after expenses."
- **Accounts**: navigable rows — Main Account / "Primary"; Emergency Fund /
  "Emergency  • 3× income"; Savings / "Savings  • Primary"

### New Month flow (modal, 3 steps, header "Step n of 3" with back chevron)
1. "How much did you receive?" — amount field prefilled with last income,
   caption "Last month: 9,000 RON".
2. "Update your account balances" / "Did you use any savings this month?" — one amount field
   per **reconcilable** account, each with a "Current balance" label, `RON` suffix, and a
   caption "was X last month". Screenshot `21-newmonth-step2.jpg`.

   ⚠️ **The prefill is the account's plain persisted `currentBalance`, NOT a projection** —
   `NewMonthSheet.swift:109` is `accountBalances[account.id] = account.currentBalance`.
   It only *looked* projected in my first walkthrough because month 1 had already committed
   1182,5 / 3547,5. Implementing an actual projection here produces wrong numbers.

   ⚠️ **And the "was X last month" caption shows that same current balance, not a previous
   value.** Verified on a second run: with Savings at 7,095 and Emergency at 2,365, the
   fields prefill `7095` / `2365` **and** the captions read **"was 7,095 RON last month"** /
   **"was 2,365 RON last month"**. The wording is misleading but it is what ships — the
   caption is `currentBalance`, formatted for display. Do not compute a historical value.

   ⚠️ **Only reconcilable accounts appear.** On this run just **Savings** and **Emergency
   Fund** were shown; **Main Account was absent**, confirming the
   `emergency | savings | personal` filter (`ReconcileAccountsStep.swift:30-36`) and why
   `isReconcilable` must be served (R14). Primary/joint/other are seeded but never displayed —
   which is exactly the R10 trap.
3. "Your Transfer Plan" — card Income / Expenses / **Available**;
   "Transfers to make" rows (Emergency Fund `+1,182 RON` with "4% → 8%";
   Savings `+3,548 RON` with "remaining money"); Primary `4,270 RON`
   "stays for automatic payments"; validation banner "All amounts add up correctly";
   CTA **Done – I made the transfers** (magenta pill with check).
   On completion balances persist (EF 2,365, Savings 7,095) and the dashboard updates.

## Visual language notes for the web port
- Background: pure white (light) / pure black (dark). Cards are subtly lighter/darker
  fills with a hairline border and very soft shadow — that is the "glass" read at rest.
- Accent magenta ≈ `#E040FB`-ish, secondary cyan ≈ `#00C8E0`-ish, warning orange for the
  emergency fund, red for expense amounts. Exact hexes come from `DESIGN-TOKENS.md`.
- Corner radii are large (≈20–24px on cards, fully rounded pills).
- Titles use heavy/bold rounded-ish system weights; large numbers are the visual anchor.
- Progress dots / sliders / progress bars use a magenta→cyan horizontal gradient.
