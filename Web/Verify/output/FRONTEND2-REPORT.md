# Frontend2 — onboarding report (tasks #5 and #21)

Resent here because two direct messages arrived as summary-only.

## Yes — I drove all 7 screens in a real browser, in both appearances, three times

Not "it builds". Playwright + Chromium at **402×874** (the R9 graded column), `deviceScaleFactor 2`,
against the live Vite dev server proxying to the Vapor API. Driven, not screenshotted-at-rest:
typed the name, typed the income, tapped both Recommended prompts, expanded the emergency row,
tapped 3×→6×→3×, filled all four expense amounts, toggled Priority→Split, toggled both split
sides to Percentage, drove the savings slider to both ends with the keyboard, and walked through
to the summary.

- **light: 27/27 assertions PASS**
- **dark: 27/27 assertions PASS**
- **Romanian (`?lang=ro`): passes**, with exactly 4 "failures" that are my English assertions not
  matching correct Romanian output.

Screenshots in `/tmp/ob-shots/{light,dark,ro-light}-*.png`, 10 per appearance.

The one thing I have **not** done: `POST /api/onboarding/complete`. The shared store holds the
finished ground-truth run (EF 2,365 / Savings 7,095) and completing would clobber it for everyone.
The payload validates (same type accepted by `/preview`), but **the persist path is unproven
end-to-end.** It needs one run against a disposable store — R29's `DIAMERIS_STORE` makes that safe.

## Ground truth, reproduced live

`4,730 RON` after expenses · `1,182 RON` savings at `25%` · target `27,000 RON` (`54,000` at 6×) ·
summary `9,000 / 1,182 / 4,270 / 3,548` · `0% → 4%` · "All accounted for!".

**New ground truth:** onboarding Split, walked for the first time. GROUND-TRUTH flagged 473/710/1,182
as *derived, not observed* — it is **confirmed**: Emergency 10% → `473 RON`, Savings 15% → `710 RON`,
total `1,182 RON`. The parts visibly do not sum; each side rounds half-even independently. Split's
default state is correctly **two empty Fixed Amount fields with nothing allocated**.

## What driving it found that compiling did not

1. **UUID case.** `crypto.randomUUID()` is lowercase; Swift's `UUID.description` is UPPERCASE. Preview
   accounts never matched draft rows under `===`, so the emergency `Target:` row rendered **empty**
   with no error anywhere. Now matched case-insensitively.
2. **The savings slider was keyboard-inaccessible.** I had implemented iOS's snap-to-7-values. Arrow
   keys move 0.01, land inside the 0.02 radius, get pulled back — the thumb **cannot leave 10%**. iOS
   has no such trap (its AX path steps 0.05 and never snaps), so single-step changes now skip the snap
   while drags keep it. Tests passed the whole time this was broken.
3. **Account name + `Primary` badge wrapped to two lines** vs `04-onboarding-accounts.jpg`. The name is
   now a label until tapped — which is also more faithful to §2.4.1.
4. **My first slider check was a false pass.** Setting `input.value` from JS bypasses React's value
   tracker, so nothing moved and the assertion matched a *tick label* that happened to read `50%`.
   Re-done with real keyboard events. Worth knowing for anyone writing range-input checks.

## Compared against the reference screens

- **`01-onboarding-welcome`** — hero halo, both title lines, em-dash subtitle, three tinted bullets,
  full-width magenta pill. Matches.
- **`04-onboarding-accounts`** — dot 3 of 5 active; Main/Emergency/Savings cards with correct icon-circle
  tints (magenta/orange/cyan), `Primary` and `Auto-Save` badges, type pill, delete affordances, prompts
  gone once satisfied. Two fixes came from this comparison (item 3 above, and the type-pill glyph, which
  needed `Menu.icon` from Frontend — now landed and adopted).
- **`06-onboarding-savings`** — dot 5 of 5; both segmented controls; 48pt magenta `25` with a small grey
  `%`; "That's 1,182 RON/month"; gradient slider with `5%` / `25% recommended` / `50%`; cyan
  "Great savings rate!" capsule; boost card; numbered flow rows; cyan preview card. Matches.
