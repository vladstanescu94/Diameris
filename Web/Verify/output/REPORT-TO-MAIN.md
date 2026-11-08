# Reviewer → main: full report

Written to disk because the sends did not arrive as a body. This is the complete text.

**Last updated** after the Split-mode ground truth, the 402px viewport correction, the
Critic's money probes and R17. Current: **103 tests / 5 files**, 21 screens × 2 themes ×
2 viewports = **84 captures**, golden fixture at **27 scenarios (24 binding)**.

### Changelog — round 9 (Backend integration; two disputes ruled)
- **Oracle endpoint adopted** — `POST /api/golden/seed` is now the primary seeding path, with
  the reset→onboard→new-month sequence kept as fallback.
- **OQ11 closed** — locale pinned to `en_US` (not `en_US_POSIX`, which disables grouping and
  silently drops thousands separators). Harness tightened from `/1182[.,]5/` to literals.
- **Dispute 1 ruled — Backend is right, my `2600` was invented.** `Decimal(1)/12` is inexact
  and iOS is identically imprecise. Withdrew the exact raw totals; assert `display` instead,
  plus a new **`rawMustNotEqual`** asserting the value is NOT the naive clean number — because
  the only way to obtain exactly 2600 is to recompute outside Domain, the divergence R2 forbids.
  Better than either offered option: no unreadable 33-digit literal, and it still catches a
  TS reimplementation.
- **Dispute 2 ruled — Backend is right.** S02's 3547.5 is `remainingMoney` routed, not an
  allocation; renamed to **`savingsReceived`**. S01 and S02 have structurally identical plans
  and must not contradict each other on one key. Recorded as an `allocationVsReceived` rule.
- **Zero-balance heuristic rejected** — every scenario now declares `input.phase` explicitly
  (17 onboarding / 7 established / 3 chained), guarded by a fixture test.
- Offline guards now **13**. One of the new ones immediately caught that `S10` had missed the
  Decimal fix — the guard working on its first run.

### Changelog — round 8 (R26 ruling, R26a, R27)
- **G2 resolved: deliberate mirror.** `contested` markers removed from `S17`/`S21`; both stand
  unchanged. Gap row records that the field and vectors are already in place should the user
  later want the real fix.
- **R26a enforced, not just documented**: a fixture test now requires every mirrored defect to
  pin an exact defective value, to differ from the correct one, and to carry a `why` that warns
  a passing check means **divergence**. Non-vacuous — it finds `S17` and `S21`.
- **R27 enforced**: no vector may contain two `isPrimarySavings` accounts, with the coin-flip
  reasoning in the failure message. Capture scenarios use one account per type, documented in
  `REPORT.md`.
- **`G6`** added: the web is *deliberately more deterministic than iOS* — divergence, not
  defect — plus iOS's Dashboard-vs-Settings sort inconsistency as an upstream bug.
- Offline fixture guards now **10**.

### Changelog — round 7 (OQ12 + the two-Savings-rows trap)
- ⚠️ **Self-correction: my transfer-row test ids were account-keyed**, which baked the
  collapsing bug into the test contract — the harness could never have caught it. Now
  **ordinal** (`nm-transfer-row-<i>`), with the whole ordered list compared in one `toEqual`.
- **`S27`** — split at target: Emergency row **absent** (not a zero row), two rows both named
  `Savings` (`+1,182` and `+3,548 remaining money`). Registered as `transferPlanRowIdentity`
  in the fixture rules (R25 row 8).
- **`S12` binding** — Settings' Total Monthly is the *requested* split total, unchanged at
  target. Also pins the ring reading exactly `100%`, complementing `S05`'s 99%.
  **`S13` stays open**: its Settings half is now known, but the near-target *transfer plan*
  is still unwalked and that is the interesting half.
- **`G5`** — the account-editor sheet renders two number formats at once (`27,000 RON` vs
  `2.365`). Screen flagged `⚠️locale` in `REPORT.md` with instructions to pin the locale or
  exclude the field, since a mismatch there may be the grading machine, not the port.
- Two new screens captured (refs 23, 24) → **92 captures**.

