# Diameris Web — a local, laptop client for the iOS app

A browser client that is **1:1 with the iOS app**. It runs entirely on your machine: no cloud, no
accounts, no external services.

## Run it

```sh
Web/run.sh
```

Then open **http://127.0.0.1:8080**.

First run builds the Swift server (~20s) and the frontend. `run.sh` is idempotent — if something is
already serving on the port it exits rather than starting a duplicate.

Data lives in `~/.diameris/web-store.json`. Delete that file for a clean slate, or use the
dev-only Reset in the toolbar (`npm run dev` builds only).

### Iterating on the UI

```sh
Web/dev.sh          # Vite dev server on :5173, proxying /api to :8080
```

Extra dev routes: `?dev=gallery` (design-system showcase), `?dev=onboarding`, `?dev=modals`.
Add `?lang=ro` to any URL to see the Romanian build.

## How it works, and why

**The browser holds no business logic.** The server is a Vapor app that compiles the iOS app's own
`Packages/Core/Domain` and `Packages/Core/Utilities` and exposes them over JSON — so
`TransferCalculator`, `BalanceReconciler` and `AmountFormatter` are *the same code the phone runs*,
not a port of it.

That matters because the maths is full of details a reimplementation would get wrong. Money rounds
**half-even** (`1182.5 → "1,182"`, `3547.5 → "3,548"`), percentages **truncate** rather than round
(`10.53% → 10%`), annual expenses normalise through a 28-digit constant so `1200/year` is
`99.999…`/month and *not* `100`, and every JavaScript default (`Math.round`, `toFixed`,
`Intl.NumberFormat`) is wrong for at least one of those. The server therefore sends every amount
**pre-formatted** and every percentage **pre-truncated**; the client never rounds, divides or sums.
A test (`src/lib/noClientMaths.test.ts`) fails the build if arithmetic creeps in.

```
Browser (React/TS)          Vapor server              iOS packages
  renders strings   ←──JSON──  assembles state  ←──uses──  Domain + Utilities
  zero arithmetic              formats money              (unmodified logic)
```

## Layout

| Path | What |
|---|---|
| `Web/Server/` | Vapor app; JSON store; serves the built client |
| `Web/Client/` | Vite + React + TypeScript; the UI |
| `Web/Verify/` | Playwright parity harness (`npm run parity`) |
| `Web/Docs/` | Specs and decisions — start with `GROUND-TRUTH.md` |

## The documents worth reading

- **`GROUND-TRUTH.md`** — what the live iOS app actually does, captured by driving it, with
  verified numbers and 25 reference screenshots.
- **`DECISIONS.md`** — every architectural decision and its reasoning, including the ones that
  turned out wrong and why.
- **`VERIFICATION-LOG.md`** — checks run with real output, and the standing rules learned from
  getting things wrong. The most useful document if you're picking this up cold.
- `PARITY-SPEC.md`, `DOMAIN-CONTRACT.md`, `DESIGN-TOKENS.md`, `LOCALIZATION.md`, `API-CONTRACT.md`.

## Checks

```sh
python3 Web/Docs/api-propagation-check.py    # every ruling actually implemented? exit 0 = yes
cd Web/Client && npm test                    # unit + guard tests
cd Web/Verify  && npm run parity             # parity suite (needs Web/verify-server.sh on :8081)
```

## Deliberate divergences

Some things here are *intentionally* not "better" than the iOS app, because parity was the goal:

- Where iOS has a defect, this reproduces it and logs it in `PARITY-GAPS.md`. Each mirrored defect
  carries a test that **fails if the values ever come out correct**, so nobody fixes it by accident.
- Some strings render English even in Romanian, because iOS does too (its translation exists but
  the runtime can never reach it). Those are allowlisted with evidence.
- The Expenses tab shows `Annual` in English in the segmented control while a row caption shows
  `(Anual)` in Romanian — same word, two module bundles, both correct on iOS.

Not portable and dropped: haptics, and Liquid Glass is approximated with `backdrop-filter`.
