# Diameris — parity verification harness

Owned by **Reviewer** (`Web/Docs/TEAM.md`). Nobody else edits `Web/Verify/`.

This harness answers one question: **does the web client actually behave like the iOS app?**
It drives the real UI in a real browser and asserts on **rendered text**, because that is
what "1:1" means. It never inspects React state, never imports client code, and never
recomputes a number itself.

The six suites map to the parity axes in `Web/Docs/DECISIONS.md` §D6:

| Suite | Axis | What it does |
|---|---|---|
| `parity/numbers.spec.ts` | 1 — Numeric | Encodes every row of the "Verified numbers" table in `GROUND-TRUTH.md` as an assertion on rendered text, after driving the canonical onboarding (Vlad / 9000 / 1200+2500+450+120 / 25 % Priority+Percentage / Main + Emergency Fund + Savings) and then the New Month flow. |
| `parity/content.spec.ts` | 2 — Content | One `test.describe` per screen; asserts every user-visible string `GROUND-TRUTH.md` lists is present. Soft assertions, so a run reports *all* missing strings on a screen, not just the first. |
| `parity/golden.spec.ts` | 1 — Numeric | Asserts `Web/Docs/golden-vectors.json` (R8/R11). Layer 1 seeds each scenario through the API and checks the server's raw decimals, percents and flags; layer 2 re-checks the same expected display strings as **rendered text**, so a correct server with a wrong UI cannot pass. |
| `parity/behaviour.spec.ts` | 3 — Behavioural | Navigation, defaults and enable/disable rules. Headline case: the two "Skip for now" buttons look identical and do different things (expenses skip persists no rows → savings 2,250; savings skip keeps the 25% defaults → 1,182). |
| `parity/locale.spec.ts` | 2 — Content (RO) | Romanian catalogue integrity **and** rendered Romanian. Added after every other suite was found to assert English only — an entire language could have been wrong while the board stayed green. Hunts silent namespace fallbacks, which look correct to an English reader. |
| `parity/screens.spec.ts` | 4 — Visual | Captures every screen in light **and** dark, at **402×874** (the graded parity column, R9) and 1280×900 (informational), to `output/`. Writes `output/REPORT.md` for human side-by-side judgement. |

## Prerequisites

1. **The app must be served on `http://localhost:8080`** — that is `./Web/run.sh`
   (`DECISIONS.md` §D5; the script does not exist yet at the time of writing).
   Point elsewhere with `DIAMERIS_URL=http://localhost:5173`.
2. The server must expose **`POST /api/reset`** (`DECISIONS.md` §D4). Every test resets the
   store through it so runs are independent and order-free. Without it the harness cannot run.
   It must also honour **`X-Diameris-Now`** (R17) so the Dashboard month title is deterministic.
3. **The API-propagation gate should be at 0.** `globalSetup` runs
   `python3 Web/Docs/api-propagation-check.py` before any suite and prints the outstanding
   count. It is a **warning** by default — Frontend still gets UI signal while the API catches
   up — and **fatal** with `PARITY_STRICT_API=1`, which is the CI setting, because per main
   "exit 0 is the definition of done for the API".

   This matters more than it sounds: several suites fail against an incomplete API for reasons
   that look exactly like UI bugs. The banner exists so nobody debugs the wrong layer. If a
   parity run is red and the gate is non-zero, **fix the gate first and re-run** before filing
   anything against the client.
4. `npm install` here, and `npx playwright install chromium` once (already done on this machine).

If the server is not up, the run fails once, in `globalSetup`, with a single readable message
instead of dozens of connection-refused stacks.

## Running

```bash
cd Web/Verify
npm install                # first time only
npx playwright install chromium   # first time only

npm run parity             # all six suites
npm run parity:numbers     # numeric parity only — the fastest useful signal
npm run parity:content     # content parity only
npm run parity:golden      # golden-vector scenarios (server + rendered UI)
npm run parity:behaviour   # navigation, defaults, skip semantics
npm run parity:locale      # Romanian rendering
npm run parity:catalogues  # OFFLINE — en/ro catalogue integrity, no server needed
npm run parity:screens     # visual capture + regenerate output/REPORT.md
npm run parity:fixture     # OFFLINE — self-consistency of golden-vectors.json, no server needed
npm run typecheck          # tsc --noEmit
npm run show-report        # open the HTML report from the last run
```

`parity:fixture` is the one thing that already passes today: it re-derives every percent
vector by truncation, checks the half-even table covers both directions, checks the
`isBalanced` table brackets `0.01` from both sides, checks the four scenarios R11 makes
mandatory are present **and** binding, and checks no expected value is an inequality.
It catches arithmetic mistakes in the fixture itself before anyone builds against it.

Runs are **serial** (`workers: 1`): there is one local JSON store (`DECISIONS.md` §D2) and
every test mutates it.

## Output

```
output/
  <screen>-<theme>-<viewport>.png   captures, e.g. dashboard-dark-1280x900.png
  REPORT.md                         side-by-side table, verdict filled in by a human
  html-report/                      Playwright HTML report
  results.json                      machine-readable results
  .playwright/                      traces/screenshots for failed tests
```

## Golden vectors

`Web/Docs/golden-vectors.json` (Reviewer owns) is the executable definition of numeric
correctness required by `DECISIONS.md` R8 and R11. Backend asserts it from Swift; this
harness asserts the same file from the browser. Two statuses:

- `binding` — verified against the live iOS app, or a mechanical consequence of a verified
  rule, or mandated by a binding resolution (R10). Asserted.
- `needs-confirmation` — the scenario shape is right but the expected values are **not**
  verified. **Not asserted**, reported as skipped with the open question that blocks it.
  A guess must never harden into the definition of correct just because it was written down.

Every `needs-confirmation` scenario must be referenced by an entry in `openQuestions`, and
the fixture-integrity test fails if one is not.

### Why there is no pixel diff

`toHaveScreenshot()` baselines are deliberately **not** used. The reference images in
`Web/Docs/reference-screens/` are iOS simulator screenshots at a different scale, aspect
ratio and device metrics; a pixel diff against a browser render would be pure noise and
would create a false sense of rigour. Instead `output/REPORT.md` pairs each reference with
each capture and leaves a **verdict** column that a reviewer fills in after actually opening
both images and judging layout, hierarchy, colour semantics and spacing rhythm. Verdicts
already recorded survive a re-run (they are keyed by `screen|theme|viewport`).

## The test-id contract

The suites need stable hooks for numbers and controls. `parity/testids.ts` is the contract:
**Frontend must render `data-testid` attributes matching those exact strings.** Text that a
user reads (and that `GROUND-TRUTH.md` pins down) is queried by text/role instead, because
asserting on the string *is* the parity check.

If an id in that file is wrong for the implementation, message Reviewer — do not rename it
locally. The file is the shared vocabulary between the harness and the client.

## Expected state today

**Every test fails right now, and that is correct.** The harness was written before the
client exists, so that the moment Frontend and Backend land there is an immediate, honest
verdict rather than a hand-wave. Failures are worded to be actionable: each one names the
GROUND-TRUTH row or screen it came from.

Anything that turns out not to be reproducible 1:1 goes in `Web/Docs/PARITY-GAPS.md`
with a reason (`TEAM.md` rule 8). Nothing is dropped silently.