### Changelog — round 6 (R25a, OQ closures, contested G2)
- **OQ10 closed** — `-0.6` → `-1` from the Critic's real-Swift probe; sign boundary complete.
- **OQ13 closed, `S24` binding** and rewritten as a **joint** assertion. A fixture-integrity
  test now fails if anyone splits it into three independent checks, because `473 + 709` also
  sums to `1,182` — two of three can pass on a wrong implementation.
- **R25a → `S25`** (annual expense asserted as *displayed* in both segments, with a
  `forbiddenDisplay` check that `1,200 RON` never appears under Monthly) **and `S26`**
  (hard cap that bites: effective 20,000 vs struck-through 27,000, and 5% not 4% — so an
  ignored cap fails a *label*, not only the picker).
- **Frontend's two `ProgressRing` gaps** recorded as `G3` (animated label, accepted) and
  `G4` (a11y wording, closeable — to be deleted once verified, not left standing).
- **`G2` marked CONTESTED** — Backend's `unallocatedRemainingMoney` + warning banner is the
  direct opposite of the OQ8 ruling. Escalated to main; vectors unchanged pending the call.

### Changelog — round 5 (API gate + R20)
- **API-propagation gate wired into `globalSetup`**: warns by default with the outstanding
  count and a "these failures may be missing API fields, not UI bugs" banner; fatal under
  `PARITY_STRICT_API=1`. Reasoning for not making it fatal by default is in the README.
- **R20 geometry assertions** (2 new tests): the label must be the truncated int **and** the
  arc must be drawn from the unrounded double, at the same moment — `data-progress`,
  `pathLength="1"` and `stroke-dasharray` all checked. Includes an explicit assertion that
  the drawn value is **not** the truncated one, since that is the actual failure mode.
  Geometry doubles pinned in `S01`/`S02` (`0.0437962962962963`, `0.0875925925925926`).
- **Icon grid corrected 18 → 37**, plus a tail assertion that the list ends at `sparkles`.
  An 18-count assertion would have ratified the server's truncation at `creditcard.fill`.
- **Settings subtitle**: tolerant match now, with a strict per-element branch that activates
  automatically once Backend serves the parts — no edit needed, and no window where the
  doubled space quietly becomes acceptable.

### Changelog — round 4 (final gap answers)
- **Gap 5** → `S21`: a SECOND vanishing-money defect (`.primarySavings` preselected but the
  savings account skipped → no card renders selected, no branch fires at save). Given the
  same `expectedToFail` + inverse-assertion treatment as `S17`. Also asserts the card
  arrives **preselected** in the normal case.
- **Gap 7** → tightened from whitespace-tolerant regex to **per-element** assertions:
  2 sibling nodes, `Emergency` / `• 3× income`, plus an explicit "no node contains a
  doubled space" check.
- **Gap 9** → new **`parity/behaviour.spec.ts`** (axis 3 had no suite at all) + vectors
  `S22`/`S23`. Includes a test that the two skips produce *different* savings figures —
  identical results mean one of them is wrong.
- **Split correction**: `S19`/`S20` re-sourced to say 10%/15% are rates revealed on toggling
  to Percentage, **not** allocation defaults (both sides default to fixed 0 — that is `S18`).
- **Per-side rounding artefact** → `S24`, `needs-confirmation`, blocked by new **OQ13**.
  Split out of `S20` so an unobserved artefact cannot ride in on a binding vector.

### Changelog — round 3 (main's gap answers)
- **OQ2 ruling inverted S10/S11.** They no longer assert a disagreement; they assert the
  **equality invariant** (annual → 2,600 both tabs, availableIncome 6,400; disabled → 2,500
  both tabs). Breakdown percents recomputed over the normalised total (rent 96%, insurance 3%).
  `PARITY-GAPS.md` G1 **withdrawn**. ⚠️ **R3 still needs amending** — as written it tells
  Backend to expose two differing fields and mirror a disagreement that cannot occur.
- **OQ8 ruling inverted S17.** The conservation check is now `expectedToFail` with the exact
  defective sum `5452.5`, plus a second assertion that fires if the money *stops* vanishing.
  Logged as `PARITY-GAPS.md` G2.
- **Gap 8:** `stepSavings` no longer clicks Priority/Percentage — it asserts them as the
  arrived-at defaults. Clicking would have masked a wrong default.