- **`07-onboarding-summary`** — no indicator; cyan check; income hero; Emergency `1,182 RON` with
  `0% → 4%`, orange bar and `Target: 27,000 RON`; Stays in Primary; Remaining Money with **Primary
  Savings preselected**; green total row; tip. Matches, except filled glyphs render as outlines (Lucide
  is stroke-only — D3, enumerated).

## Rulings applied after they landed

- **R24** caught a real hole: my amount inputs are raw `<input>`s, so the brand never reached them and
  everything compiled green. Branded all seven `*Text` draft fields as `EditingString` → 9 compile
  errors on 9 real assignment sites. **The brand only protects code routed through `AmountField`; the
  guard belongs on the state.** Worth a line in `DECISIONS.md` — the next hand-rolled input will hit it.
- **R25 row 8** was live in my summary: allocations were keyed by `accountId`. At-target Split produces
  two rows both named "Savings"; React would have collapsed them and silently dropped **3,548 RON**.
  Now an ordered list keyed by index. Invisible in the ground-truth data, exactly as R25 predicted.
- **R28d**: reverted `Currency.displayName` to raw. The other four enums were already correct.
- **R30 / late items, all verified already correct:** "Target reached!" is gated on `isComplete` for any
  account type and appended below the progress note; `!isBalanced` shows the orange triangle and drops
  "All accounted for!"; allocations are mapped **unfiltered** and never keyed by account id; onboarding
  does not touch `account.subtitle`, so the v1.2 `subtitleParts` change does not reach it.

## Open gaps (for `PARITY-GAPS.md` — I have not edited it)

1. **7 strings stay English in Romanian**, faithfully: `Food`, `Rent`, `Gas`, `Streaming`,
   `"Where does your money go?"`, `"Transfer to %@"`, `"for %@"`. Verified at source — all **absent from
   `Onboarding/Localizable.xcstrings`** although iOS calls `.localized` on them, so iOS ships English too.
   This will look like our bug in a Romanian screenshot.
2. **Lucide is stroke-only** — every `.fill` glyph renders as an outline, including the summary's filled
   cyan check circle. Accepted D3 deviation, visible on every screen.
3. **Two non-iOS strings I added**: the indicator's `"Step %lld of %lld"` aria-label (iOS has no such
   text; needed for a11y) and a degradation notice shown only if a server omits `savingsSliderPositions`.
   Neither renders in the normal flow.
4. **`api.ts`'s `RemainingMoneyDestinationValue` is missing `'personal'`** — Domain has three cases and
   the live server sends three. Cast in my test with a note; reported to Frontend.
5. **iOS's snap makes some rates unreachable** (9%, 11%, 14%…) — any drag within 0.02 of a snap value
   collapses onto it. Reproduced deliberately; noting it so it is not filed as a web bug.

## Environment

Browser verification on :8080 is racy (R29). Three server restarts hit me mid-run and produced one
**entirely bogus pass/fail set** — every expense assertion failed because `availableIncome` came back as
9,000. My walk now retries the initial load. Anyone grading from a single browser run on the shared port
should assume the same hazard.

## Numbers

`npx tsc --noEmit` → 0 errors. `npm test` → **123 passed / 7 files** (31 of them mine: draft logic,
7-screen render, snap boundaries, and two R26a inverse tests that fail if the mirrored
remaining-money defect is ever "fixed"). `npm run build` → clean. `data-testid` → 30 across onboarding,
with expense slugs derived from the **seed key, not the localized name** (a slug from `name` becomes
`mancare` in Romanian and fails the suite on a correct screen).

---

# Frontend2 — task #22 (Expenses modals) + the closed onboarding gap

## The completion gap is closed — it now runs for real

`POST /api/onboarding/complete` was the one path in onboarding with no verification. With
R29's `DIAMERIS_STORE` it runs against a disposable store:

```
DIAMERIS_PORT=8082 DIAMERIS_STORE=/tmp/f2-store.json Web/Server/.build/debug/DiamerisServer &
DIAMERIS_TEST_URL=http://127.0.0.1:8082 npx vitest run complete.integration   # 2 passed
```

