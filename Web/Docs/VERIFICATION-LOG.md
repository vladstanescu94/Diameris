# Verification log

Checks run with real output, by the orchestrator or by an agent that recorded its evidence.
Anything not in here should be treated as a **report, not a proof**. Keeping that distinction
visible is the point of this file.

## 📋 2026-08-06 — FINAL BOARD (`Web/Verify/output/BOARD.md`)

| | Before corrections | After |
|---|---|---|
| Passed | 53 | **70** |
| Failed | 62 | **45** |
| Test ids observed live | 23 | **88** |
| Unreachable surfaces | 6 | **0** |
| Visual captures | 8 | **48 / 88** |
| Screens *graded* | 0 | **0** |

**Six reported causes resolved down to TWO genuine client findings:**
1. Income step — `RON` suffix not visible. → Frontend
2. Accounts step — Emergency `aria-label` missing `27,000 RON`. → Frontend

Four were withdrawn as harness/contract bugs: the `aria-checked`-on-`role="tab"` assertion (the
single largest cause, ~35 results, 17 converted by one edit), the screen-roots bundle-grep
artifact, a stale `REPORT.md` mistaken for a generator bug, and the `expenses.Amount` absence
(closed with the SharedUI `.main`-binding evidence).

**Standing verdict, unchanged and deliberately not upgraded:**
- **Numeric parity — PASS, but server-scoped.** 26/26 golden vectors against the API. Layer-2
  rendered-text assertions have never executed, so no `display` value is confirmed **in the DOM**
  — which is precisely the divergence layer 2 exists to catch.
- **Content / behavioural — improving, not established.**
- **Visual — NOT established.** 48 captures exist; **zero have been judged.** Half the artefacts,
  none of the verdicts.

**Remaining preflight count (47 unverified) is an upper bound, not a defect list** — the preflight
doesn't open modals or reach New Month step 3, so most are *unvisited*, not absent. Genuinely
suspicious on reachable screens: `onb-summary-*`, `onb-after-expenses-value`,
`onb-savings-permonth-caption`.

## ✅ 2026-08-06 — Visual sweep: **8 → 48 of 88 captures**, both themes, both viewports

Two harness fixes unblocked it, **neither a client defect**:

1. **`onb-name-field` missing** → `stepName()` couldn't fill, `Continue` stayed *correctly*
   disabled, run died as a 180s timeout that read as a broken screen. (8 → 24)
2. **`aria-checked` asserted on `role="tab"`** — invalid ARIA; `aria-selected` is correct. This
   single assertion inside `stepSavings` was **the largest cause on the whole board (~35 results)
   plus six "unreachable" surfaces**, because every walkthrough traverses it. (24 → 48+)

Now covering all 7 onboarding screens, Dashboard, Expenses, expanded-category, Add Expense and
Manage Categories, in light + dark at both widths.

**Dashboard graded against `08-dashboard.jpg` — ✅ match.** Title `August 2026`; summary
`9,000` / `-4,270` (red) / `1,182` (cyan) / **`3,548`** bold; emergency ring `4%` with
`1,182 RON / 27,000 RON` and `Target: 3× monthly income`; balances `4,270` + `Primary` pill and
`3,548`; breakdown **58% / 28% / 10% / 2%** — all four, including the truncated `2%` that started
this project's numeric investigation. Toolbar correctly shows **only** the gear (dev tools is
`import.meta.env.DEV`-gated, R16), which is a deliberate difference from the reference.

### The pattern across this whole final phase

**Three of us independently blamed infrastructure for a single missing hook.** I attributed the
sweep failure to port contention; the Reviewer attributed its 92 failures to the same; both were
one missing test id. And three of us got wildly wrong numbers from source greps of the test-id
contract — mine `105/105`, Frontend2's false-seven, the Reviewer's `50/83` — because ids arrive
via JSX expressions, `testId` props and template literals. **Only the DOM knows.** The Reviewer's
runtime preflight (`parity:contract`) is the durable fix, and it corrected *itself* twice before
being right — once inventing 209 false positives in a file whose docstring warns about exactly
that.

The generalisation worth keeping: **when a diagnosis is "the environment", check for a missing
hook first.** Infrastructure explanations are seductive because they're always partly true.

## 🟡 2026-08-06 — Earlier: sweep 8 → 24 of 88. Root cause found and fixed.

**The sweep had never completed, and the cause was not port contention** (which I had wrongly
told the Reviewer, having just diagnosed contention elsewhere and over-generalised it).

**Real cause: one missing test id.** `stepName()` fills the name field via
`getByTestId('onb-name-field')`; that id did not exist in the client. The fill silently no-op'd,
`Continue` stayed **correctly** disabled, and the run died as a **180s timeout** — taking every
screen after it. The failure snapshot showed `button "Continue" [disabled]`, which reads exactly
like a broken screen.

Fixed (`NameScreen`) → captures went **8 → 24**, now covering 6 onboarding screens × 2 themes ×
2 viewports. Frontend2 independently found and fixed the same class on the savings slider.

**Still outstanding, both small and both harness-side, not client defects:**
1. The sweep stalls after the savings screen (summary onward never captured). Same shape —
   diagnose by reading `error-context.md`'s page snapshot, not by guessing.
2. `output/REPORT.md` marks files that **do exist** as `❌ not captured` — a path-resolution bug
   in its own generator. So the report currently understates coverage.

### ⚠️ My test-id diff tool was wrong three times, and I acted on it twice

Recording this against myself because it is the exact failure this log exists to prevent.

| Attempt | Claim | Reality |
|---|---|---|
| 1 | "**105 of 105** contract ids missing" | matched only literal `data-testid="…"`; the client uses JSX expressions and `testId` props |
| 2 | `settings-strategy-priority`/`-split` absent | present via a **template literal** |
| 3 | `onb-savings-percent-slider` absent | **already present** — my "fix" added a duplicate prop and broke the build until reverted |

Only the first was implausible enough to catch on sight. **I should have validated the scanner
against a known-present id before trusting it** — which is precisely Standing rule #2, written
five times in this file by me, about other people's instruments.

The `onb-name-field` finding was real and valuable. Every subsequent conclusion from the same
tool was noise. **A tool that is right once is not a tool that is right.**

## 🟡 2026-08-06 — Visual grading: partial. 4 captures graded by the orchestrator, sweep incomplete.

I stood up a **dedicated** instance (`DIAMERIS_PORT=8090`, own store, no other agent on it —
`lsof` confirmed pid 59093 sole listener) and ran `parity/screens.spec.ts` against it via
`DIAMERIS_URL`. It produced **8 captures (2 screens × 2 themes × 2 viewports)** and then stalled
without completing or reporting. **I am recording it as partial rather than claiming a run.**

**What I graded myself, at the graded 402px width, against `reference-screens/`:**

| Screen | Theme | Verdict |
|---|---|---|
| Welcome | light | **PASS** — halo circle, 2-line heavy title, 3-line subtitle, 3 tinted bullets (cyan/magenta/cyan), full-width magenta pill. Layout and hierarchy match `01-onboarding-welcome.jpg`. |
| Welcome | dark | **PASS** — canvas is pure `#000000` per R19, text inverts, accent correctly lightens to the dark-variant magenta on the CTA, bullet tints hold. |
| Name | light | **PASS on prose** — 5-dot indicator with dot 1 active (R-corrected 7-screens/5-dots rule), correct title/subtitle/placeholder, `Continue` rendering in its **disabled** style with the field empty. |
| Name | dark | **PASS on prose** |

⚠️ **One enumerated deviation, visible and expected:** the sparkle glyph is a **Lucide stroke
icon** where iOS uses a filled SF Symbol. SF Symbols cannot be redistributed (D3), so every icon
is a mapped substitute. This is the single most visible cosmetic difference in the port and it is
by design.

⚠️ **The Name screen has no reference image** — it is one of the three onboarding screens I never
captured from the simulator, so it is graded **against prose only**, not against a picture. Stated
rather than glossed.

**Honest position on the visual axis:** every screen has been driven and compared by its
implementer (onboarding 27/27 light + 27/27 dark; modals 31/31 + 31/31), and 4 screens are now
independently graded by me. **A complete automated ±2px sweep across all 19 screens has never
finished** — the harness lost its server to port contention repeatedly, and this last attempt
stalled. `Web/Verify` is ready and `DIAMERIS_URL` targets any instance; it needs one
uninterrupted run.

## ✅ 2026-08-06 — CLOSEOUT: full stack verified end to end

Run by the orchestrator after the final round of fixes.

| Check | Result |
|---|---|
| Server builds | `Build complete!` |
| Client `tsc --noEmit` | clean |
| Client tests | **151 passed / 2 skipped** (9 files) |
| Client build | clean |
| API propagation gate | **28/28, 0 outstanding** |
| App serves | `/` → **200**, `/api/state` → **200** |
| iOS app | `** BUILD SUCCEEDED **`, Dashboard **77 tests pass** |
| iOS scope | exactly the 5 authorised edits + 1 new Domain file |

**Final defects fixed and verified in this round:**