- **Gap 6:** step-2 captions asserted as literals (`was 1,182 RON last month` /
  `was 3,548 RON last month`), with a comment that they echo the CURRENT balance.
- **Gap 11b/1:** money format and month-name rules recorded in the fixture's `rules`.
- **Gap 10:** refs 20/21/22 wired in; the three onboarding screens are marked prose-only.

### Changelog since the first version
- Split mode: 3 measured scenarios (S18/S19/S20) + a Settings-Split content suite + 2 new
  captured screens. OQ3 (split ratio) is **answered**; OQ12 opened for the at-target case.
- Graded viewport corrected **390×844 → 402×874** (OQ9 resolved — see §3).
- Critic's probes pinned: `-0.4`/`-0.5` → `-0`, `parse("1e3")` → `1000`, and the
  `formatForEditing` separator left deliberately loose until Backend pins `en_US_POSIX`.
- R17: the clock is pinned (`X-Diameris-Now` header + `page.clock`), so the Dashboard
  month title cannot flake at a month boundary.

---

## 0c. CORRECTIONS APPLIED — my locale suite was asserting the wrong target

⚠️ **The most important item in this round is a correction to my own new suite.** I had
pinned `Lunar`/`Anual` on the Monthly|Annual control and the mixed header `Total Lunar
Expenses` "explicitly as the target". Both were **wrong, and would have failed a correct
implementation** — the worst kind of test, because it pushes the implementer to break parity
in order to go green.

What actually ships, verified by probe:

| Site | Renders in RO | Why |
|---|---|---|
| Monthly\|Annual segmented control | **`Monthly` / `Annual`** (English) | `Frequency.displayName` is Domain code binding Domain's bundle, which has no such key |
| Annual row caption | **`(Anual)`** | `ExpenseItemRow.swift:60` binds the *Expenses* bundle, which does |
| `Total Monthly Expenses` header | **fully English** | Two independent causes: a dead lookup (interpolation happens *before* localisation, so the runtime key can never match `Total %@ Expenses`) **and** the bundle mismatch above |

So one screenshot correctly shows a control reading `Annual` above a row reading `(Anual)`.
The suite now asserts exactly that, with `Monthly`/`Annual` allowlisted in the leakage sweep
*with the reason*, plus `Developer Tools` and `%lld percent complete` as correct English
fallbacks so `G7` cannot grow to include correct behaviour.

Added a **negative** assertion: `Cheltuieli %@ totale` exists in `ro.json` but is
**unreachable on iOS**, so it must never appear in the DOM — rendering it would be a silent
improvement, which R26a forbids. Scoped deliberately: this is the only dead interpolated key,
so it must not generalise into a rule against `%@` keys.

## 0b. LAYER 1 IS LIVE — 22/26 golden vectors pass against the real server

First trustworthy numeric signal of the project. `parity:golden` layer 1 (server maths via
`POST /api/golden/seed`): **22 passed, 4 failed**, reproducible across runs.

Two of my vectors were wrong rather than the server, both caught by Backend and fixed:
`S13` now carries **both** `savingsAllocation` (1082.5, the spill) **and** `savingsReceived`
(4630, spill + remainder) — different quantities, so one key could never serve both; and
`S26` was declared `established` while expecting post-plan balances, so it is now
`onboarding`. `S05` stays `established` because it asserts a *before* balance. That the two
look identical in data shape is precisely why the flag has to be declarative.

**What passes is the part that matters**: S01 ground truth, S03/S04 half-even both directions,
S05 truncation at 99%, S06 zero income, S07 the clamp, S08/S09 emergency capping, **S10 and
S25 the Decimal-tail ruling**, S11 disabled expenses, S12/S18/S19/S20 split, S13 near-target,
S17/S21/S26/S27. The reused Swift Domain is producing exact values with no client arithmetic.

**The 4 failures are integration gaps, not numeric defects:**

| Vector | Cause |
|---|---|
| `S02`, `S16`, `S24` | All three use `continuesFrom`. The oracle has no chaining, so they fall back to `POST /api/onboarding/complete`, which returns **400**. ⚠️ Note *which* ones these are: S02 is the canonical two-month ground truth and S16 is the R10 balance-wipe case — **the two most load-bearing vectors are the two that cannot run.** Requested oracle support for `continuesFrom` + `newMonth`. |
| `S23` | `savingsStrategy` / `savingsMode` are not served. Field request with Backend. |

