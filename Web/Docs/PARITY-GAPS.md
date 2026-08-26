# Parity gaps

Owned by **Reviewer**. Anything the web client cannot reproduce 1:1 with the iOS app is
recorded here, with the reason and what closing it would take (`TEAM.md` rule 8).
**Nothing is dropped silently.** If it is not in this table, it is expected to match.

Axis values follow `DECISIONS.md` §D6: `numeric` · `content` · `behavioural` · `visual` ·
`not-portable`.

Severity: `blocker` (parity claim is false without it) · `major` (visible to a user) ·
`minor` (cosmetic / unlikely to be noticed).

| # | Screen / area | Axis | What differs | Why | What closing it would take | Severity | Status |
|---|---|---|---|---|---|---|---|
| G1 | Expenses total (Dashboard vs Expenses tab) | numeric | ~~Two different totals coexist~~ — **withdrawn 2026-08-06.** The two totals are **equal by construction**: `MainTabView.swift:147` filters `isEnabled` and normalises `frequency` before the Dashboard VM ever sees the expenses. The disagreement `DECISIONS.md` R3 predicted is unreachable through the UI. | R3 was reasoning from `DashboardViewModel.swift:176-178` in isolation, without the caller's pre-filter. | Nothing — there is no gap. **R3 itself needs amending**: as written it instructs Backend to expose two *differing* fields and mirror a disagreement that does not occur. | n/a (not a gap) | Withdrawn. Golden vectors `S10`/`S11` now assert the **equality** as an invariant, which is a stronger check than either value alone |
| G3 | Dashboard — `EmergencyProgressCard` ring, and every other `ProgressRing` site | visual | iOS animates the percentage label, counting up via `.contentTransition(.numericText())`. The web renders it statically. **The final value is identical** — only the transition is missing. | No CSS equivalent to `numericText()`. A rolling-digit component is possible but is real work for a sub-second effect. | A digit-roll component driven by the server's `progressDisplay` string, honouring `prefers-reduced-motion`. | minor | Accepted. Reported by Frontend from `src/ui/primitives.tsx` |
| G4 | Same — `ProgressRing` accessibility label | content | iOS reads `"\{Int(progress * 100)} percent complete"` (`ProgressRing.swift:46`); the first web implementation exposed `aria-label="4%"` — the visible text rather than the spoken form. | Frontend defaulted the a11y label to the visible string. | **Already done**: `ProgressRing` takes an optional `ariaLabel` so the calling screen composes the spoken form through `t()`. | minor | **Closeable, not permanent.** Becomes a real gap only if a screen ships without passing it — Reviewer to verify per-screen on the Dashboard, and this row is deleted once verified rather than left standing |
| G5 | Account editor sheet (`23-account-editor.jpg`) | numeric / visual | The sheet renders **two incompatible number formats at once**: `Target Amount` shows `27,000 RON` (comma grouping, `AmountFormatter`) while `Current Balance` shows `2.365` (period grouping, `TextField(format: .number)` → the **device locale**, `SettingsSheet.swift:55`). Stored value is `2365` in both cases. | Upstream iOS inconsistency — one field bypasses `AmountFormatter`. Confirms R18 item 8 empirically: `editing` semantics are wrong for that one field. | An upstream fix, or a decision to normalise on the web (which would be a deliberate divergence). Meanwhile the **screenshot comparison for this screen is locale-dependent** — on a US-formats machine the same field renders `2,365`, so a reference/capture mismatch may be the grading machine rather than the port. | major | Open. Screen marked `⚠️locale` in `Web/Verify/output/REPORT.md`; **grade with the locale pinned or exclude the field and say so**. `2.365` reads as a plausible number, same hazard class as R24's `parseUserInput("9,000 RON") = 9.000` |
| G7 | Romanian catalogue — two missing keys | content | `dashboard.Step %lld of %lld` (New Month header "Step n of 3") and `dashboard.Target: %lld× monthly income` (Emergency Fund caption) are **absent from `ro.json`**, so both render in **English on a Romanian dashboard**. | A missing key falls back to English silently — nothing errors, and an English-reading reviewer sees a correct-looking screen. | Add both keys to `ro.json` (Frontend owns the catalogues). | major | **Open — found 2026-08-06 by `parity/locale.spec.ts` on its first run.** Not allowlisted: these are user-visible sentences, not format-only strings. Reported to Frontend |
| G2 | New Month — remaining money with no primary-savings account | numeric | When `remainingDestination == .primarySavings` and no such account exists, the remaining money (3,547.5 in the canonical scenario) **silently vanishes**. The parts sum to 5,452.5 instead of 9,000, and `isBalanced` still reports `true` because it is computed before the destination lookup. | **Upstream iOS defect we are deliberately mirroring** (`DECISIONS.md` R10.3 — an `if let` with no `else`). Ruled by main 2026-08-06: do **not** invent a fallback destination or an `unallocatedRemaining` field. | An upstream iOS fix. Until then, reproducing the loss *is* parity. | n/a (intentional) | Mirrored by design; pinned by golden vector `S17`, whose conservation check is marked `expectedToFail` with the exact defective sum. If a future implementation conserves the money, `S17` fails — and that failure means we have **diverged from iOS**, not that we fixed a bug. **RESOLVED 2026-08-06 by R26: deliberate mirror.** `unallocatedRemainingMoney` stays served but is quarantined to the dev-tools surface (not shipped parity surface, per R16). The field and the vectors are already in place should the user later decide they want the real fix — flagged for their review in `DECISIONS.md` |

