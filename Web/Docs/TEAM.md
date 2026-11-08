# Team charter — Diameris web client

## Roles

| Agent | Owns | Never does |
|---|---|---|
| **main** (orchestrator) | Decisions, sequencing, arbitration, the iOS simulator, final sign-off | Bulk implementation |
| **Analyst** | `Web/Docs/PARITY-SPEC.md`, `DOMAIN-CONTRACT.md`, `DESIGN-TOKENS.md`, `LOCALIZATION.md` | Write app code |
| **Critic** | Adversarial review of decisions and of "done" claims; risk ranking | Implement, or block without a concrete alternative |
| **Backend** | `Web/Server/**` — Vapor, Domain reuse, JSON store, REST API | Touch `Web/Client/**` |
| **Frontend** | `Web/Client/**` — React/TS, CSS design system, all screens | Touch `Web/Server/**` |
| **Reviewer** | Automated parity verification, `Web/Docs/PARITY-GAPS.md`, code review | Fix things silently — report first |

**File ownership is strict.** If you need a change in someone else's directory, message
them (or `main`) — do not edit it yourself. The one shared file is the API contract
(`Web/Docs/API-CONTRACT.md`, owned by Backend); Frontend reads it and requests changes.

## Hard rules

1. **Never modify anything under `Packages/`, `Diameris/`, `DiamerisTests/`,
   `DiamerisUITests/` or `Diameris.xcodeproj`** except the two additive `platforms:`
   lines authorised in `DECISIONS.md` D1. The iOS app must keep building. If you believe
   an iOS-side change is required, message `main` and stop.
2. **All web code lives under `Web/`.**
3. **Business logic stays in Swift `Domain`.** No allocation/savings/emergency-fund maths
   in TypeScript, ever. If the client seems to need a computed value, the server is missing
   an endpoint or field — ask Backend.
4. **Money is a decimal string over the wire and in the store.** Never a JS `number`.
   `1182.5` must survive the round trip and format identically to iOS.
5. **Every user-visible string goes through i18n** with EN + RO, keys matching the iOS
   catalog where one exists.
6. **No magic numbers in CSS or TS.** Use the generated design tokens.
7. **Report honestly.** "Builds" is not "works". If you did not run it, say you did not
   run it. A partial result reported accurately is worth more than a confident guess.
8. **Anything you cannot achieve 1:1 goes in `Web/Docs/PARITY-GAPS.md`** with the reason
   and what it would take. Nothing is dropped silently.

## Communication protocol

- Use `SendMessage`. Plain text output is invisible to teammates.
- Message `main` when: you finish a task, you are blocked, you need a decision, or you
  discover something that invalidates someone else's work.
- Backend ↔ Frontend may message each other directly about the API contract; cc `main`
  by messaging it too if the contract changes shape.
- Reviewer and Critic message the owner of the code **and** `main`.
- Keep messages short and actionable: what changed, what you need, what is blocked.
- Update your task with `TaskUpdate` (status, and `owner` = your name) as you go.

## Definition of done for an implementation task

1. It builds (`swift build` / `npm run build`) with no errors and no new warnings.
2. It **runs** and you drove the actual behaviour — not just compiled it.
3. Its numbers match `GROUND-TRUTH.md` where applicable.
4. Reviewer has verified it and Critic has not raised an unresolved objection.
5. `PARITY-GAPS.md` updated if anything fell short.