### Three harness bugs found by running it (all mine, all fixed)

1. **Silent fallback.** A non-ok oracle response fell through to the reset path *quietly*, so
   a 400 caused by unexpanded account templates looked like a slow success on a route I never
   meant to take. Now warns with status and body.
2. **Unexpanded templates.** The oracle wants full account dictionaries; I was posting
   `["main", {from: "emergency"}]` verbatim. Expansion is the client's job.
3. **A loose lookup.** My recursive "find this key anywhere" matched `display.emergencyTarget`
   (`"20,000 RON"`) for a `raw` assertion expecting `"20000"`. It failed loudly this time; the
   dangerous version is where the two coincide and it **passes for the wrong reason**. Lookups
   are now scoped to the named response section. Same family as the account-keyed test ids.

### One vector was wrong, not the server

`S13.savingsReceived` expected `1082.5` (the spill only); the server returns `4630`
(spill + remaining money). The server is right and consistent with S02 — `savingsReceived` is
the **total** the account receives. The 1,082 / 3,548 split lives in `transferPlanRows`, which
is where the two-rows-named-Savings distinction belongs anyway.

### Register row 4 — confirmed, and the oracle cannot see it

`emergencyHardCap` and `emergencyTargetUncapped` **are** served (probed live: 20000 / 27000,
effective target correctly capped). But `targetCaption` is **absent from the oracle response
entirely**, and `StateAssembler.swift:361` has no cap branch — so the capped caption defect is
confirmed at source and is invisible to layer 1. S26 now pins the exact iOS string
`"Target: 3× monthly income (capped at 20,000 RON)"` plus a guard that the phantom bare
`"Target"` fallback never renders. **Needs `targetCaption` in the oracle response to be
catchable server-side** — otherwise it is a layer-2-only assertion, and layer 2 is blocked on
test ids.

## 0a. HARNESS GAP CLOSED — there were no Romanian assertions at all

main asked whether my RO assertions would catch the `Search expenses` namespace defect.
**They would not have: there were none.** Every suite asserted English only, so an entire
language could have been wrong — wrong namespace, missing key, untranslated fallback — while
the parity board stayed green. `parity/locale.spec.ts` closes it: catalogue integrity
(offline) plus rendered Romanian per screen, hunting the silent-English-fallback failure mode
that looks correct to anyone reading English.

**It found two real defects on its first run** (logged as `G7`):
`dashboard.Step %lld of %lld` and `dashboard.Target: %lld× monthly income` are missing from
`ro.json`, so the New Month header and the Emergency Fund caption render **English on a
Romanian dashboard**. Both are user-visible sentences, so neither is allowlisted.

## 0. FIRST FULL RUN — 2026-08-06 (read this before reading a red board)

`npm run parity` executed against the live stack for the first time.
**13 passed · 92 failed · 3 skipped.**

**The red is almost entirely one cause, and it is not UI bugs.**

| Evidence | Finding |
|---|---|
| `grep -ro 'data-testid' Web/Client/src` | **0 occurrences** |
| `data-testid` in the built bundle (`dist/assets/index-*.js`) | **0 occurrences** |
| Contract ids probed (`onb-welcome`, `screen-dashboard`, `tab-dashboard`, `dash-summary-income`, `onb-progress-dot`, `nm-transfer-row`, `dash-ef-ring-arc`, `expense-row-amount`) | **all absent** |

So the **test-id contract in `parity/testids.ts` is not yet implemented**. Every suite that
drives the UI fails at the first locator (`onb-welcome`), which cascades: 46 failures never
reached their assertion at all. **None of these 92 failures is evidence of a numeric,
content or behavioural defect** — the suites never got far enough to test anything.

The 13 passes are the offline fixture guards; the 3 skips are the `needs-confirmation`
scenarios, correctly not asserted.

**Second caveat on this run: the server was flapping.** It answered `200` at `globalSetup`,
and by the end of my follow-up checks `DiamerisServer` was not running at all
(`ConnectionRefusedError`). Some failures may be a mid-run restart rather than the client.
The run should be repeated once the contract lands and the server is stable — **treat these
92 as one blocked precondition, not 92 findings.**