Rows are added only once real behaviour has been observed and found to differ — not from
anticipation. `G1` is retained struck-through rather than deleted so the reasoning that
withdrew it stays auditable.

## G2 — resolved: deliberate mirror (R26)

Backend's `unallocatedRemainingMoney` + warning banner would have **conserved money where iOS
loses it**, contradicting the OQ8 ruling. Escalated rather than resolved locally, because
"deliberately better than the app we are porting" is a product decision and the user was
unavailable.

**Ruled by main (R26): mirror the defect.** A warning iOS does not show is a behavioural
divergence under D6 axis 3 — better is still not *the same*, and 1:1 is the reversible
default. The path is unreachable in the default flow, so mirroring costs almost nothing. The
field stays served but is quarantined to the dev-tools surface (R16: not shipped parity
surface). `S17` and `S21` stand unchanged.

**R26a generalises this into a standing rule**, and it is now the required pattern here:
where iOS has a defect, reproduce and log it, never silently improve it — and **every
mirrored defect must carry a test that fails if the values ever come out correct**. That is
the `expectedToFail` + inverse-assertion pair used by `S17` and `S21`. A mirrored defect with
no such test decays into an unnoticed divergence the moment someone "fixes" it.

| G6 | Primary-savings account selection, and account ordering | behavioural | **The web is deliberately MORE DETERMINISTIC than iOS.** iOS does not enforce `isPrimarySavings` uniqueness (`SettingsSheet.swift:605` sets it without clearing others) and resolves it with `accounts.first(where:)` over an **unsorted** `@Query` array — so with two such accounts it credits a **nondeterministic** account between launches. The web picks deterministically. Separately, iOS sorts accounts inconsistently between the Dashboard and Settings. | Upstream iOS defects. Reproducing nondeterminism is neither possible nor desirable: a golden vector over two primary-savings accounts would encode one arbitrary run and then fail randomly — the fixture would be certifying a coin flip. | An upstream fix (enforce uniqueness on write; one sort order). | major (upstream) / n/a (our side) | **Accepted divergence, not a defect.** Enforced by a fixture-integrity test: no vector may contain two `isPrimarySavings` accounts (R27). Screenshot scenarios use **one account per type** so Dashboard grading cannot flake on iOS ordering rather than ours |

## Already known to be out of scope (per `DECISIONS.md` §D6.5)

These are decided, not discovered — they are listed so they are not re-litigated, and they
will be restated as proper rows above once the affected screens are actually built.

- **Foundation Models on-device LLM** — not available in a browser. The MVP docs' deterministic
  fallback is the agreed substitute.
- **Haptics** — no web equivalent worth faking on a laptop. Dropped.
- **Liquid Glass** — `backdrop-filter` is an approximation, not the real material.
  "Closest faithful approximation" is the agreed bar; individual screens that fall short of
  even that get a row above.

## Backend / server-side (Backend, 2026-08-06)