1. **R36 / Critic item 1 (HIGH) — Settings savings section predicate.** iOS is
   `accountType == .savings || isPrimarySavings` (`SettingsSheet.swift:61-63`); the web had
   dropped the second disjunct, so an account flagged `isPrimarySavings` while typed `.personal`
   showed the section on iOS and hid it on the web. Fixed **both** sides:
   - client predicate corrected with the reasoning inline;
   - server normalises in `AccountRecord.init` — the **single choke point every write path uses**
     (onboarding, POST/PUT, golden seeder) rather than per-caller, per R33. iOS normalises on save
     (`:605-607`); our API didn't, which is what made the state reachable at all.

   Verified: `POST /api/accounts {accountType:"personal", isPrimarySavings:true}` → 200, then
   `GET /api/state` → `isPrimarySavings=False`. **The divergent state is now unreachable rather
   than merely handled.**

2. **`targetCaption` hard-cap branch** — was silently dropping `(capped at X)`. Verified live:
   `targetCaption: "Target: 3× monthly income (capped at 20,000 RON)"`.

3. **Phantom `?? "Target"` fallback** removed (a string iOS can never render).

4. **En dash → hyphen** on the New Month completion button; the en dash now survives only as a
   *planted non-vacuity case* inside `lib/i18nKeys.test.ts` — i.e. the R35 key-resolution guard
   exists and is tested against the very defect that motivated it.

5. **Dev Tools** ported as dev-only tooling behind `import.meta.env.DEV`
   (`features/devtools/DevTools.tsx`), per R16 — reset + seed only, not a user-facing screen.

## ✅ 2026-08-06 — Regression checkpoint: **the app being ported is not broken**

Run by the orchestrator. We modified shipping iOS code hours ago (R1's Domain lift + the
authorised platform/`canImport` edits); this re-confirms nothing has drifted since.

| Check | Result |
|---|---|
| iOS app builds | **`** BUILD SUCCEEDED **`** |
| Dashboard package tests | **`Test run with 77 tests in 18 suites passed`** — same count as before the lift |
| Web client tests | **144 passed / 8 files**, `vite build` clean |
| API propagation gate | **28/28 propagated; 0 outstanding** |
| iOS scope discipline | **exactly the 5 authorised modifications + 1 new Domain file.** No unauthorised edits to `Packages/`, `Diameris/`, the Xcode project, or either test target. |

Web tree: 217 source files (Swift/TS/TSX/CSS/MD/SH/PY, excluding `node_modules`, `.build`, `dist`).

**Why this check matters and why it's mine:** the brief was to build a web client, not to change
the iOS app. Five files were modified under explicit authorisation and one added; everything else
in `Packages/` is untouched. A port that quietly breaks its source is a failure regardless of how
good the port is, and nobody else on the team has both the mandate and the simulator to verify it.

## ✅ 2026-08-06 — API gate: **28/28, idempotent, three consecutive clean runs**

```
$ for i in 1 2 3; do python3 Web/Docs/api-propagation-check.py | tail -1; done
28/28 propagated; 0 outstanding
28/28 propagated; 0 outstanding
28/28 propagated; 0 outstanding
```

Every API-affecting ruling (R7, R12, R13, R14, R17, R18, R20, R23) is now implemented **and
mechanically verified from a clean reset**. All nine numeric ground-truth assertions pass, both
palettes are complete (37 icons ending at `sparkles`, 12 category icons, 10 colours), the
**`en_US`** formatting pin landed, and the double-spaced subtitles are gone.

⚠️ **Name correction, flagged by the Reviewer:** earlier text in this file (and my messages) said
"the `en_US_POSIX` pin". **Wrong name.** Formatting is pinned to **`en_US`**
(`LocalePin.swift:38`); only *parsing* uses `en_US_POSIX` (`DecimalString.swift:35`). The
behaviour is correct either way it's described, but the wrong name propagating **is exactly how
someone later "restores" POSIX and silently drops every thousands separator** —
`en_US_POSIX` sets `usesGroupingSeparator: false`, so `9,000 RON` becomes `9000 RON`. See R7.

**Also answered by testing rather than asking a fourth time:**
- `POST /api/reset` → **200**. Works. (Asked three times, never confirmed by report.)
- `X-Diameris-Now` → **honoured**; pinning `2026-01-15` yields `currentMonthDisplay: "January 2026"`.
Both were built but never reported. **Verifying beat asking.**

### ⚠️ My own instrument had the bug it was built to catch

The first version of this gate **assumed** the store already held the ground-truth data. The
moment I called `POST /api/reset` to test it, the gate fell from 20/25 to 13/25 — not because
anything regressed, but because its numeric assertions depended on state it never established.

It now **seeds itself**: `POST /api/reset` → `POST /api/onboarding/complete` with the
ground-truth payload → assert. Hence idempotency, and hence a result that describes the *code*
rather than the *fixture*.

This is the same defect the Reviewer found in its own harness on the same day: its transfer-row
test ids were **account-keyed**, so a client that collapsed two same-account rows would have
satisfied the ids exactly — the bug was baked into the test contract. Now ordinal.

## Standing rule #2 — the instrument agrees with the bug

Distinct from the standing rule below, and rarer and worse: **a verification artefact that
certifies the defect it exists to catch.** Four instances, four different people:

| Instrument | How it certified the bug |
|---|---|
| Icon-count assertion (Reviewer) | Asserting `18` would have **ratified** the server's truncation at `creditcard.fill`. Fixed with count **plus tail** (`ends at sparkles`). |
| Transfer-row test ids (Reviewer) | Account-keyed ids made row-collapse **unfalsifiable**. Fixed: ordinal ids, whole list compared in one `toEqual`. |
| API propagation gate (orchestrator) | Assumed its own fixture, so it reported the store's state, not the code's. Fixed: self-seeding. |
| `App.test.tsx` locale assertion (Analyst) | Passed **because** the namespace was an empty stub; the real value is `"Hai să începem"`. Fixed: absent key for fallback + a test on the real value. |
| Locale check via a temp file (Reviewer) | `curl -o /tmp/state.json` **failed** (`HTTP 000`), but the file already existed from an earlier run — so the parse succeeded and produced entirely plausible output. **Stale data one step from being reported as live verification.** Fixed: read in-process, never via a path that can pre-exist. |

The fifth instance is the most instructive: **nothing in the output would have revealed it.** A
failed fetch plus a stale artefact produces a confident, well-formed, wrong answer. Never verify
through a file that can exist before the command runs.

**The generalisation, in the Reviewer's words:** *whenever a test id encodes an identity
assumption, the assumption becomes unfalsifiable.* Standing checks now expected of everyone:
- Does this assertion assume uniqueness, ordering, or a count I have not verified?
- Does it establish its own preconditions, or inherit them?
- Would it still fail if the value under test were wrong in the most likely way?
- Am I asserting the value, or asserting my belief about the value?

## Standing rule #5 — a shared server mid-reset produces *plausible* failures, not obvious ones

Frontend2 had **two browser runs produce entirely bogus pass/fail sets** because port 8080 was
mid-reset: one showed every expense assertion failing with `availableIncome = 9,000`, another
showed the Account section missing. **Both looked exactly like real UI bugs** — not like an
outage.

This is the seventh instance on this project of an instrument producing a confident wrong answer,
and it is the most dangerous shape because the failure is *specific and diagnosable*. Someone
would have spent an hour fixing a working screen.

**Rules:** grade only from a run on an **isolated** port with its own store (R29); retry the load
before believing a failure set; and treat any single run on the shared 8080 as provisional
regardless of how coherent its failures look.

## ✅ Closed: `POST /api/onboarding/complete` — the last unverified write path

Ran for real against a disposable store on :8082 (8080/8081 untouched, instance shut down, store
deleted). Committed as an opt-in test that builds the payload through the **real**
`createDraft → addAccount → updateExpense → toPayload` path rather than a hand-made fixture, and
asserts §2.8's write: profile `Vlad`, income `9,000 RON`, 4 expenses totalling `4,270 RON`,
savings at 25% prioritized, emergency multiplier 3 / target `27,000 RON`, and balances pre-applied
— **Main `4,270` (assigned, not added) · Emergency `1,182` · Savings `3,548`**.

It **fails loudly rather than skipping** when unreachable, and refuses to write unless the store is
fresh — so it cannot quietly destroy a populated store. That last property is what makes it safe
to leave committed.

## Standing rule #4 — the runtime accessibility snapshot describes the *declared* view, not the *rendered* one

**Both of my `GROUND-TRUTH.md` errors have this single root cause**, and I didn't see the pattern
until the second one.

| Error | What the snapshot said | What actually renders |
|---|---|---|
| Account subtitle | one flattened label `"Emergency␣␣• 3× income"` | **2–3 separate `Text` views** with an 8pt gap and per-part colours — the doubled space was a concatenation artefact |
| Monthly\|Annual control | `e30\|tap\|tab\|Monthly\|1\|calendar` — an SF Symbol name | **bare text.** `.pickerStyle(.segmented)` discards the image entirely |

In both cases the accessibility tree faithfully reported what the view *declared* —
`Label(displayName, systemImage:)`, sibling `Text` views — while the screen showed something else.
The snapshot is an excellent instrument for **structure and interaction targets** and an unreliable
one for **rendered appearance**.

**Why this one was hard to catch:** the second error was *corroborated by the source*.
`FrequencyPicker.swift:17` really is `Label(displayName, systemImage: icon)`. Two implementers
independently added icons from doc + source agreeing, and only a **screenshot** disproved both.