### A near-miss worth recording (standing rule #2, on me this time)

My first attempt to check the live locale used `curl -o /tmp/state.json` and then parsed the
file. `curl` failed with `HTTP 000` — but `/tmp/state.json` **already existed from 16:58**, so
the parse succeeded and produced entirely plausible output. I was one step from reporting
stale data as live verification. The instrument agreed with the answer I expected.
Fix applied: read the response in-process (`urllib.request.urlopen`), never via a file that
can pre-exist.

### Locale pin — resolved empirically, and the naming in circulation is wrong

main's message said the pin is `en_US_POSIX`; Backend said `en_US`. **Backend is right**, and
it matters:

- Source: `Web/Server/Sources/DiamerisServerCore/Money/LocalePin.swift:38` → `"en_US"`, with a
  comment explicitly warning that `en_US_POSIX` "is the usual reflex … and it is wrong here".
- Live data: `editing` values are dot-decimal (`1182.5`, `3547.5`, `709.5`) and displays are
  grouped (`1,182 RON`, `27,000 RON`). Under `en_US_POSIX` grouping is disabled, so those
  would read `1182 RON`.

`OQ11` was closed correctly. The *behaviour* is right under either name — but the wrong name
propagating is how someone later "restores" POSIX and silently drops every separator.

---

## 1. Chromium

**Installed and launching.** Playwright `1.62.1`, Chromium `151.0.7922.34`
(headless-shell) + ffmpeg, downloaded to `~/Library/Caches/ms-playwright/`.
Verified with `npx playwright test --list` and by running the offline fixture suite.
Visual verification is unblocked.

---

## 2. What exists in `Web/Verify/`

Standalone npm project, `type: module`, `tsc --noEmit` clean, **79 tests / 4 files**.

| File | Role |
|---|---|
| `playwright.config.ts` | serial (`workers: 1` — one JSON store), `en-US` / `Europe/Bucharest` pinned per R7, list+html+json reporters |
| `parity/testids.ts` | the `data-testid` contract Frontend must implement |
| `parity/flows.ts` | onboarding + New Month drivers, canonical data, expected strings |
| `parity/numbers.spec.ts` | every GROUND-TRUTH "Verified numbers" row, asserted on rendered text |
| `parity/content.spec.ts` | one `describe` per screen (22 screens); ~200 individual string assertions, soft |
| `parity/golden.spec.ts` | the R8/R11 golden-vector harness (see §4) |
| `parity/screens.spec.ts` | 21 screens × light/dark × **402×874** (graded) + 1280×900 = **84 captures** |
| `parity/screen-catalog.ts` | screen ↔ reference-image map, shared by capture and report |
| `parity/global-setup.ts` | one readable "server not running" error instead of 79 stacks |
| `parity/report.ts` | globalTeardown → `output/REPORT.md`, preserves recorded verdicts |
| `README.md` | how to run; `npm run parity` |

`npm run parity:fixture` runs **offline and passes today** (6 tests) — see §4.

---

## 3. The spec gaps

These are the 11 from the first report. **Eight are now resolved** by main's answers of
2026-08-06; **three remain open** (5, 7, 9 — all with the Analyst for a source read).
The "Still open" table below is kept for the audit trail; resolved rows are struck through.

### Resolved by your corrections

| # | Was | Now |
|---|---|---|
| 2 | "Streaming 120 ~3%" — the `~` made it unassertable, and the rounding mode was unstated | §2 proves truncation. Harness asserts `2%`. **But line 125 of `GROUND-TRUTH.md` still reads "Streaming 120 ~3%"** — the Dashboard section was not updated with §2. See OQ7. |
| 11a | Money rounding mode unstated | §1 pins half-even with runtime-confirmed outputs |
| — | New Month step 2 described as a projection | Corrected to the persisted `currentBalance` (`NewMonthSheet.swift:109`) |
| — | "5 steps" vs 7 enumerated screens | Corrected to 7 screens / 5 dots. Harness now asserts 5 dots, active index per screen, and **no dots** on welcome + summary |

### Still open