| # | Gap | Reason | What it would take |
|---|---|---|---|
| B1 | **Main savings slider granularity.** iOS's slider is *continuous* (`SavingsSlider.swift:112-129` computes an arbitrary `Double` from the drag position and only *snaps* when within `snapThreshold` of 7 values). The web serves `savingsSliderPositions` at 0.01 granularity, so the client reaches a subset of iOS's positions. | R2 forbids client-side arithmetic and a round-trip per drag frame is unusable, so the reachable positions must be enumerable. 0.01 is the granularity the *split* sliders genuinely use (`SavingsScreen.swift:178`). | Nothing user-visible: the percent label truncates to an integer either way, and whatever position is chosen is stored and everything derives from it consistently. Only an exact-position replay of an iOS drag would differ. |
| B2 | **`AmountFormatter.parse` comma bug reproduced.** `"1,234"` parses as `1.234`, because `parse` replaces *all* commas with periods. Served faithfully via `POST /api/parse-amount`. | Deliberate, per `DECISIONS.md` D1 — matching iOS beats being correct. | Fix `Utilities.AmountFormatter.parse` upstream, then update the web at the same time. |
| B3 | **"Emergency" quick-suggestion chip creates a `.savings` account.** `AddAccountSheet.swift:66-69` passes `type: .savings` for the chip labelled "Emergency". Served as data in `reference.accountSuggestions`, bug intact. | Reproducing it keeps parity; serving it as data rather than hardcoding makes it a one-line flip if fixed upstream. | Change the chip's type in iOS, then flip the server's `Defaults.accountSuggestions`. |
| B4 | **Quick-suggestion chip labels are unlocalized.** "Joint" / "Emergency" / "Travel" are raw literals with no `.localized`, so they render English under Romanian. | Faithful to iOS. | Add the three keys to the Onboarding catalog upstream. |
| B5 | **Remaining money can vanish.** When `remainingDestination` names a role no account fills (`.primarySavings` with no primary-savings account), `BalanceReconciler` adds it to no balance — and `isBalanced` was already computed `true`. Shipped iOS behaviour, preserved. | `DECISIONS.md` R10 rules that the behaviour is reproduced, not fixed. | The server *reports* it as `unallocatedRemainingMoney` on `/api/new-month/preview` so the UI can warn; changing where the money goes is an upstream product decision. |
| B6 | **`Frequency.annual.monthlyMultiplier` is inexact.** `Decimal(1)/12` is a 28-digit approximation, so an annual 1,200 normalises to `99.999…` and any total containing it carries the tail (`2599.9999999999999999999999999999999`). | Domain behaviour; iOS is identically imprecise and only ever shows the formatted value, which rounds correctly to `"2,600 RON"`. | Store a rational or scale by 12 in Domain. Not worth it: no displayed value is affected. |
| B7 | **`transferPlan.summary` groups with the host locale.** `TransferPlan.summary` builds a bare `NumberFormatter` without forcing `","` the way `formatForDisplay` does. | Domain code; not authorised to change. | No iOS view renders it — use the individual `Money.display` fields. |
| B9 | **`account.balanceEditorValue` follows the *server's* pinned locale, not the device's.** The Settings account editor uses `TextField(format: .number)`, so iOS renders the stored `2365` as **`2.365`** on a Romanian-locale device while the server (pinned `en_US`, R7) serves `"2,365"`. Confirmed live in the simulator: the same screen shows `Target Amount` as `27,000 RON` and `Current Balance` as `2.365`. | R7 requires the server be machine-independent; iOS deliberately keeps device-locale behaviour here. The two cannot both hold. | Serve a device-locale variant if a reviewer insists on grouping-glyph parity for this one field. Numerically identical either way, and it is an *input* field the user overwrites. |
| B10 | **`SavingsAllocationEntry.presets` (5 values) ≠ `SavingsSlider`'s snap set (7 values).** Domain declares `[0.10,0.15,0.20,0.25,0.30]`; the slider snaps to `[0.10,0.15,0.20,0.25,0.30,0.35,0.40]`. | `presets` is referenced by **no view** — dead code, like Domain's `recommendationText`. The slider's array is what the user feels. | None. Both are exposed; the contract directs clients to `snapValues`. |
| B11 | **An exact `.5` is unreachable through the annual→monthly conversion.** `Frequency.annual.monthlyMultiplier` is `Decimal(1)/12`, so `1266 × multiplier = 105.4999…` and displays `105 RON`, where a true `1266 / 12 = 105.5` would round half-even to `106`. | Domain behaviour, and iOS is identically affected. Reproduced by serving the value from Domain rather than dividing anywhere. | Nothing on our side. It is a reason the conversion can never be done client-side: dividing changes the *value* at the boundary, not just the rounding. Served via `POST /api/expenses/preview`. |
| B8 | **Domain enum display names are English-only server-side.** SwiftPM copies `Localizable.xcstrings` without compiling it on macOS, so `.localized` falls back to the key — which *is* the English string. | Cannot be fixed without an unauthorised change to `Domain`. | None needed: the client's i18n dictionary owns Romanian, keyed by the English string (per `LOCALIZATION.md`). |
