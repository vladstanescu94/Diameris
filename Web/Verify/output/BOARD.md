# Verification board — 2026-08-06

> **REVISED after main's review.** Two of my six root causes were **contract bugs, not client
> bugs** — see "Withdrawn" below. Fixing one of them converted 17 tests and unblocked every
> screen past Savings. Original numbers kept beneath for the audit trail.

## Revised totals (after the `aria-selected` fix)

| | Before | After |
|---|---|---|
| Passed | 53 | **70** |
| Failed | 62 | **45** |
| Contract ids observed live | 23 | **88** |
| Unreachable surfaces | 6 | **0** |

## Withdrawn — my bugs, not the client's

**#1 `aria-checked` → WITHDRAWN, contract was wrong.** The control is `role="tablist"` /
`role="tab"`, where **`aria-checked` is not permitted** — it belongs to `radio`/`checkbox`.
My assertion demanded the client emit *invalid ARIA*. It was the single largest cause on the
board (~35 failures), all mine. This is precisely the rule I set when I had pinned `Lunar` on
a control iOS renders in English: **a test that demands the wrong value pushes the implementer
to break the thing it exists to protect.** Now asserts `aria-selected`.

**#3 screen roots absent → WITHDRAWN, bundle-grep artifact.** `Chrome.tsx:140` renders
`` data-testid={`onb-${step}`} ``, so the literal strings never appear in the bundle while the
ids resolve fine at runtime. Fourth instance in this project of a source grep lying about
test ids. **If a locator resolves at runtime, the grep is wrong, not the client.**

**#6 `expenses.Amount` → CLOSED.** SharedUI calls `String(localized:)` with no `bundle:`, so
it binds `.main`, which has no `Amount`; the expenses catalog's "Sumă" is an orphan that call
site cannot reach. Allowlisted with that evidence.

**Still real, send to Frontend: #4** (income step missing the `RON` suffix) and **#5**
(Emergency add-card `aria-label` missing `27,000 RON`). Two findings, not six.

## Contract preflight — 47 unverified, and its own limitation

All surfaces are now reachable, but **the preflight does not open modals** (Add Expense,
Manage Categories, New Category) or walk to New Month step 3. Most of the 47 belong to those,
so they are **unvisited, not proven absent** — the same distinction I insisted on for the
earlier 78. The ones that look genuinely missing on a *reachable* screen are the
`onb-summary-*` values and `onb-after-expenses-value` / `onb-savings-permonth-caption`.

---

## Original board (superseded above)

Run: isolated server, private port 8092, disposable store. `PARITY_EXPECT_TIMEOUT=2500`.

## Per suite

| Suite | Pass | Fail | Skip |
|---|---|---|---|
| `golden.spec.ts` | 39 | 24 | 2 |
| `numbers.spec.ts` | 2 | 13 | 0 |
| `content.spec.ts` | 4 | 18 | 0 |
| `locale.spec.ts` | 5 | 5 | 0 |
| `behaviour.spec.ts` | 3 | 2 | 0 |
| **Total** | **53** | **62** | **2** |
| `screens.spec.ts` | — | **NOT RUN** | — |

**Golden layer 1 in isolation: 26/26 pass.** Numeric parity is green at the server layer.

## Failures by root cause, ranked

| # | Root cause | Fails | Screen | Expected | Actual | Owner |
|---|---|---|---|---|---|---|
| 1 | `onb-strategy-priority` exposes `aria-checked=""` | ~35 | Onboarding Savings | `aria-checked="true"` on the default Priority segment | `""` | Frontend |
| 2 | Layer-2 seeding rejected | 24 | all golden layer 2 | persisted seed | `400 accounts.Index 0.id — invalid UUID` (fixture uses `"main"`) | Reviewer + Backend |
| 3 | Screen roots absent from bundle | cascade | Welcome / Accounts / Expenses | `onb-welcome`, `onb-accounts`, `onb-expenses` | absent | Frontend |
| 4 | Currency suffix missing | 1 | Onboarding Income | `RON` visible | absent | Frontend |
| 5 | a11y label incomplete | 1 | Onboarding Accounts | Emergency add-card `aria-label` contains `27,000 RON` | missing | Frontend |
| 6 | `expenses.Amount` RO absence unconfirmed | 1 | catalogue | confirmed verdict | unresolved | Analyst |

**#1 is the whole board.** It fails inside `stepSavings`, which every onboarding walkthrough
passes through, so it cascades into `numbers`, `content`, `behaviour` and golden layer 2.
Fixing it alone should convert the majority.

## Verdict

**Numeric parity: PASS** (26/26 vectors, server layer, incl. S02 two-month and S16 R10 guard).
**Content / behavioural / visual: NOT ESTABLISHED.** One a11y-attribute defect blocks the
walkthrough; the board below it is mostly cascade, not independent findings.

## Not run, and why

- **`screens.spec.ts` (all 92 captures) — out of time.** No visual grading was performed at
  402×874 or 1280×900. `REPORT.md` still shows 0/92 captured. **No visual verdict exists.**
- Layer-2 rendered-text assertions never executed (blocked by #2), so every golden
  `display` value remains unverified *in the DOM* — verified only server-side.

---

## Addendum — contract preflight added, and what it proves

`parity/contract.spec.ts` (`npm run parity:contract`) walks the app and diffs the live DOM
against `testids.ts`. **Runtime, not grep** — three agents (main, Frontend2, me) each got
wildly wrong numbers from source greps (105/105, 50/83, 232) because ids arrive via JSX
expressions, `testId` props and template literals. Only the DOM knows.

Result on this build:

```
23 ids observed live
78 UNVERIFIED — absent OR on an unreachable screen (this run cannot separate them)
 6 UNREACHABLE SURFACES: onboarding:summary, onboarding:dashboard,
                         expenses tab, insights tab, settings, new month
26 templated ids NOT CHECKED (valid arguments live in the fixture, not the contract)
```

**The 6 unreachable surfaces are all downstream of root cause #1.** `stepSavings` fails on
`onb-strategy-priority`'s `aria-checked`, so everything past the Savings screen is untested
rather than failing. **78 is an upper bound on missing ids, not a count of them.**

### The preflight got this wrong on its first two runs, and the corrections matter

1. It expanded templated ids against guessed arguments and reported **232 missing** — ~209
   invented by itself (`onb-expense-amount-main`; expense slugs are never account slugs).
   A false-positive detector generating 209 false positives. Now: literals only, templated
   ids counted and declared unchecked.
2. It labelled unreachable ids as "missing". Absent and unreachable are different verdicts
   and conflating them would have sent Frontend hunting for ids that already exist.

Both corrections are the same lesson the rest of this board keeps teaching: **an instrument
that reports confidently about what it cannot see is worse than one that admits the gap.**