| # | Gap | Why it blocks an implementer | Suggested fix |
|---|---|---|---|
| ~~1~~ | ✅ RESOLVED — month name follows the selected UI language (`August 2026` EN / `august 2026` RO, lowercase); "current month" is the server's local timezone, and the harness pins the date per R17. |  |  |
| 1 | ~~**Dashboard large title**~~ is "current month + year". No rule for locale, timezone or RO month names. | Two implementers will produce "August 2026", "august 2026" and "August 2026" in different timezones, and the test can only guess. R7 pins the *formatter* locale but not this. | State: month name follows the selected UI language (R7 already says this for months — make it explicit that the Dashboard title is included), and name the timezone the "current month" is computed in. |
| ~~3~~ | ✅ RESOLVED — `1/1 enabled` on each of the four categories, now in GROUND-TRUTH. |  |  |
| 3 | ~~**"n/m enabled"**~~ — the counter format is described but no actual counts are given anywhere. | I had to read `1/1 enabled` off `09-expenses.jpg` to assert it. | Add the four counters to the Expenses section. |
| ~~4~~ | ✅ RESOLVED — added to the table, **plus a standing rule: the table is not exhaustive, and where a screenshot and the table disagree, the screenshot wins.** |  |  |
| 4 | ~~**Category totals**~~ (450 / 120 / 2,500 / 1,200) and **Dashboard Account Balances** (Main `4,270`, Savings `3,548`) are legible in refs 09 and 08 but are **absent from the Verified-numbers table**. | The table is billed as "the web client MUST reproduce these exactly"; an implementer reading only the table will miss six real numbers. | Add them to the table, or state that the table is not exhaustive and the screenshots are also binding. |
| **5 — OPEN** | **"Remaining Money" default.** Ref 08 shows Savings holding 3,548 after month 1, so the default must be **Primary Savings** — but the spec never says which of the two cards is preselected. | It is a behavioural default (D6 axis 3) and it changes every downstream balance. | State the default explicitly. |
| ~~6~~ | ✅ RESOLVED — the caption echoes the **current** balance, not a historical one (`was 7,095 RON last month` on a run holding 7,095). Misleading but it ships that way; assert the literal. |  |  |
| 6 | ~~**New Month step 2 caption "was X last month"** — X is never given. | Cannot assert the caption; currently matched with a regex. | Give the literal for the ground-truth run. |
| **7 — OPEN** | **Settings row `Emergency␣␣• 3× income`** — double space, presumably a copy artefact. | Asserting the literal would bake in a typo; I match whitespace-tolerantly. | Confirm single space, or confirm the double space is real. |
| ~~8~~ | ✅ RESOLVED — 25% / Priority / Percentage are the **defaults**. `stepSavings` now asserts them instead of clicking them. |  |  |
| 8 | ~~**Savings step defaults.**~~ Is 25 % / Priority / Percentage the *default state*, or does the user select it? | Affects whether "Continue" alone reproduces the ground truth. My flow selects them explicitly, which would mask a wrong default. | State the defaults. |
| **9 — OPEN** | **"Skip for now"** appears on two screens with no described behaviour. | D6 axis 3. Untestable as written. | Describe what it skips and what the resulting state is. |
| ~~10~~ | 🟡 PARTLY RESOLVED — refs 20/21/22 captured (New Month 1–2, Insights). Onboarding name/income/expenses deferred until the client runs; graded on prose only. |  |  |
| 10 | ~~**No reference images**~~ for onboarding name / income / expenses, Insights, New Month steps 1–2. | Under R9 these screens have no gradeable artefact — the ±2px criterion has nothing to measure against. Also the 5-dot claim is verified only on accounts and savings. | Either capture the five missing screenshots or state that those screens are graded on prose only. |
| ~~11b~~ | ✅ RESOLVED — `,` grouping (hardcoded, not locale-derived), one ASCII space, currency **code** `RON` never `lei`, ASCII hyphen. |  |  |
| 11b | ~~**Money format details**~~ — `,` grouping, a space before `RON`, ASCII hyphen for negatives. All inferred from the table and ref 08, never written down. | R7 pins the locale, which fixes grouping *size*, but the separator, suffix spacing and negative form are still implicit. | One line in §1. |

### New, found while writing the vectors