It builds the draft through the **real** `createDraft` → `addAccount` → `updateExpense` →
`toPayload(draft, true)` path — not a hand-written payload — and asserts what §2.8 says the
write produces: profile `Vlad`, income `9,000 RON`, four expenses totalling `4,270 RON`,
savings persisted at `25%` prioritized, emergency multiplier 3 with target `27,000 RON`, and
the balances pre-applied as if every transfer had been made — **Main `4,270` (assigned, not
added) · Emergency `1,182` · Savings `3,548`**.

It is **opt-in and fails loudly** rather than skipping: a test that goes green when nothing is
listening is worse than no test. It refuses to run without `DIAMERIS_TEST_URL` and asserts the
store is fresh before writing, so it can never quietly destroy a populated one.

## The three modals

`features/expenses/modals/` — `AddExpenseSheet`, `CategoryManagementView`, `AddCategorySheet`,
plus `categoryOrder.ts`, `useExpensePreview.ts`, `ModalsDevHarness.tsx`, `modals.css`.
**20 unit tests**; `npm test` **151 passed / 2 skipped**; `npm run build` clean.

**Driven in a browser at 402×874: 27/27 assertions in light and dark**, via the `?dev=modals`
hook. Screenshots in `/tmp/modal-shots/`.

Verified live, not merely rendered: **37 / 12 / 10** palette counts straight from `reference`;
`calendar` present in the category grid and **absent** from the expense grid (the cleanest
proof the two lists are not shared); Save disabled at empty, at name-only, and **still at
amount 0** (the shipped rule rejects 0 though `Docs/MVP/03` wants it allowed); the New Category
sheet presented *from* the expense sheet, as iOS does; the Preview row following the typed
name; 8 `Default` pills with no Custom section; the sheet's delete confirming (unlike the row
context menu, which does not).

## Monthly Equivalent — the row I refused to ship, then shipped

R18 grants a client-side-multiply exception for this row and describes it as `× 12`. It is
`amount × Frequency.annual.monthlyMultiplier` — **÷ 12**. Following R18 literally is **144×**
wrong. I held the row unrendered and asked Backend for an endpoint.

Backend's test then found the deeper reason it could never be local: the multiplier is
`Decimal(1)/12` at 28 significant digits, so `1266 × multiplier = 105.4999…` → **105**, while
JS `1266 / 12` is exactly `105.5` → **106**. The disagreement is in the *operand*, so no
rounding care in `money.ts` recovers it. **Confirmed in the browser: 1,266 annual renders
`105 RON`.** `showsMonthlyEquivalent` carries iOS's render gate, so even the condition is not
reimplemented.

`DECISIONS.md` R18's `× 12` wording should be corrected — Backend has flagged it too and
documented the truth in `API-CONTRACT.md` v1.9.

## Two visual bugs the screenshot comparison caught

1. **The Monthly|Annual segmented control must have no icons.** `FrequencyPicker.swift:17` is
   `Label(displayName, systemImage: icon)`, so the source reads as if it has them — but
   `.pickerStyle(.segmented)` drops the image, and `09-expenses.jpg` / `14-add-expense-sheet.jpg`
   both show bare text. Removed from mine; **`ExpensesScreen.tsx:124` still passes `icon: f.icon`**
   and needs the same fix (reported). `GROUND-TRUTH.md` lists the icons for this control, which
   is what makes it re-addable — worth correcting there.
2. **The colour grid wraps 7-then-3; iOS wraps 6-then-4.** `ui.css:679` sizes columns from
   `--size-color-swatch` (36px) where iOS's grid is `.adaptive(minimum: 44)` — a 44pt cell
   holding a 36pt circle. One extra column at the graded width. Reported with the fix.

## Open

- `api.ts` still lacks `reference.categoryIcons` / `categoryColors` (served since this morning)
  and `'personal'` on `RemainingMoneyDestinationValue`. Cast locally with comments; the casts
  come out when the types land.
- `Category` has no `createdAt`, so R17's custom-category tie-break is `(sortOrder, name)` only.
  Two customs with the same name stay unordered — invisible on screen, but noting it.
- `ModalsDevHarness` is dev-only surface (`?dev=modals`), not parity surface, on the same
  standing R16 takes for Dev Tools. It must never be reachable from app navigation.