**Rule:** for anything visual, the screenshot is the authority — over the accessibility snapshot,
and over the source. Use the snapshot to find *what to tap*, not *what it looks like*.

⚠️ And note the failure mode this creates for docs specifically: my error propagated into a
document, the document was believed over the image, and a comment written at the call site
**cannot reach whoever reads the doc next.** Fixing the doc was the necessary part; Frontend was
right that the code comment alone was only a stopgap.

Companion finding from the same pass, same shape: the colour grid rendered **7-then-3** instead of
**6-then-4** — a 44pt cell against a 36pt swatch yields one extra column at the 402px width.
Invisible to every test we had, visible immediately in the screenshot.

## Standing rule #3 — `.localized` names a lookup; it does not mean the lookup succeeds

Three orphaned catalog entries found so far, all the same shape: **a translation a static
extractor wrote that the runtime can never reach.**

| Orphan | Why it's unreachable |
|---|---|
| `app.Other = "Altele"` | `"Other"` appears in no app-target Swift; `AccountType.displayName` resolves in `domain` → `"Altul"` |
| `expenses."Total %@ Expenses" = "Cheltuieli %@ totale"` | `"Total \(x) Expenses".localized` interpolates **first**, so the runtime key is `"Total Monthly Expenses"` — never `%@` |
| `expenses.Monthly = "Lunar"` | `Frequency.displayName` is *Domain* code binding `bundle: .module`; `Monthly` is **absent** from the Domain catalog |