| # | Question |
|---|---|
| OQ2 | Does `availableIncome` subtract the **Dashboard raw** total or the **Expenses-tab normalised** total? R3 establishes the two totals differ but not which one feeds the allocation. Vector S10 assumes raw and will catch it if not. |
| OQ8 | R10.3 — when `.primarySavings` is the destination and no such account exists, **where does the money go**? Fall back to Primary, surface a validation error, or expose an `unallocatedRemaining` field? S17 asserts only that it does not vanish. |
| OQ9 | **R8 and R9 contradict each other on the graded viewport.** R8 bullet 2 says 1280×900 is primary; R9 says the 390px column is the only width with an acceptance criterion. I followed R9 (later and more specific) and `REPORT.md` now carries a Graded column — but R8 should be amended. |

Full list with blocking relationships is in `Web/Docs/golden-vectors.json` → `openQuestions`.

---

## 4. Golden vectors (R8 / R11)

`Web/Docs/golden-vectors.json` — **17 scenarios: 13 binding, 4 needs-confirmation**, plus
12 formatter / 9 percent / 6 `isBalanced` pure vectors and 9 open questions.
**Exact decimal strings only** — a fixture test rejects any value that is not
`^-?\d+(\.\d+)?$`, so an inequality cannot be smuggled in.

R11's four mandatory cases, all binding:

- **(a)** `S01` + `S02` — the two-month ground-truth sequence to EF **2,365** / Savings **7,095**,
  chained through `POST /api/new-month`.
- **(b)** `S16` — incomplete `reconciledBalances`. A Joint account holding **5,000** that the
  New Month step never lets the user edit; the dict deliberately omits it. Expected: it still
  holds 5,000. `0` or `4,270` is the R10 failure mode.
- **(c)** `S17` — `.primarySavings` with no such account. Asserts a **conservation invariant**
  (the parts must sum to income, missing parts counted as zero) rather than a destination,
  because the destination is not decided yet.
- **(d)** `S08` — emergency already at target; allocation must be 0 and the whole 1,182.5 flows
  to savings.

Other discriminating cases: `S09` (EF 100 short → cap at 100, spill 1,082.5, which also
exercises half-even *down* to `1,082`), `S04` (1183.5 → `1,184` **and** 3550.5 → `3,550` in one
scenario — half-up fails the second, truncation fails the first, only half-even passes both),
`S05` (26,999/27,000 → **99 %**, never 100), `S10`/`S11` (the R3 dual totals: 3,700 vs 2,600,
and 2,950 vs 2,500 with `1/2 enabled`), `S06` zero income, `S07` the `max(0, …)` clamp.

Deliberately **not asserted**: `S12`/`S13` (split ratio), `S14` (fixed-amount clamp),
`S15` (boost multiplier). Each is blocked by a numbered open question, and a fixture test
fails if a `needs-confirmation` scenario has no question pointing at it. An unverified guess
must not become the definition of correct simply because someone wrote it into a JSON file.

**The Playwright side asserts it in two layers**, which is the part that matters:
layer 1 seeds each scenario through the API and checks the server's raw decimals, percents
and flags; layer 2 re-checks the *same* `expected.display` strings as **rendered text**.
Layer 1 alone would let a correct server and a broken UI pass together.

`npm run parity:fixture` (offline, no server, **passes now** — 6 tests): re-derives every
percent by truncation and compares to the fixture, proves at least two vectors where rounding
and truncation disagree, brackets the `0.01` boundary from both sides, checks R11's four
mandatory scenarios are present *and* binding, and rejects inequalities.

---

## 5. Dependencies on others

- **`POST /api/reset` is load-bearing.** Every test resets the store through it. Without it
  the harness cannot run at all.
- **`POST /api/new-month` must accept a partial balance dict** and defend the precondition
  itself (R10.2) — `S16` fails if it delegates that to the caller.
- **Frontend must implement `parity/testids.ts`.** Numbers and controls need stable hooks;
  user-readable strings are queried by text, because asserting the string *is* the check.
- **Backend and I must agree the fixture shape** — messaged separately.

---

## 6. Honest status

No suite except `parity:fixture` has ever passed, because there is nothing to run against.
That is the intended state: the harness was written ahead of the client so there is a verdict
the moment it lands. Every failure names the GROUND-TRUTH row or screen it came from.