**This produced a real wrong instruction from me.** I ruled (on the Critic's finding) that the
Expenses header renders the mixed string "Total **Lunar** Expenses" and that all served
`displayName`s need `tDomain`. The Analyst disproved both; I verified directly:

```
Domain catalog:    'Monthly' ABSENT   'Annual' ABSENT   'Total %@ Expenses' ABSENT
Expenses catalog:  'Monthly' ro='Lunar'  'Annual' ro='Anual'  'Total %@ Expenses' ro='Cheltuieli %@ totale'
Domain/Utils/Localization.swift:  String(localized:, bundle: .module)
```

iOS renders **"Total Monthly Expenses"** — fully English, both words. So rendering
`f.displayName` raw was **already correct**, and my "fix" would have turned a non-bug into a
divergence: the exact R26a violation the Critic had been guarding against.

**The rule — and it is stricter than my first version. THREE things must agree:**

1. **The call form.** Verified by probe (`String.LocalizationValue`, real Swift):
   ```
   Form A  String.LocalizationValue("Nice to meet you, \(name)!")
           → key "Nice to meet you, %@!"     arguments ["Vlad"]   ✅ RESOLVES
   Form B  let s = "Nice to meet you, \(name)!"; LocalizationValue(s)
           → key "Nice to meet you, Vlad!"   arguments []         ❌ DEAD
   ```
   Interpolation is captured as `%@` **only from a literal**. The `.localized` computed property
   receives an already-interpolated runtime `String`, so the key carries the *substituted value*
   and can never match the catalog. `String.localized(_ key: LocalizationValue)` takes a
   `LocalizationValue`, so it is Form A and resolves.
2. **Which bundle it binds** (`bundle: .module` → that package's catalog only).
3. **Whether that catalog holds the key.**

**Exactly ONE dead lookup exists in the codebase:** `ExpenseListView.swift:91`. The Critic first
reported "20 dead interpolated lookups across 3 modules", then **caught it before sending because
the number felt too large**, probed, and corrected to one. Most `%@`-keyed entries are Form A and
resolve fine.

**So iOS renders "Total Monthly Expenses" fully English for TWO independent reasons** — the
wrapper is a dead Form-B lookup, *and* the inner word was already English via the bundle
mismatch. Neither alone gives the right answer, which is why two people each got it half right.

Method note, in the Critic's words: *a `.localized` call site tells you nothing on its own.*
Checking one of three gave a wrong answer; two of three gave another wrong answer. **Stop
reporting localization conclusions from static reading alone** — the cheap decisive instrument is
a `swift` probe plus a catalog query, and both are seconds.

**Corollary (R28e), and it reframes the class:** SwiftPM **never compiles `.xcstrings`** — the
Domain bundle ships the raw file, no `.lproj`, because that's an Xcode-only step
(`xcstringstool`). So **the server physically cannot serve Romanian**; every `*DisplayName` it
sends is an **English lookup key**, not display text. Verified three ways, including live
`/api/state` returning `"Emergency"` / `"Priority"` / `"Primary Savings"`.

## Standing rule, learned the hard way three times

**A filtered or partial view of the evidence is not the fact.** Three instances on this project,
all different people, all the same failure mode:

| Instance | What happened |
|---|---|
| Orchestrator | Read a *too-narrow grep* of test output as "only 5 tests exist" → coverage looked vacuous. Real count: 77. |
| Orchestrator | Counted **18** icons from a **clipped screenshot**; the 18th happened to be the last visible symbol, so the miscount looked self-consistent and propagated into 3 documents. Real count: 37. |
| Critic | `grep -l "struct ExpenseCategory"` **substring-matched** `struct ExpenseCategoryCard`, turning a SwiftUI View into a phantom data type → became R6, a decision built on nothing. |

Corrections now expected of everyone: anchor identifier greps (`\bstruct X\s*[:{]`), open the
file before promoting anything to a finding, count from source rather than from an image, and
never read a filtered command output as a complete result.

A fourth, related instance: **390px vs 402px** — both the orchestrator and the Critic asserted
the iPhone 17 Pro logical width from memory without measuring. That one would have corrupted
the *acceptance criterion itself*, mis-grading every screen by 12px.

---

## 2026-08-06 — ⚠️ Systemic finding: rulings were landing in docs, not in code

Frontend noticed `reference.expenseIcons` still returned 18 entries and asked whether other
corrected docs had failed to propagate. They had. I swept the **live server** against every
API-affecting ruling: **9 of 25 passed, 16 outstanding.**

The nine that passed were the numeric ones — half-even, truncation, all four breakdown
percentages. The sixteen failures were every *structural* ruling made after the server was
first written: R12 palettes, R13 slider table, R14 fields, the whole R18 closed set, R23's
subtitle, R7's locale pin.

**Root cause, and it was mine:** ~20 rulings were issued by message while Backend was building,
and *nothing was checking whether they reached the code*. Docs and decisions accumulated;
the API surface silently didn't move. Agents reported progress truthfully and I read it as
propagation.

**Fix — a re-runnable gate rather than another message:**

```
$ python3 Web/Docs/api-propagation-check.py
9/25 propagated; 16 outstanding      (exit code = count outstanding)
```

Exit 0 is now the definition of done for the API. Every new API-affecting ruling adds a check.
This is the same lesson as the standing rule above, one level up: **a decision written down is
not a decision implemented.** The distinction between *proven* and *reported* has to be
mechanical, because reading reports as proof is exactly the failure mode.

## 2026-08-06 — 🎉 Server serves `GET /api/state` and reproduces the iOS numbers exactly

Run by the orchestrator: `swift build` → `Build complete! (15.27s)`, launched
`.build/debug/DiamerisServer`, `curl http://127.0.0.1:8080/api/state` → **200**.

**Numeric parity, server vs the live iOS app, same inputs:**

| Field | Server | iOS | |
|---|---|---|---|
| `summary.income` | `9,000 RON` | `9,000 RON` | ✅ |
| `summary.expenses` | `4,270 RON` | `-4,270 RON`¹ | ✅ |
| `summary.savings` | `"1182.5"` → **`1,182 RON`** | `1,182 RON` | ✅ **half-even correct** |
| `summary.personalSpending` | `"3547.5"` → **`3,548 RON`** | `3,548 RON` | ✅ **half-even correct** |
| Emergency balance / target | `2,365 RON` / `27,000 RON` | same | ✅ |
| `emergencyProgressPercent` | `8` from `0.08759…` | `8%` | ✅ **truncation correct** |
| Breakdown Rent / Food / Gas / Streaming | `58%` / `28%` / `10%` / **`2%`** | identical | ✅ all four |
| `currentMonthDisplay` | `August 2026` | `August 2026` | ✅ |

¹ the minus is applied by the Dashboard view, not the formatter — consistent with R7's note.

This is the single most important result so far: **the reused Swift `Domain` +
`AmountFormatter` reproduce every value with no client-side arithmetic**, which was the entire
premise of D1/R2. Both hard cases — half-even on `.5` and truncation on percentages — are
correct without anyone hand-writing a rounding rule in JavaScript.

**Deltas still outstanding, from the same response:**

| Delta | Evidence | Ref |
|---|---|---|
| `expenseIcons` is **18**, must be **37** | `len(reference.expenseIcons) == 18` | R12 |
| `categoryIcons` / `categoryColors` absent | not in `reference` keys | R12 |
| `savingsSliderPositions` absent | substring not present anywhere in the response | R13 |
| `editing` uses a **comma**: `"1182,5"` | contract §2.4 documents `"1182.5"` | locale bug, R7 |
| `subtitle` contains a **double space**: `"Emergency␣␣• 3× income"` | verbatim in the response | ⚠️ see below |

⚠️ **The double space is probably my fault propagating.** It reached the server from my
`GROUND-TRUTH.md`, which took it from a *runtime accessibility label* that concatenates two
separate text elements (`"Emergency"` and `"• 3× income"`). If iOS renders them as two views
with layout spacing, the server is baking in a typo that never existed. Pending an Analyst
source read — a fourth instance of the standing rule at the top of this file.

## 2026-08-06 — Environment

| Check | Result |
|---|---|
| Swift toolchain | 6.3.3, target `arm64-apple-macosx26.0` |
| Vapor resolves + builds on macOS | **PASS** — Vapor 4.122.0, `swift build` → `Build complete! (63.17s)` |
| Node / npm | v24.4.1 / 11.4.2, registry reachable (`npm ping` → PONG) |
| `Domain` free of iOS-only imports | **PASS** — no `UIKit`/`SwiftUI`/`Combine`, no `#if os(...)`, no availability pins |
| `Utilities` iOS-only files | 2 found: `HapticManager.swift:1`, `KeyboardHelper.swift:1` |

## 2026-08-06 — R1: `computeUpdatedBalances` lifted into Domain

The highest-risk edit in the project, because it modifies shipping iOS code. Gate was:
tests pass **unchanged** AND the iOS app still builds. Both were verified by me, not reported.

| Check | Result |
|---|---|
| Diff is a faithful *move*, not a rewrite | **PASS** — logic identical line-for-line; new file `Packages/Core/Domain/Sources/Domain/UseCases/BalanceReconciler.swift`, VM delegates in one call |
| The one substitution is safe | **PASS** — `accounts` → `makeAccountEntries()`; `toAccountEntry()` (`DashboardViewModel.swift:64-75`) preserves all four fields the reconciler branches on: `id`, `accountType`, `isPrimary`, `isPrimarySavings` |
| iOS app builds | **PASS** — `** BUILD SUCCEEDED **` |
| Dashboard tests pass | **PASS** — `Test run with 77 tests in 18 suites passed`, `** TEST SUCCEEDED **` |
| Tests actually cover the moved code | **PASS** — there is a dedicated `Suite "Compute Updated Balances"`; 6 call sites in `DashboardViewModelTests.swift` covering the `primarySavings`, `personal` and `primary` destinations, joint expense transfers, and the primary-is-assigned-not-accumulated rule |

⚠️ Process note: my first test run used too narrow a grep and showed only 5 parameterised
tests, which made coverage look vacuous. Re-running with a correct filter showed 77. The
lesson is in the log deliberately: **a filtered test output is not a test result.**

Scope check — `git status` confirms the only modified iOS files are the five authorised ones
(2 manifests, 2 `#if canImport(UIKit)` wraps, 1 delegating VM) plus the new Domain file.
No unauthorised edits.

## 2026-08-06 — Icon grid count: 37, settled in source

Two agents disagreed (Analyst said 37, Critic said 18, my `GROUND-TRUTH.md` said 18), so I
counted rather than adjudicate:

```
$ awk 'NR>=193 && NR<=231' .../AddExpenseSheet.swift | grep -c '"'
37
$ sed -n '193,231p' .../AddExpenseSheet.swift | grep '"' | sed -n '18p'
        "creditcard.fill",
```

**37 icons.** The 18th entry is `creditcard.fill` — the last symbol visible in my clipped
screenshot — which is why my miscount looked independently confirmed when the Critic echoed it.

Root cause worth remembering: **I inferred a list length from an image.** The error then
propagated into `GROUND-TRUTH.md`, the Critic's audit, and `API-CONTRACT.md` before anyone
counted the source. R12 now makes all three palettes server-served so no document can drift.

## 2026-08-06 — Numeric rules confirmed in the running app

| Rule | Evidence |
|---|---|
| Percentages **truncate** | Gas 450/4270 = 10.53% renders **10%**; Streaming 120/4270 = 2.81% renders **2%**. Rounding would give 11% and 3%. Verified by scrolling the live dashboard, not inferred from source. |
| Money is **half-even** | Critic verified `NumberFormatter.roundingMode` default is `.halfEven` (rawValue 4) at runtime: `1182.5→1,182`, `3547.5→3,548`, `2.5→2`, `1183.5→1,184` |
| 8 default categories, one canonical list | Manage Categories screen lists all 8 with icons/colours matching Domain's `Category.defaults`; the Expenses tab showed 4 only because 4 had expenses. R6 downgraded. |

## 2026-08-06 — Column width: **402px**, settled from the screenshots (Critic)

I told `main` 390px and R9 adopted it. **I was wrong; Frontend's 402 is correct.** I asserted a
number I had not measured — the same error class as my 18-icon echo.

The reference screenshots are downscaled (`368×800`), so they cannot be read off directly — but
the aspect ratio settles it:

```
$ for f in *.jpg; do sips -g pixelWidth -g pixelHeight "$f"; done   # all 368 x 800
402/874 = 0.459954 -> width at height 800 = 367.96  -> 368  ✅ matches
390/844 = 0.462085 -> width at height 800 = 369.67  -> 370  ❌
393/852 = 0.461268 -> width at height 800 = 369.01  -> 369  ❌
```

iPhone 17 Pro logical width is **402×874**. `--app-width: 402px` in `tokens.css:167` is right.
**R9's ±2px grading at 390 would have mis-graded every screen by 12px.**

## 2026-08-06 — `Money.editing` is locale-dependent — **live bug on this machine** (Critic)

`Money.swift:22` calls `AmountFormatter.formatForEditing(value)`, which builds a bare
`NumberFormatter()`. Its `locale` defaults to `Locale.current`, and only the *decimal* separator
is left unpinned (grouping is forced to `""`). R7 pinned parsing (`DecimalString.swift:35`,
`en_US_POSIX`) but **not** formatting.

```
$ swift loc.swift
Locale.current: en_US@rg=rozzzz
formatter.locale: en_US@rg=rozzzz   decimalSeparator: ,
formatForEditing(1182.5) = "1182,5"
```

This dev machine is `en_US@rg=rozzzz` (US English, **Romanian regional formats**), so the server
emits `"editing": "1182,5"` while `API-CONTRACT.md` §2.4 documents `"1182.5"`. Not hypothetical
and not a foreign-deployment edge case — it is what this team's own machine produces today.
Fix: pin `formatter.locale = Locale(identifier: "en_US_POSIX")` in the server's Money assembly
(not in `Packages/`, which must keep iOS's device-locale behaviour).

## 2026-08-06 — iOS formatter/parser edge cases, run against real Swift (Critic)

Probe replicating `AmountFormatter` exactly, on the shipped configuration:

| Input | iOS actual | `money.ts` | |
|---|---|---|---|
| `formatForDisplay(-0.4)` | `-0` | `0` | ❌ divergence |
| `formatForDisplay(-0.5)` | `-0` | `0` | ❌ divergence |
| `formatForDisplay(-0.6)` | `-1` | `-1` | ✅ |
| `parse("1e3")` | `1000` | `1` | ❌ divergence |
| `parse("12abc")` | `12` | `12` | ✅ |
| `parse("1.2.3")` | `1.2` | `1.2` | ✅ |
| `parse("5.")` | `5` | `5` | ✅ |
| `formatForEditing(0.125)` | `0,12` | `0.12` | ✅ (half-even; separator per above) |
| `formatForEditing(0.135)` | `0,14` | `0.14` | ✅ |

`money.ts:247-249` suppresses the sign for a rounded-to-zero magnitude, and its comment asserts
`NumberFormatter` never emits `-0`. **That assertion is empirically false.**

## 2026-08-06 — `src/ui/` review: R2 clean; progress arcs exceed the ±2px tolerance (Critic)

**R2 — clean, and well engineered.** `grep` for `Number(`/`parseInt`/`parseFloat`/`toFixed`/
`Math.*`/`Intl.*`/`toLocaleString`/`reduce(`/infix `*` across `src/ui/*.tsx|ts`: **zero hits.**
`ProgressRing` uses `pathLength={100}` so the dash array *is* the percentage; `ProgressBar` and
`Slider` push values into CSS custom properties. No JS arithmetic anywhere. `--app-width: 402px`
confirmed (`tokens.css:167`). No hardcoded palette in `primitives.tsx` — `IconGrid`/`ColorGrid`
take `symbols`/`colors` as props, so `reference` drives them.

**Defect — progress geometry is driven by the truncated integer, not the true fraction.**
`ProgressRingProps.percent` is documented as "server-supplied, already-truncated integer 0–100"
and `ui.css:223` is `width: calc(1% * var(--percent))`. That integer is correct for the *label*
(iOS truncates) but iOS draws the *arc* from the full `Double`
(`AccountEntry.emergencyProgress` → `0.04379629629629629`), not from `4`.

Pixel error, at `--app-width: 402px` (bar ≈ 354px, ring circumference ≈ 181px):

```
true  4.380% -> renders 4%   bar delta = 1.34px   ring = 0.69px
true  8.759% -> renders 8%   bar delta = 2.69px   ring = 1.79px   <- GROUND-TRUTH month 2
true  8.990% -> renders 8%   bar delta = 3.50px                   <- worst case
true 58.990% -> renders 58%  bar delta = 3.50px
```

**The month-2 emergency-fund case is already 2.69px and the worst case is 3.50px — both exceed
R9's ±2px grading tolerance.** So this would be graded as a layout failure while the real cause
is the wrong server field.

Fix costs nothing and adds no arithmetic: the API already ships the full double
(`emergencyProgress` / `progressBefore` / `progressAfter`). Take that for the geometry
(`pathLength={1}` with `strokeDasharray={`${progress} 1`}`, and `calc(100% * var(--progress))`
for the bar) and keep the truncated `progressDisplay` string for the label.

**Two content/behaviour deviations for `PARITY-GAPS.md`, not bugs:**
- iOS `ProgressRing` animates its label (`animatedProgress` + `contentTransition(.numericText())`),
  counting up on appear; the web renders a static string.
- iOS a11y label is `"\(Int(progress * 100)) percent complete"` (`ProgressRing.swift:46`);
  the web uses `aria-label={label}` = `"4%"`. Different string, and PARITY-SPEC quotes a11y labels.

**Note:** `Gallery.tsx:41-50` hardcodes the 10 category colours. It is route-gated
(`App.tsx:15` `isGalleryRoute()`), so it is a dev showcase, not production — but it is a third
copy of that palette alongside `tokens.css` `--cat-*` and `reference.categoryColors`. Nobody
should copy screen code from it.

## 2026-08-06 — Split display artefact: **CONFIRMED** (Critic)

`GROUND-TRUTH.md` carried this 🚧 unconfirmed (derived, not observed). Confirmed two ways —
source, then real Domain — so the 🚧 can be removed.

**1. The total card renders in Split mode.** `SavingsScreen.savingsPreview` (`:429-458`) is not
mode-gated; `calculatePreviewSavings()` (`:460-469`) branches and returns `splitTotal` for
`.split`. So "This month's savings" renders alongside the per-side rows at `:172` and `:218`.

**2. The numbers, from the shipped Domain + `AmountFormatter` on macOS:**

```
$ swift run probe3
Emergency 10%: raw 473     display 473 RON
Savings   15%: raw 709.5   display 710 RON      <- half-even, 710 is even
splitTotal   : raw 1182.5  display 1,182 RON

per-side displayed sum = 473 + 710 = 1183
total displayed        =            1,182
```

**The screen displays per-side amounts that sum to 1,183 next to a total of 1,182.** Each value
is rounded independently from the full decimal, so the visible arithmetic does not close. This is
shipped iOS behaviour and must be reproduced, not corrected.

Why it is the strongest vector on the project: split defaults are 10% + 15% = 25%, which
deliberately matches Priority, so **`1,182 RON` renders as the total in both modes** — a
total-only assertion passes a mode mix-up. And 473 + 709 would also sum to 1,182, so a
naive-rounding implementation matches the total while getting both sides wrong. Only asserting
`473` / `710` / `1,182` **together** catches it.

## 2026-08-06 — R20 verified applied; the **fourth leak** found (Critic)

**R20 landed correctly.** `primitives.tsx:263-288` now uses `pathLength={1}` with
`strokeDasharray={`${progress} 1`}`; `ui.css:224` is `calc(100% * var(--progress))`;
`aria-valuemax` was correctly moved from `100` to `1` alongside it, so the fix introduced no
a11y regression. `SliderProps.value` is now an R13 table index. No further action.

### The fourth leak: a `display` string reaching an input

Same family as R20 — a correct value used in the wrong place — but with a worse failure mode.
`Money` carries three forms of one quantity: `amount` (payload), `display` (labels), `editing`
(inputs). `AmountField.value` is documented "seed it from the server's `editing` string", but
`.display` and `.editing` are both `string` on the same object, one identifier apart.

Run against the real `parseUserInput` from `money.ts:305-312`:

```
$ node -e '...'
parseUserInput("1,182 RON")  = 1.182
parseUserInput("9,000 RON")  = 9.000     <- nine thousand becomes nine
parseUserInput("27,000 RON") = 27.000
parseUserInput("4,730 RON")  = 4.730
parseUserInput("1182.5")     = 1182.5    <- correct: this is `editing`
```

**A 1000× silent data loss.** No exception, no validation error, and the field still *looks*
right — under this machine's Romanian regional formats "9.000" reads as nine thousand to a human
reviewing the screen. The wrong value only surfaces after it is persisted.

**Defence — make it unrepresentable rather than documented.** `money.ts` already brands `Money`;
brand the other two the same way, so `AmountField.value: EditingString` rejects a display string
at compile time. This closes the whole family, not the one instance. Documentation will not hold
with two implementers sharing `src/ui/`.

### Confusable-pairs register — pre-registered, before the screens are written

Every row is one quantity with more than one server representation. Column 5 is the one that
matters: a trap invisible in the ground-truth data ships green and is found by a user.

| # | Quantity | Forms | Correct use | Leak symptom | Caught by GT data? |
|---|---|---|---|---|---|
| 1 | money | `amount` / `display` / `editing` | payload / label / input | `display`→input = 1000× loss | ❌ no |
| 2 | progress | `progress` / `progressPercent` / `progressDisplay` | geometry / — / label | R20, 3.50px | ✅ fixed |
| 3 | expense amount | `amount` / `monthlyAmount` / `annualAmount` | edit-only / toggle / toggle | annual expenses off by 12× | ❌ **no — all four seed expenses are monthly** |
| 4 | emergency target | capped / uncapped | both, for the strikethrough | strikethrough missing | ❌ no — GT has no hard cap |
| 5 | allocation order | Domain priority / server-sorted | allocations must NOT be re-sorted | emergency & savings swap | ⚠️ partly |
| 6 | `linkedAccountId: null` | null = **primary**, not "none" | use `linkedAccountName` | renders blank or "Unknown" | ✅ yes |
| 7 | destination label | "Keep in Primary" / "Primary Account" | per-screen | wrong string on one screen | ✅ yes |

Row 3 verified in source: `ExpenseItemRow.swift:31` renders
`displayFrequency == .monthly ? expense.monthlyAmount : expense.annualAmount` and
`ExpenseCategoryCard.swift:34` does the same with group totals — **the raw `amount` is never
displayed anywhere**. It exists only to seed the edit field. Rendering `expense.amount` is
correct for all four seed expenses and wrong for every annual one.

## 2026-08-06 — R24 enforcement **proven at compile time** (Critic)

Asked to verify rather than take the report. Wrote a probe inside the project's own tsconfig
(so the real compiler options apply) and ran `tsc --noEmit`:

```tsx
<AmountField value={displayString('1,182 RON')} .../>   // expect error
<AmountField value={'1182.5'} .../>                     // expect error
<AmountField value={editingString('1182.5')} .../>      // expect OK
```
```
probe.tsx(5,33): error TS2322: Type 'DisplayString' is not assignable to type 'EditingString'.
probe.tsx(7,33): error TS2322: Type 'string' is not assignable to type 'EditingString'.
                                                        // line 9 produced no error
```

**R24 is a real control, not a doc comment.** It also rejects a bare `string`, which closes the
`amountText: string` seam in `features/onboarding/types.ts` — a display string cannot reach an
input even by way of an implementer's own draft type.

Confirmed the control is actually enforced in the pipeline: `package.json` has
`"build": "tsc --noEmit && vite build"`, so a violation breaks the build rather than only an
editor squiggle.

*Process note:* the same run surfaced three real type errors (`Gallery.tsx:181/188/195` passing
raw strings to `AmountField`, and an `AccountExpenseTransferExt` extension conflict). By the time
I re-ran, all three were fixed. **Reported as transient-and-resolved rather than as findings** —
the tree is green as of this entry. Racing a live implementer means a red typecheck is a
snapshot, not a fact.

## 2026-08-06 — Register row 5 (allocation order) resolved: **split verdict** (Critic)

Row 5 was the only ⚠️. It decomposes into three questions with different answers.

**Safe — the allocation array order.** `TransferCalculator.distributeToAccounts` appends
emergency then savings unconditionally; `distributeSplitToAccounts` likewise. Deterministic in
both modes. The server preserves it (API-CONTRACT §2.6: "keeps Domain's priority order — not
sorted"). No action.

**Unspecifiable — account list order.** iOS declares `@Query private var accounts: [Account]`
(`MainTabView.swift:13`) with **no sort descriptor**, so Dashboard account cards render in
unspecified store order. The server sorts (`StateAssembler.swift:52`,
`(sortOrder, createdAt)`).

iOS is also inconsistent with *itself*: `SettingsSheet.swift:349` sorts the very same accounts
`by: { $0.sortOrder < $1.sortOrder }`, while the Dashboard does not. So Settings matches the
server and the Dashboard may not.

**Latent iOS bug — allocation target selection.** `accounts.first(where: { $0.isPrimarySavings })`
runs over that unsorted array, and `isPrimarySavings` is **not enforced unique**:
`SettingsSheet.swift:605` sets it per-account without clearing the flag on others (unlike
`isPrimary`, which the API does clear). With two accounts flagged, iOS picks nondeterministically
between launches; the server deterministically picks the lowest `sortOrder`.

Actions:
1. Golden vectors must **not** contain two `isPrimarySavings` accounts — iOS has no defined
   answer, so any assertion would encode one arbitrary run.
2. Screenshot grading of the Dashboard account section needs one account per type, or it flakes
   on iOS's ordering, not on ours.
3. `PARITY-GAPS.md`: the web is *deliberately more deterministic than iOS* here. That is a
   documented divergence, not a defect — and the iOS Dashboard/Settings inconsistency is worth
   recording as an upstream bug.

## 2026-08-06 — Expenses tab: row 3 clean; **register row 9** — the two implementers diverged (Critic)

**R25 row 3 — handled correctly.** `ExpensesScreen.tsx:251` is
`frequency === 'monthly' ? expense.monthlyAmount : expense.annualAmount`, group totals at `:180`
likewise, and the header block documents the quirk. `expense.amount` is never rendered. The
pre-warning landed.

### Row 9 — server enum `displayName` rendered without translation

Same family as rows 1–3: a correct value used in the wrong place. Server enum `displayName`s are
**always English by design** — API-CONTRACT §2.7 states `Bundle.module` falls back to the key on
macOS, so "RO must come from the client's i18n dictionary, keyed by the English string."

**Frontend2 built the right tool and uses it.** `tDomain` (a `TFunction`, threaded through
`screens/shared.ts:17`) wraps every server enum label: `AddAccountSheet.tsx:91`,
`AccountRow.tsx:82`, `RemainingMoneyPicker.tsx:73`, `SavingsScreen.tsx:71,109,117`.

**Frontend did not adopt it.** `ExpensesScreen.tsx:78` and `:100` render `f.displayName` raw. The
screen *does* use `t()` for its own literals (`:285`, `:286`, `:289`), so this is specifically the
server-supplied labels that were missed.

The translations already exist — nothing is missing but the call:

```
'Monthly' -> Lunar        'Priority'        -> Prioritizat
'Annual'  -> Anual        'Split'           -> Separat
'Primary' -> Principal    'Keep in Primary' -> Păstrează în Principal
```

**Symptom:** in Romanian the Expenses tab's Monthly|Annual segmented control and its total header
render **English**, while every onboarding screen renders Romanian. Invisible in EN — which is
what gets tested.

**The header needs a precise fix, not a blanket `t()`.** iOS is
`Text("Total \(selectedFrequencyView.displayName) Expenses".localized)`
(`ExpenseListView.swift:91`). `Frequency.displayName` **is** `.localized` (`Frequency.swift:31-37`),
but the assembled string is then used as a lookup key that does not exist, so it falls back to
itself. In RO iOS therefore renders the mixed string **"Total Lunar Expenses"** — inner word
translated, wrapper English. So the web wants:

```tsx
`Total ${tDomain(f.displayName)} Expenses`   // wrapper stays English — reproduces the iOS bug
```

Frontend's comment at `:85` shows the interpolated-key quirk was understood; only the inner
translation was missed.

**Checked and NOT a finding:** `IncomeScreen.tsx:56` wraps `Currency.displayName` in `tDomain`.
iOS `Currency.displayName` (`Currency.swift:18-24`) is a raw literal with **no** `.localized`, so
it stays English on iOS too, and `ro.json` correctly has no key for it — `tDomain` falls through
to the English key. Correct parity. Verified against iOS before flagging.

## 2026-08-06 — Dashboard pass: the `-0` hazard **dissolves**; row 4 is live (Critic)

### The `-0` vs `0` conflict is not a conflict — different mechanisms

Traced the minus sign, which I had left untraced since my first API review.
`SummaryCard.swift:97`:

```swift
let prefix = style == .negative && amount > 0 ? "-" : ""
```

The minus is a **view-level string prefix gated on `amount > 0`**, and the value passed is
`expenses` — always a non-negative Decimal. The formatter never produces the sign on this path.

So the two rulings live on structurally different code:

| | Mechanism | Where |
|---|---|---|
| R28a — render `0` | string concatenation, gated `amount > 0` | `SummaryCard.swift:97` |
| R24 — render `-0` | `NumberFormatter` on a Decimal in `(-0.5, 0)` | `AmountFormatter.formatForDisplay` |

**They cannot be unified by a refactor** — one is a prefix on a non-negative value, the other is
formatter output for a negative one. A well-meaning merge would have to fuse a concatenation site
with a number-formatting site. The hazard is real in appearance, absent in code.

⚠️ **But the fix for R28a must key off the amount, not the display string.** Implemented as
"suppress the minus when `display === '0'`", it would also swallow the legitimate `-0` of R24 if a
negative value ever reached that component. Mirror iOS: gate on `amount > 0`.

### Confirmed (Analyst's find) — with its precise cause

`DashboardScreen.tsx:74` is `value={`-${expenses.display}`}` — **unconditional**. iOS gates on
`amount > 0`. With `totalExpenses = 0` (reachable via "Skip for now") the web renders `-0 RON`
where iOS renders `0 RON`. Not re-reporting; recording the one-line cause and the correct fix.

### NEW — register row 4 lands on the Dashboard: `targetCaption` has no hard-cap variant

iOS `EmergencyProgressCard.swift:73-82` builds **two** captions:

```swift
"Target: \(multiplierInt)× monthly income (capped at \(capFormatted))"   // hard cap set
"Target: \(multiplierInt)× monthly income"                              // no cap
```

The server emits only the second — `StateAssembler.swift:361`:

```swift
targetCaption: multiplier.map { "Target: \(formatMultiplier($0))× monthly income" } ?? "Target",
```

**With a hard cap set, the Dashboard silently drops `(capped at X)`.** `emergencyHardCap` is
plumbed all the way through (`DashboardView.swift:88` passes it to the card) and is a real,
settable field in `AccountEditorSheet` — so this is reachable, not theoretical. Invisible in the
ground-truth fixture, which has no hard cap. **This is register row 4 arriving exactly where the
register predicted, and it is why R25a asked for a hard-capped fixture.**

Minor, same site: the `?? "Target"` fallback is a string iOS never renders — the card is gated on
a target existing (`DashboardView.swift:80-82`) and the multiplier defaults to `3.0` (`:87`).
Unreachable if the gate is right; worth deleting rather than carrying a phantom string.

### Verified clean — checked and NOT findings

- **Account ordering.** `DashboardScreen.tsx` does not re-sort; served order is rendered, with
  explicit "Do not re-sort" comments at `:245`. Matches R27.
- **Emergency excluded from Account Balances.** `:178` filters `accountType !== 'emergency'`;
  iOS does the same inside the component — `AccountBalancesRow.swift:16-19`,
  `!account.isPrimary && account.accountType != .emergency`. Verified before flagging.
- **R20 geometry.** `progress={fund.progress}` (full double) for the ring, `fund.progressDisplay`
  for the label. Correct.
- **a11y.** `t('%lld percent complete', [fund.progressPercent])` — truncated integer, matching
  `ProgressRing.swift:46`.
- **Row 4 on the card's target *amount*** is correct: iOS shows the **capped** effective target
  (`viewModel.emergencyTarget`), which is what the API's `target` field is. Only the caption is wrong.

Rows 6, 7 and 8 are not Dashboard surfaces — they belong to Expenses, Settings and the transfer
plan respectively.

## 2026-08-06 — Conditional-string sweep: the pattern is narrower than hypothesised (Critic)

Asked to hunt for "strings assembled conditionally in iOS but flattened server-side". Swept every
non-test View in `Packages/Features`, `SharedUI` and `Diameris/` for interpolated `.localized`
strings, ternary string production and `if/else` string branches. **The hypothesis needs
narrowing, and the narrowed form is more useful.**

### Not a general failure — the hardest case was ported correctly

`SavingsScreen.swift:365-404` is the most conditional string site in the app: **four** mutually
exclusive strings for split mode (percentage vs fixed × emergency vs savings), each item gated on
`hasEmergencyAccount`/`hasPrimarySavingsAccount`, and step numbering as
`hasEmergencyAccount ? "2" : "1"`.

`SavingsScreen.tsx:311-345` (`flowItems`) is a faithful port of **both** branches with identical
gating, and `:276`'s `index + 1` is equivalent to iOS's conditional numbering given the same
filtering. **Verified clean.** Frontend2 handled it by porting the branch logic client-side, using
data the client already has.

### The real pattern: **server-assembled sentence fields**, not conditional strings generally

The failure occurs only where iOS's conditional was **collapsed into a single string at assembly
time**, so the branch no longer exists to be ported. I enumerated every such field in
`ResponseDTOs.swift` (~12: `targetCaption`, `subtitleParts`, `progressChangeDisplay`,
`enabledCaption`, `wasLastMonthDisplay`, `accountTypeDescription`, `percentDisplay`, `summary`, …)
and checked each against its iOS source. **Two are broken.**

**1. `targetCaption`** — already logged; missing the `(capped at X)` variant.

**2. The completion strings — not served at all, and the two screens disagree.**

Same condition, `allocation.isComplete`, renders differently in two places:

| Screen | Source | String | Structure |
|---|---|---|---|
| New Month | `TransferPlanStep.swift:188-192` | `"Completes fund to 100%!"` | **replaces** `progressChangeDisplay` |
| Onboarding | `TransferPlanScreen.swift:375-386` | `"Target reached!"` | **appends** a green ✓ row *below* `progressDisplay` |

Neither string is served. Both are already in `en.json`/`ro.json` (extracted, unrendered).

The trap is sharper than a missing field: a client that implements "if `isComplete`, show the
completion string" **uniformly** is wrong on one of the two screens — different wording *and*
different structure (replace vs append). `isComplete` is served, so the client can branch; it must
just branch differently per screen. New Month is task #7 (unbuilt) and the onboarding summary
screen exists, so this is a pre-warning for both rather than a live defect.

### Narrowed lens for future work

Not "iOS builds a string in a branch" — that's handled when the branch is client-side. It is:
**every server field that is a pre-assembled sentence is a place where an iOS conditional may have
been flattened.** ~12 fields, 2 broken. That is a finite, auditable list rather than an open hunt.

## 2026-08-06 — Localization: my "Total Lunar Expenses" was wrong; corrected mechanism (Critic)

Retracted. The Analyst's correction is right, and I verified it rather than accepting it:
`Monthly`/`Annual` exist in exactly **one** catalog (Expenses, 55 keys) and are **absent** from
Domain (29), Dashboard (41), Onboarding (169) and app (59).

I then over-corrected and nearly shipped a second wrong finding — a sweep claiming **20 dead
interpolated lookups**. That was also wrong, and the reason is worth recording.

### The two call forms are not equivalent — proven

```
$ swift lv.swift
Form A  String(localized: "Nice to meet you, \(name)!")
        -> key: "Nice to meet you, %@!"   arguments: ["Vlad"]     RESOLVES
Form B  "Nice to meet you, \(name)!".localized
        -> key: "Nice to meet you, Vlad!" arguments: []           DEAD
```

`String.LocalizationValue` captures interpolation as `%@` **only from a literal**. The `.localized`
computed property receives an already-interpolated runtime `String`, so the key carries the
substituted value. `String.localized(_ key: LocalizationValue)` takes a *LocalizationValue*
parameter, so it is Form A and **resolves** — the four `String.localized("Transfer to \(name)")`
sites are fine.

### Result: exactly ONE dead lookup in the codebase

`ExpenseListView.swift:91` — `Text("Total \(...displayName) Expenses".localized)`. My original
catch, and it is the only one.

So iOS renders **"Total Monthly Expenses"** — fully English — for **two independent reasons**:
1. the wrapper is a Form-B dead lookup, falling back to its interpolated key; and
2. the inner word was already English, because `Frequency.displayName` is Domain code binding
   Domain's bundle, which lacks `Monthly`.

Both are required for the answer. I had (1) and missed (2).

### Live trap: `ro.json` ships translations iOS can never render

```
'Total %@ Expenses'  -> 'Cheltuieli %@ totale'    <- iOS: dead lookup, renders English
'Monthly'            -> 'Lunar'                   <- see below
```
Rendering the first via `t()` produces Romanian where iOS shows English — an R26a violation.

### The bundle-split defect, with a same-screen consequence

The word `Annual` is looked up from **two modules**:

| Site | Module | Bundle has key? | Renders in RO |
|---|---|---|---|
| `ExpenseItemRow.swift:60` `"Annual".localized` | Expenses | ✅ `Anual` | **"Anual"** |
| `Frequency.swift:35-36` `"Annual".localized` | Domain | ❌ absent | **"Annual"** |

**On the Expenses tab in Romanian, the same word renders both ways at once** — an annual expense
row shows the caption `(Anual)` while the segmented control above it shows `Annual`. That is the
`.localized`-names-a-lookup-not-a-result class the Analyst identified, and it is observable on one
screen. The web must reproduce both.

**Method note for this class:** a `.localized` call site tells you nothing on its own. Three things
must agree — the call **form** (A resolves, B is dead), the **bundle** the call binds, and whether
that bundle's catalog holds the key. I checked one of the three and was wrong twice.

## 2026-08-06 — Negative-space register: Settings + New Month (Critic)

Closed-set method applied to "states whose correct output is nothing". Verified in source, plus a
Domain probe for the plan-shape cases.

### ⚠️ CORRECTION — "no emergency row when the fund is full" is **inverted**

The premise in my brief was that a full emergency fund produces no row. **It produces a row.**

```
$ swift run probe3
EF FULL (27000): allocations=2
   type=emergency amount=0        target=27000  isComplete=true   note="100% → 100%"
   type=savings   amount=1182.5   target=nil    isComplete=false  note=nil
```

And `TransferPlanStep.swift:129` is `ForEach(transferPlan.accountAllocations)` — **unfiltered**. So
iOS renders **"Emergency Fund  +0 RON"** with the completion note attached.

**The dangerous seam:** the section *gate* and the row *loop* use different predicates.

```swift
hasAccountAllocations = !accountAllocations.isEmpty && accountAllocations.contains { $0.amount > 0 }  // gate
ForEach(transferPlan.accountAllocations) { … }                                                        // loop: no filter
```

An implementer who assumes "the gate filters positives, so the loop shows positives" drops a row
iOS displays. Telling Frontend to "hide the emergency row when full" would **create** the defect.

Web `SummaryScreen.tsx:65` maps `plan.accountAllocations` unfiltered — **correct**, matches iOS.

### Verified true negative space — nothing renders

| # | Site | Condition | Correct output |
|---|---|---|---|
| N1 | `TransferPlanStep.swift:336` | `if isBalanced` — **no `else`** | `!isBalanced` → **no banner at all**, no warning |
| N2 | `TransferPlanStep.swift:168` | `if let note = transferNote` | savings rows, and emergency without a multiplier → **no note line** (probe: both `nil`) |
| N3 | `TransferPlanStep.swift:137` | `if remainingMoney > 0` | zero → **no remaining-money row** |
| N4 | `TransferPlanStep.swift:124` | `if hasTransfers` | no positive allocation **and** no expense transfers **and** `remainingMoney == 0` → **whole card absent** |
| N5 | `SettingsSheet.swift:385` | `if let multiplier` | no multiplier → **no "3× income" subtitle part** |
| N6 | `SettingsSheet.swift:379` | `if account.isPrimarySavings` | false → **no "Primary" badge part** |
| N7 | `SettingsSheet.swift:323` | `if hasEmergency \|\| hasSavings` | neither → **whole distribution section absent** |

N1 is the sharpest: an unbalanced plan shows **no** validation feedback — not a warning, not a
red state, nothing. The natural implementation adds an error banner, which is an R26a violation.

### Verified NOT a defect — do not "fix"

`SettingsSheet.swift:341` gates the "Total exceeds available income" footer on
`allocationMode == .split`. That is **correct**: prioritized mode cannot over-allocate, because
`SavingsAllocationEntry.calculateSavings` returns `min(fixedAmount, max(0, availableIncome))` for
fixed amounts and is capped at 50% for percentages. The warning is split-only because
over-allocation is only *reachable* in split. Making it universal would add a state iOS never shows.

## 2026-08-06 — Mode-dependence confirmed; the gate/loop seam is **reachable** (Critic)

Verified `main`'s mode-dependent resolution, then extended it across the register.

```
PRIORITIZED, EF at target       rows=2  [emergency/0/complete=true/note="100% → 100%", savings/1182.5]
SPLIT,       EF at target       rows=1  [savings/1182.5]                       <- no emergency row
PRIORITIZED, EF at target, no savings acct
                                rows=1  [emergency/0/complete=true]  hasAccountAllocations=FALSE  remaining=4730
SPLIT,       EF at target, no savings acct
                                rows=0  []                            hasAccountAllocations=false  remaining=4730
```

Mode-dependence **confirmed**: prioritized appends the completed emergency allocation
(`amount > 0 || targetAmount != nil`), split does not (`remaining <= 0` → overflow, nothing
appended). Neither is the universal rule.

### The gate/loop seam is not theoretical — it is reachable

Row 3 above: **prioritized + EF at target + no savings account.**

- `hasAccountAllocations = false` — the gate says there is nothing worth showing
- `remainingMoney = 4730 > 0` — so `hasTransfers` is **true** and the card renders anyway
- `ForEach` is unfiltered — so the **"Emergency Fund +0 RON"** row renders

**A real state exists in which the gate and the loop disagree.** Anyone who filters the loop to
match the gate loses that row. This is why the rule must be *never filter the row loop* rather
than any statement about when rows appear.

### N4 is reachable — and it is a different state from the `-0` bug

```
income == expenses (9000/9000): avail=0     hasTransfers=FALSE  -> whole "Transfers to make" card ABSENT
income == 0:                    avail=0     hasTransfers=FALSE  -> card ABSENT
skip-all expenses (0 expenses): avail=9000  hasTransfers=true   -> card renders
```

Note `accountAllocations` still contains **one** entry when the card is absent — so an
implementer who renders the card on `accountAllocations.length > 0` shows a card iOS hides. The
gate is `hasTransfers`, not array length.

I had guessed N4 co-occurred with the `-0` trigger. **It does not** — `-0` needs
`totalExpenses == 0` (skip-all), where `hasTransfers` is *true*; N4 needs `availableIncome == 0`,
where expenses are typically non-zero. Two distinct narrow states, both needing their own vector.

### Generalisation for rows 7/8

**Allocation mode is an independent axis over the whole negative-space register.** Every N-entry
verified under one mode may invert under the other, exactly as the emergency row did. Vectors for
Settings and New Month should cover prioritized **and** split for any assertion about a row's
presence or absence.

## 2026-08-06 — N1–N4 pre-verified across mode × account-set (Critic)

Ran the full matrix — 2 modes × 8 account/income configurations — before either implementer
reads the assertions.

### N1: the trigger is **expenses > income**, and nothing else

`!isBalanced` did not fire in any of the 16 matrix cells. Derived why from
`TransferCalculator.swift:70-71`:

```
total = remainsInPrimary + expenseTransfers + allocations + remainingMoney
      = totalExpenses + allocatedSavings + (availableIncome - allocatedSavings)
      = totalExpenses + availableIncome
availableIncome = max(0, income - totalExpenses)      <- the clamp is the whole story
```

If `income >= totalExpenses`, `total == income` — **always balanced**. Only the `max(0, …)` clamp
can break it. Predicted `totalExpenses > income`, then tested:

```
income=9000 exp=4270  avail=4730  isBalanced=true   banner SHOWN
income=9000 exp=9000  avail=0     isBalanced=true   banner SHOWN     <- boundary
income=9000 exp=9001  avail=0     isBalanced=false  banner ABSENT    <- one unit later
income=9000 exp=12000 avail=0     isBalanced=false  banner ABSENT
income=0    exp=500   avail=0     isBalanced=false  banner ABSENT
```

**`isBalanced == false` iff `totalExpenses > income`.** Mode-independent, account-set-independent.

### The state worth writing a vector for

At `expenses > income`, **N1 and N4 fire together**: no validation banner *and* no
"Transfers to make" card. New Month step 3 renders the summary and then **nothing else** — no
transfers, no warning, no error. This is the single most inviting place on the flow for an
implementer to add "Your expenses exceed your income", and iOS shows nothing.

`exp == income` vs `exp == income + 1` are **adjacent states with different output**
(banner shown + card absent, vs banner absent + card absent). That pair is a precise regression
vector: it cannot pass by accident and it pins the clamp boundary.

### Matrix results — mode **does** change N2, not N1/N3/N4

| Config | prioritized | split |
|---|---|---|
| EF+SAV, EF empty | rows=1, noteNil=0 | rows=2, **noteNil=1** |
| EF+SAV, EF full | rows=2, noteNil=1 | rows=1, noteNil=1 |
| EF only, EF full | **rows=1** (`+0 RON` row) | **rows=0** |
| SAV only | rows=1, noteNil=1 | rows=1, noteNil=1 |
| primary only | rows=0 | rows=0 |
| avail==0 | N3 **and** N4 fire | N3 **and** N4 fire |

- **N1** — mode- and account-independent; only `expenses > income`.
- **N2** (no note line) — **mode-dependent**: `EF+SAV, EF empty` has no nil-note row under
  prioritized but one under split, because split allocates to savings (note always nil) while
  prioritized sends everything to emergency.
- **N3 / N4** — driven by `availableIncome == 0`, mode-independent.
- **Emergency row presence** — mode-dependent, as established.

### N5–N7 are not plan-shaped

`SettingsSheet` N5 (`if let multiplier`), N6 (`if isPrimarySavings`) and N7
(`if hasEmergency || hasSavings`) read account **properties**, never the `TransferPlan`. They are
mode-independent by construction — no probe needed, and no fixture should imply otherwise.

## 2026-08-06 — `interpolate()` verified; RO "Step" gap is **correct parity** (Critic)

### `interpolate()` — tested, not read

```
"Step %1$lld of %2$lld" [1,3]  -> "Step 1 of 3"      positional
"Step %lld of %lld"     [1,3]  -> "Step 1 of 3"      sequential
"%2$lld before %1$lld"  [7,9]  -> "9 before 7"       reordered
"100%% done, %lld left" [2]    -> "100% done, 2 left" escape
"Step %1$lld of %2$lld" [1]    -> "Step 1 of %2$lld"  missing arg -> verbatim (documented)
```

Correct on every form. The positional fix landed.

### ⚠️ Nearly reported a defect — RO missing `Step %lld of %lld` is **correct**

`ro.json` has no `Step %lld of %lld`, `en.json` does. That looks like an English-leakage bug.
It is not. The iOS Dashboard catalog contains **two** keys:

```
'Step %d of %d'      -> ro = 'Pasul %d din %d'    <- translated
'Step %lld of %lld'  -> ro = None                 <- NOT translated
```

Which one does iOS look up? Proven rather than assumed:

```
$ swift step.swift
Int interpolation key: %lld      ("Step %lld of %lld")
```

Swift renders an interpolated `Int` as `%lld`, so the runtime key is `Step %lld of %lld`, which
has **no RO value** → iOS falls back to English and renders **"Step 1 of 3"** in Romanian.
`'Step %d of %d' -> 'Pasul %d din %d'` is an **orphan the runtime can never reach** — the exact
class flagged after `Total %@ Expenses`.

**So the web's missing RO key reproduces iOS.** Adding `Pasul %d din %d` would be an R26a
violation. Third time the call-form + bundle + catalog rule has prevented a wrong finding.

Also confirmed: `'Target: %lld× monthly income (capped at %@)'` is now in both catalogs, positional
in EN and RO — the row-4 hard-cap caption fix has landed.

### NewMonthSheet — all four traps handled correctly

| Trap | Site | Status |
|---|---|---|
| N1 no-banner | `:410` `{plan.isBalanced && …}`, no `else` | ✅ cites `isBalanced == false ⟺ totalExpenses > income` |
| N4 gate | `:306,346` `hasTransfers`, never `.length > 0` | ✅ |
| N3 | `:378` `{!plan.remainingMoney.isZero && …}` | ✅ |
| row-loop seam | `:355` `accountAllocations.map` unfiltered | ✅ |
| row 8 collapse | `:357` `key={index}`, not `accountId` | ✅ |
| second `-0` | `:329` gated on `plan.totalExpenses.isZero` | ✅ |

`isZero` is a **server-supplied boolean** (`api.ts:84`), so the gate needs no client arithmetic —
R2-clean.

**Micro-divergence, verified not a defect:** iOS gates on `amount > 0`, the web on `!isZero`.
These differ for negative amounts (iOS suppresses the prefix, the web would emit a double minus).
`totalExpenses` is a sum of amounts validated `> 0`, so it cannot be negative. Unreachable.

**Transient:** `tsc` red in `features/expenses/modals/AddExpenseSheet.tsx` — missing sibling
modules, and the errors *changed between two runs* (`./categoryOrder` → `./AddCategorySheet`).
Frontend2's in-flight work, not a finding.

## 2026-08-06 — Settings pre-warning: enum matrix + row 7 resolved (Critic)

Settings is unwritten and renders more enums than any other screen, so this is pre-registration.

### The six-enum matrix — every key checked against the bundle its call site binds

All five Domain enums use `"…".localized`, which binds **Domain's** catalog (29 keys).
`Currency.displayName` (`Currency.swift:18-24`) has **no `.localized` at all**.

| Enum | Bundle | Keys present? | iOS renders | Client |
|---|---|---|---|---|
| `AccountType` | Domain | ✅ all 6 | **Romanian** | `tDomain` |
| `AllocationMode` (+`description`) | Domain | ✅ all 4 | **Romanian** | `tDomain` |
| `SavingsInputMode` | Domain | ✅ both | **Romanian** | `tDomain` |
| `RemainingMoneyDestination` (+`description`) | Domain | ✅ all 4 | **Romanian** | `tDomain` |
| `Frequency` | Domain | ❌ `Monthly`/`Annual` **absent** | **English** | render raw |
| `Currency` | — (no lookup) | n/a | **English** | render raw |

Confirms 4-of-6 with per-key evidence, e.g. `Primary→Principal`, `Joint→Comun`, `Other→Altul`,
`Priority→Prioritizat`, `Fixed Amount→Sumă fixă`.

**Screen-specific:** Settings renders no `Frequency` control (that is the Expenses tab), so on
**Settings only, `Currency` is the single enum that must stay English** — 4 translate, 1 raw.

### Row 7 resolved — the mechanism is **shadowing**, and only one case differs

PARITY-SPEC §10 #11 says "`SettingsSheet` privately relabels it". The mechanism matters:
`SettingsSheet.swift:698-706` declares a **`private extension RemainingMoneyDestination { var displayName }`**
which *shadows* Domain's for every call site in that file. So `:403`'s
`Text(destination.displayName)` silently resolves to the private one.

I first read `:403` as using Domain's value and nearly filed row 7 as a false alarm. The shadow is
invisible at the call site — the line is character-identical to the onboarding one.

| case | Settings (app bundle) | Onboarding (Domain bundle) |
|---|---|---|
| `.primarySavings` | Primary Savings / `Economii principale` | Primary Savings / `Economii principale` |
| `.personal` | Personal Account / `Cont personal` | Personal Account / `Cont personal` |
| `.primary` | **Primary Account** / `Cont principal` | **Keep in Primary** / `Păstrează în Principal` |

**Only `.primary` differs, and both sides translate** — so this is not an English-leakage case, it
is two different labels for one enum case on two screens. The web needs a Settings-scoped override
for `.primary` and must not "unify" the two, in either language.

Note the app catalog carries all three keys, so the shadow does not introduce a bundle gap — the
divergence is purely the different English string for `.primary`.
