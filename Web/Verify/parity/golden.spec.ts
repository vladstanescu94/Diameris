/**
 * GOLDEN-VECTOR HARNESS — DECISIONS.md R8, the enforcement of D6 axis 1.
 *
 * `Web/Docs/golden-vectors.json` is the single checked-in definition of numeric
 * correctness. Backend asserts it from Swift; this file asserts the SAME fixture
 * from the browser side, in two layers:
 *
 *   Layer 1 (every binding scenario) — seed the scenario through the API, read
 *   `GET /api/state`, and compare the server's raw decimal strings, formatted
 *   display strings, truncated percents and flags against the fixture.
 *
 *   Layer 2 (scenarios with `assertInUI: true`) — additionally drive the browser
 *   and compare RENDERED TEXT against the same `expected.display` values.
 *
 * Layer 1 alone would let a correct server and a wrong UI pass together. Layer 2 is
 * what makes "a divergence between server maths and rendered UI cannot hide" true.
 *
 * Scenarios with `status: "needs-confirmation"` are NOT asserted — they are reported
 * as skipped with their open question, so an unverified guess can never harden into
 * the definition of correct. Flip them to `binding` once Analyst fills the values.
 */
import { expect, test, type APIRequestContext, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { BASE_URL, TID } from './flows';

type Vectors = {
  schemaVersion: number;
  accountTemplates: Record<string, Record<string, unknown>>;
  formatterVectors: { cases: Array<{ raw: string; display: string; note?: string }> };
  percentVectors: {
    cases: Array<{ numerator: string; denominator: string; exact: string; percent: number; note?: string }>;
  };
  isBalancedVectors: {
    cases: Array<{ income: string; total: string; delta: string; isBalanced: boolean }>;
  };
  scenarios: Array<Scenario>;
  openQuestions: Array<{ id: string; question: string; blocks: string[] }>;
};

type Scenario = {
  id: string;
  title: string;
  discriminates: string;
  status: 'binding' | 'needs-confirmation';
  assertInUI: boolean;
  input: Record<string, unknown>;
  expected: {
    raw?: Record<string, string | null>;
    /** non-numeric expected state (enums, flags-as-strings) — exempt from the decimal check */
    state?: Record<string, string>;
    display?: Record<string, string | null>;
    percent?: Record<string, number | Record<string, number>>;
    flags?: Record<string, boolean>;
    rawMustNotEqual?: Record<string, string>;
    conservation?: {
      parts: string[];
      mustEqual: string;
      why: string;
      /** true = we are pinning a DEFECT: the parts deliberately do NOT sum to mustEqual. */
      expectedToFail?: boolean;
      expectedSum?: string;
    };
    invariant?: { equalFields: string[]; why: string };
    uiInvariant?: {
      noDestinationCardSelected?: boolean;
      uncappedTargetStruckThrough?: boolean;
      why: string;
    };
    geometry?: Record<string, string>;
    jointAssertion?: { fields: string[]; why: string };
    segments?: Record<string, { rows: Record<string, string>; total: string; why: string }>;
    transferPlanRows?: Array<{ name: string; amount: string; subtitle: string }>;
    transferPlanAbsentNames?: string[];
    transferPlanWhy?: string;
    forbiddenDisplay?: { monthly?: string[]; annual?: string[]; why: string };
    forbiddenAnywhere?: { strings: string[]; exact?: boolean; why: string };
    narrowWindowStrings?: { strings: string[]; why: string };
    note?: string;
  };
};

/**
 * Decimal-string arithmetic in integer minor units. Test-side only — the CLIENT never
 * does this (TEAM.md rule 3 / R2). Used solely to check the conservation invariant,
 * which cannot be expressed as a single field comparison.
 */
function toCents(decimal: string): bigint {
  const neg = decimal.startsWith('-');
  const [whole, frac = ''] = decimal.replace('-', '').split('.');
  const cents = BigInt(whole) * 100n + BigInt((frac + '00').slice(0, 2));
  return neg ? -cents : cents;
}

const VECTORS_PATH = fileURLToPath(
  new URL('../../Docs/golden-vectors.json', import.meta.url),
);
const V: Vectors = JSON.parse(readFileSync(VECTORS_PATH, 'utf8'));

/**
 * Seed a scenario. Uses the endpoints D4/R5 already define; if Backend adds the
 * dedicated `POST /api/golden/seed` we asked for, only this function changes.
 */
async function seed(
  request: APIRequestContext,
  scenario: Scenario,
  /**
   * Layer 2 must PERSIST. The oracle is a pure function that stores nothing, so seeding
   * through it leaves the app on onboarding and every rendered-text assertion fails with
   * "should land on the Dashboard". Layer 1 wants the oracle (fast, exact, no state);
   * layer 2 needs the real write path.
   */
  persist = false,
): Promise<unknown> {
  const input = scenario.input as {
    continuesFrom?: string;
    extraAccounts?: unknown[];
    newMonth?: { income: string; accountBalancesEnteredByUser: Record<string, string> };
  };

  // Chained scenarios (R11a, R11b) replay their base scenario, then apply a New Month.
  const base = input.continuesFrom
    ? V.scenarios.find((s) => s.id === input.continuesFrom)
    : undefined;
  if (input.continuesFrom && !base) {
    throw new Error(
      `${scenario.id} continuesFrom "${input.continuesFrom}", which is not in golden-vectors.json`,
    );
  }

  // Preferred path: the oracle endpoint. Persists nothing and answers in the fixture's own
  // key names. Template keys are OUR job to resolve — the endpoint wants full account
  // dictionaries, so sending `["main", {from: "emergency", ...}]` verbatim earns a 400.
  // Chained scenarios: the oracle takes the base scenario INLINE as a one-element
  // `continuesFrom` array, so it never reads the fixture file and stays a pure function of
  // its input. The child's own `accounts` is where extraAccounts go — appended to the base.
  const oraclePayload: Record<string, unknown> = base
    ? {
        // Scalars a chained scenario doesn't restate (monthlyIncome, savings, phase) are
        // inherited from the base — the child declares only what CHANGES. The oracle
        // requires them at the top level as well as inside `continuesFrom`.
        ...(base.input as Record<string, unknown>),
        ...scenario.input,
        continuesFrom: [
          { ...(base.input as Record<string, unknown>), accounts: expandAccounts(base.input) },
        ],
        // The child's `accounts` is where extraAccounts go — appended to the base's set.
        accounts: expandAccounts({ accounts: input.extraAccounts }) ?? [],
        expenses: (scenario.input as { expenses?: unknown[] }).expenses ?? [],
      }
    : { ...scenario.input, accounts: expandAccounts(scenario.input) ?? [] };

  const oracle = persist
    ? null
    : await request.post(`${BASE_URL}/api/golden/seed`, { data: oraclePayload });
  if (oracle?.ok()) return oracle.json();

  // A non-ok oracle used to fall through SILENTLY to the reset path. That hid a 400 caused
  // by unexpanded templates behind a slower, different code path — the harness reporting
  // success on a route it did not mean to take. Fallback still happens so a run completes,
  // but it is never quiet again.
  if (oracle) {
    console.warn(
      `[parity] ${scenario.id}: POST /api/golden/seed → ${oracle.status()}; falling back to ` +
        `reset→onboard→new-month. Body: ${(await oracle.text()).slice(0, 300)}`,
    );
  }

  const reset = await request.post(`${BASE_URL}/api/reset`);
  expect(reset.ok(), `POST /api/reset failed for ${scenario.id}`).toBeTruthy();

  const basis = base ? (base.input as Record<string, unknown>) : scenario.input;
  const onboardingPayload = {
    ...basis,
    accounts: expandAccounts(basis) ?? (basis as { accounts?: unknown }).accounts,
    ...(base ? { extraAccounts: input.extraAccounts } : {}),
  };
  const seeded = await request.post(`${BASE_URL}/api/onboarding/complete`, {
    data: onboardingPayload,
  });
  expect(
    seeded.ok(),
    `Could not seed golden scenario ${scenario.id}: POST /api/onboarding/complete returned ${seeded.status()}.\n` +
      `The scenario input shape is defined in Web/Docs/golden-vectors.json — if the server expects a different shape, message Reviewer.`,
  ).toBeTruthy();

  if (input.newMonth) {
    const applied = await request.post(`${BASE_URL}/api/new-month`, {
      data: {
        income: input.newMonth.income,
        accountBalances: input.newMonth.accountBalancesEnteredByUser,
      },
    });
    expect(
      applied.ok(),
      `${scenario.id}: POST /api/new-month returned ${applied.status()}. ` +
        `R10.2 — this endpoint must accept the dict as given and defend the precondition itself.`,
    ).toBeTruthy();
  }

  const state = await request.get(`${BASE_URL}/api/state`);
  expect(state.ok(), `GET /api/state failed for ${scenario.id}`).toBeTruthy();
  return state.json();
}

/**
 * Resolve `accounts` template references into full dictionaries.
 * `"main"` → the template; `{from: "emergency", ...overrides}` → template merged with
 * overrides; an inline object passes through untouched.
 */
/**
 * `POST /api/onboarding/complete` decodes `accounts[].id` as a UUID, while the fixture uses
 * readable slugs (`"main"`). Map slug → a stable UUID so the persisting path accepts it and
 * a failure is still traceable back to the slug by eye.
 */
const SLUG_UUID: Record<string, string> = {
  main: '00000000-0000-4000-8000-00000000ma1n',
  emergency: '00000000-0000-4000-8000-0000000eme4',
  savings: '00000000-0000-4000-8000-00000005a71c',
  joint: '00000000-0000-4000-8000-0000000j01nt',
};
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
function withUuid(a: Record<string, unknown>): Record<string, unknown> {
  const id = String(a.id ?? '');
  if (UUID_RE.test(id)) return a;
  const mapped =
    SLUG_UUID[id] ?? `00000000-0000-4000-8000-${id.padEnd(12, '0').slice(0, 12).replace(/[^0-9a-f]/gi, '0')}`;
  return { ...a, id: mapped, _slug: id };
}

function expandAccounts(input: Record<string, unknown>): unknown[] | undefined {
  const accounts = input.accounts as Array<string | Record<string, unknown>> | undefined;
  if (!accounts) return undefined;
  return accounts.map((a) => {
    if (typeof a === 'string') return withUuid({ ...V.accountTemplates[a] });
    if (typeof a === 'object' && a && 'from' in a) {
      const { from, ...overrides } = a as { from: string } & Record<string, unknown>;
      return withUuid({ ...V.accountTemplates[from], ...overrides });
    }
    return withUuid(a as Record<string, unknown>);
  });
}

/**
 * Look a key up inside a NAMED SECTION of the oracle response first.
 *
 * The oracle answers `{raw, display, percent, flags}`, and the same key name appears in
 * more than one section — `emergencyTarget` is `"20000"` in `raw` and `"20,000 RON"` in
 * `display`. A bare recursive search returns whichever the traversal hits first, so a raw
 * assertion can be answered by a display value. That failed loudly here; the dangerous
 * version is the one where the two happen to match and it passes for the wrong reason.
 * Scope first, fall back to the whole tree only when the section is absent (the
 * reset-based fallback path returns plain app state with no such sections).
 */
function scoped(state: unknown, section: string, key: string): unknown[] {
  const root = state as Record<string, unknown> | null;
  const sec = root && typeof root === 'object' ? root[section] : undefined;
  if (sec && typeof sec === 'object') {
    const hit = collect(sec, key);
    if (hit.length > 0) return hit;
    // A section that exists but lacks the key is a real absence, not a reason to go
    // hunting elsewhere and match something unrelated.
    return [];
  }
  return collect(state, key);
}

/** Depth-first lookup of a key anywhere in the state tree; returns all matches. */
function collect(node: unknown, key: string, out: unknown[] = []): unknown[] {
  if (Array.isArray(node)) {
    for (const n of node) collect(n, key, out);
  } else if (node && typeof node === 'object') {
    for (const [k, v] of Object.entries(node as Record<string, unknown>)) {
      if (k === key) out.push(v);
      collect(v, key, out);
    }
  }
  return out;
}

const binding = V.scenarios.filter((s) => s.status === 'binding');
const unverified = V.scenarios.filter((s) => s.status !== 'binding');

test.describe('Golden vectors — fixture integrity', () => {
  test('golden-vectors.json is well-formed and every needs-confirmation scenario has an open question', async () => {
    expect(V.schemaVersion, 'fixture schemaVersion').toBe(1);
    expect(binding.length, 'there must be binding scenarios to assert').toBeGreaterThan(0);
    for (const s of unverified) {
      const covered = V.openQuestions.some((q) =>
        q.blocks.some((b) => b.startsWith(s.id)),
      );
      expect(
        covered,
        `Scenario ${s.id} is needs-confirmation but no openQuestion blocks it — an unverified vector with no owner is how a guess becomes "correct".`,
      ).toBeTruthy();
    }
  });

  test('the four scenarios DECISIONS.md R11 makes mandatory are present and binding', () => {
    const required: Array<[string, string]> = [
      ['R11a two-month ground-truth sequence to 2,365 / 7,095', 'S02-ground-truth-month-2'],
      ['R11b incomplete reconciledBalances dict (the R10 case)', 'S16-incomplete-reconciled-balances'],
      [
        'R11c .primarySavings destination with no such account',
        'S17-primary-savings-destination-with-no-savings-account',
      ],
      ['R11d emergency at target, overflow redirected to savings', 'S08-emergency-at-target-priority'],
    ];
    for (const [label, id] of required) {
      const s = V.scenarios.find((x) => x.id === id);
      expect(s, `${label}: scenario "${id}" is missing from golden-vectors.json`).toBeDefined();
      expect(
        s!.status,
        `${label}: "${id}" exists but is not binding, so R11 is not actually satisfied`,
      ).toBe('binding');
    }
  });

  test('S24 stays a JOINT assertion — three independent checks would be defeatable', () => {
    const s24 = V.scenarios.find((x) => x.id === 'S24-split-per-side-independent-rounding');
    expect(s24, 'S24 missing').toBeDefined();
    expect(
      s24!.expected.jointAssertion?.fields.slice().sort(),
      'S24 must assert emergencyAllocation + savingsAllocation + splitTotalMonthly TOGETHER. ' +
        'A naive-rounding client produces 473 + 709 = 1,182, matching the total and one side, ' +
        'so any two of the three can pass independently while the implementation is wrong.',
    ).toEqual(['emergencyAllocation', 'savingsAllocation', 'splitTotalMonthly']);
  });

  test('R25a — the fixture contains an annual expense and a biting hard cap', () => {
    const annual = V.scenarios.find((x) => x.id === 'S25-annual-expense-displayed-in-both-segments');
    expect(
      annual?.expected.segments,
      'R25a: without a vector asserting an annual expense as DISPLAYED in both segments, a client ' +
        'rendering expense.amount passes the whole fixture and is 12x wrong on annual expenses.',
    ).toBeDefined();
    const capped = V.scenarios.find((x) => x.id === 'S26-hard-capped-emergency-fund');
    expect(
      capped?.expected.raw?.emergencyTarget,
      'R25a: the hard cap must BITE (effective target 20,000 below the uncapped 27,000), ' +
        'otherwise ignoring the cap entirely cannot fail a test.',
    ).toBe('20000');
    expect(
      capped?.expected.percent?.['emergencyProgressAfter'],
      'R25a: progress must be measured against the CAPPED target — 1182.5/20000 = 5.91% -> 5%, ' +
        'not the 4% an uncapped target gives. That difference is what makes the cap observable in a label.',
    ).toBe(5);
  });

  test('R26a — every mirrored defect carries a test that fails if the values come out CORRECT', () => {
    const mirrored = V.scenarios.filter((x) => x.expected.conservation?.expectedToFail);
    expect(
      mirrored.length,
      'the fixture is expected to contain mirrored defects (S17, S21) — if this is 0 the guard is vacuous',
    ).toBeGreaterThan(0);
    for (const m of mirrored) {
      const c = m.expected.conservation!;
      expect(
        c.expectedSum,
        `${m.id}: R26a — a mirrored defect MUST pin the exact defective value, not merely note that ` +
          `something is wrong. Without expectedSum the harness cannot tell "still broken as designed" ` +
          `from "broken differently".`,
      ).toBeDefined();
      const target = m.expected.raw?.[c.mustEqual] ?? m.input[c.mustEqual];
      if (typeof target === 'string') {
        expect(
          c.expectedSum,
          `${m.id}: the defective sum must DIFFER from ${c.mustEqual} — if they are equal there is no defect to mirror`,
        ).not.toBe(target);
      }
      expect(
        c.why,
        `${m.id}: R26a — the note must warn that a passing conservation check means DIVERGENCE, not a fix. ` +
          `Whoever hits this failure will otherwise "repair" it by relaxing the assertion.`,
      ).toMatch(/diverg/i);
    }
  });

  test('R27 — no vector contains two isPrimarySavings accounts', () => {
    for (const sc of V.scenarios) {
      const accounts = (sc.input as { accounts?: unknown[] }).accounts ?? [];
      const savingsLike = accounts.filter((a) => {
        if (typeof a === 'string') return a === 'savings';
        const o = a as { from?: string; type?: string; isPrimarySavings?: boolean };
        return o.isPrimarySavings === true || o.from === 'savings' || o.type === 'savings';
      });
      expect(
        savingsLike.length,
        `${sc.id}: R27 — iOS does not enforce isPrimarySavings uniqueness and resolves it with ` +
          `accounts.first(where:) over an UNSORTED @Query, so two such accounts make the credited ` +
          `account nondeterministic between launches. A vector over that state would encode one ` +
          `arbitrary run and then fail randomly — the fixture would be certifying a coin flip.`,
      ).toBeLessThanOrEqual(1);
    }
  });

  test('annual-derived sums are never pinned to a naive exact total (Decimal(1)/12 is inexact)', () => {
    for (const sc of V.scenarios) {
      const annual = ((sc.input as { expenses?: Array<{ frequency?: string }> }).expenses ?? []).some(
        (e) => e.frequency === 'annual',
      );
      if (!annual) continue;
      for (const key of ['dashboardTotalExpensesRaw', 'availableIncome', 'savingsAmount']) {
        expect(
          sc.expected.raw?.[key],
          `${sc.id}: has an annual expense, so "${key}" carries a 28-digit Decimal tail and cannot ` +
            `equal a clean integer. Assert expected.display instead, and expected.rawMustNotEqual ` +
            `for the naive value — a clean total means something recomputed outside Domain.`,
        ).toBeUndefined();
      }
      expect(
        sc.expected.rawMustNotEqual,
        `${sc.id}: an annual-expense scenario must carry rawMustNotEqual, else a TS reimplementation ` +
          `producing clean numbers would pass unnoticed.`,
      ).toBeDefined();
    }
  });

  test('savingsAllocation and savingsReceived are never conflated', () => {
    for (const sc of V.scenarios) {
      const raw = sc.expected.raw ?? {};
      if (raw['savingsAllocation'] !== undefined && raw['savingsReceived'] !== undefined) continue;
      // S01 and S02 have structurally identical plans; if both used savingsAllocation they
      // would contradict each other for the same key. That was a fixture bug, not a Domain bug.
      if (sc.id.startsWith('S02') ) {
        expect(
          raw['savingsAllocation'],
          'S02 must NOT use savingsAllocation — its 3547.5 is remainingMoney routed by ' +
            'remainingDestination, not an allocation the plan made (the plan allocates 0, as in S01).',
        ).toBeUndefined();
        expect(raw['savingsReceived'], 'S02 must pin savingsReceived').toBe('3547.5');
      }
    }
  });

  test('every scenario declares its phase explicitly — never inferred from zero balances', () => {
    for (const sc of V.scenarios) {
      const input = sc.input as { phase?: string; continuesFrom?: string };
      if (input.continuesFrom) continue;
      expect(
        input.phase,
        `${sc.id}: must declare phase 'onboarding' or 'established'. Inferring it from "all balances ` +
          `are zero" misclassifies a returning user who has spent everything — same data shape, ` +
          `completely different intent.`,
      ).toMatch(/^(onboarding|established)$/);
    }
  });

  test('no expected value is an inequality — R11 requires exact equality', () => {
    for (const s of V.scenarios) {
      for (const [k, v] of Object.entries(s.expected.raw ?? {})) {
        if (v === null) continue;
        expect(
          v,
          `${s.id}.raw.${k} = "${v}" — golden vectors must be exact decimal strings, never ranges or comparisons (R11: "never inequalities")`,
        ).toMatch(/^-?\d+(\.\d+)?$/);
      }
    }
  });
});

test.describe('Golden vectors — server maths (layer 1)', () => {
  for (const s of binding) {
    test(`${s.id}: ${s.title}`, async ({ request }) => {
      test.info().annotations.push({ type: 'discriminates', description: s.discriminates });
      const state = await seed(request, s);

      for (const [key, want] of Object.entries(s.expected.raw ?? {})) {
        if (want === null) continue;
        const found = scoped(state, 'raw', key);
        expect(
          found,
          `${s.id}: no "${key}" in the response's raw section (expected decimal string "${want}"). Money must be a decimal STRING, never a JS number.`,
        ).not.toHaveLength(0);
        expect(
          found[0],
          `${s.id}: raw "${key}" — ${s.discriminates}`,
        ).toBe(want);
      }

      for (const [key, want] of Object.entries(s.expected.state ?? {})) {
        const found = scoped(state, 'state', key);
        expect(
          found,
          `${s.id}: no "${key}" in the response (expected "${want}")`,
        ).not.toHaveLength(0);
        expect(found[0], `${s.id}: state "${key}" — ${s.discriminates}`).toBe(want);
      }

      for (const [key, want] of Object.entries(s.expected.flags ?? {})) {
        const found = collect(state, key);
        if (found.length === 0) continue; // flags are optional per scenario
        expect(found[0], `${s.id}: flag "${key}"`).toBe(want);
      }

      // Decimal(1)/12 is inexact, so annual-derived sums carry a 28-digit tail and iOS is
      // identically imprecise. Asserting the naive exact total would be asserting a value
      // Domain cannot produce; asserting the 33-digit tail would be unreadable and brittle.
      // So: assert it is NOT the naive value — the only way to get that is to have
      // recomputed outside Domain, which is the divergence R2 forbids.
      for (const [key, naive] of Object.entries(s.expected.rawMustNotEqual ?? {})) {
        if (key === 'why') continue;
        const found = scoped(state, 'raw', key);
        if (found.length === 0) continue;
        expect(
          found[0],
          `${s.id}: raw "${key}" came back as exactly "${naive}". ${s.expected.rawMustNotEqual!.why}`,
        ).not.toBe(naive);
      }

      // OQ2 — fields that must agree with each other, whatever their value.
      const inv = s.expected.invariant;
      if (inv) {
        const values = inv.equalFields.map((f) => ({ f, v: scoped(state, 'raw', f)[0] }));
        const present = values.filter((x) => typeof x.v === 'string');
        expect(
          present.length,
          `${s.id}: invariant needs at least two of [${inv.equalFields.join(', ')}] present`,
        ).toBeGreaterThan(1);
        for (const x of present.slice(1)) {
          expect(
            x.v,
            `${s.id}: ${inv.why}\n  ${present.map((p) => `${p.f}=${String(p.v)}`).join('  ')}`,
          ).toBe(present[0].v);
        }
      }

      // Conservation. Normally: the parts must sum to income. For S17 the ruling is that
      // iOS LOSES the money, so we pin the defect's exact sum instead (OQ8).
      const cons = s.expected.conservation;
      if (cons) {
        const target = scoped(state, 'raw', cons.mustEqual)[0];
        expect(
          typeof target,
          `${s.id}: conservation target "${cons.mustEqual}" must be present as a decimal string`,
        ).toBe('string');
        let sum = 0n;
        const breakdown: string[] = [];
        for (const part of cons.parts) {
          const v = scoped(state, 'raw', part)[0];
          const asString = typeof v === 'string' ? v : '0';
          breakdown.push(`${part}=${typeof v === 'string' ? v : '(absent → 0)'}`);
          sum += toCents(asString);
        }
        const detail = `\n  parts: ${breakdown.join(', ')}\n  sum=${Number(sum) / 100}`;

        if (cons.expectedToFail) {
          expect(
            cons.expectedSum,
            `${s.id}: a conservation vector marked expectedToFail must state expectedSum`,
          ).toBeDefined();
          expect(
            sum,
            `${s.id}: MIRRORED DEFECT — ${cons.why}${detail}`,
          ).toBe(toCents(cons.expectedSum!));
          expect(
            sum,
            `${s.id}: the parts now reconcile to ${cons.mustEqual}. That means the money is NO LONGER being lost — which is a DIVERGENCE from iOS, not a fix. Re-open OQ8 before changing this vector.${detail}`,
          ).not.toBe(toCents(target as string));
        } else {
          expect(
            sum,
            `${s.id}: money vanished. ${cons.why}${detail}, expected ${cons.mustEqual}=${String(target)}`,
          ).toBe(toCents(target as string));
        }
      }
    });
  }
});

test.describe('Golden vectors — rendered UI (layer 2)', () => {
  for (const s of binding.filter((x) => x.assertInUI)) {
    test(`${s.id}: rendered text matches the same fixture`, async ({ page, request }) => {
      test.info().annotations.push({ type: 'discriminates', description: s.discriminates });
      await seed(request, s, true);
      await page.goto(`${BASE_URL}/`);
      await expect(
        page.getByTestId(TID.dashboard),
        `${s.id}: seeding should land on the Dashboard (onboarding already complete)`,
      ).toBeVisible();

      const display = s.expected.display ?? {};
      const onDashboard: Array<[string, string]> = [
        ['monthlyIncome', TID.dashIncome],
        ['dashboardTotalExpensesRawNegative', TID.dashExpenses],
        ['savingsAmount', TID.dashSavings],
        ['personalSpending', TID.dashPersonalSpending],
        ['emergencyProgressAmounts', TID.dashEfAmounts],
        ['emergencyTargetCaption', TID.dashEfTargetCaption],
      ];
      for (const [key, tid] of onDashboard) {
        const want = display[key];
        if (!want) continue;
        await expect(
          page.getByTestId(tid),
          `${s.id}: the Dashboard must RENDER "${want}" for ${key}. ${s.discriminates}`,
        ).toHaveText(want);
      }

      const efPercent = (s.expected.percent ?? {})['emergencyProgressBefore'];
      if (typeof efPercent === 'number') {
        await expect(
          page.getByTestId(TID.dashEfPercent),
          `${s.id}: the emergency ring must render a TRUNCATED "${efPercent}%"`,
        ).toHaveText(`${efPercent}%`);
      }

      const breakdown = (s.expected.percent ?? {})['breakdown'];
      if (breakdown && typeof breakdown === 'object') {
        for (const [slug, pct] of Object.entries(breakdown as Record<string, number>)) {
          await expect(
            page.getByTestId(TID.breakdownPercent(slug)),
            `${s.id}: breakdown "${slug}" must render a TRUNCATED "${pct}%"`,
          ).toHaveText(`${pct}%`);
        }
      }

      // Gap 5 defect: the preselected destination is absent from the rendered options,
      // so NO card may show as selected. A "helpful" fallback is a divergence.
      if (s.expected.uiInvariant?.noDestinationCardSelected) {
        for (const tid of [TID.summaryRemainingChoiceSavings, TID.summaryRemainingChoicePrimary]) {
          const card = page.getByTestId(tid);
          if ((await card.count()) === 0) continue;
          await expect(
            card,
            `${s.id}: ${s.expected.uiInvariant.why}`,
          ).not.toHaveAttribute('data-selected', 'true');
        }
      }

      // Strings iOS never renders — phantom fallbacks that would read as real UI.
      for (const bad of s.expected.forbiddenAnywhere?.strings ?? []) {
        await expect(
          page.getByText(bad, { exact: s.expected.forbiddenAnywhere?.exact ?? false }),
          `${s.id}: "${bad}" must never render. ${s.expected.forbiddenAnywhere?.why}`,
        ).toHaveCount(0);
      }

      // Strings that exist only in one narrow state (S13's completion callout).
      for (const want of s.expected.narrowWindowStrings?.strings ?? []) {
        await expect(
          page.getByText(want),
          `${s.id}: "${want}" must render in this state. ${s.expected.narrowWindowStrings?.why}`,
        ).toBeVisible();
      }

      // R25 row 8 — the transfer plan is an ORDERED LIST. One account can appear twice.
      const planRows = s.expected.transferPlanRows;
      if (planRows) {
        await page.getByTestId(TID.newMonthButton).click();
        await page.getByTestId(TID.nmNextButton).click();
        await page.getByTestId(TID.nmNextButton).click();

        const rows = page.getByTestId(TID.nmTransferList).getByTestId(/^nm-transfer-row-/);
        await expect(
          rows,
          `${s.id}: the plan must render exactly ${planRows.length} transfer rows. ` +
            `Fewer means rows were collapsed by account — ${s.expected.transferPlanWhy}`,
        ).toHaveCount(planRows.length);

        // Compare the whole ordered list at once: a per-row loop would stop at the first
        // mismatch and hide the collapse, which is precisely the failure being hunted.
        const actual = [];
        for (let i = 0; i < planRows.length; i++) {
          actual.push({
            name: ((await page.getByTestId(TID.nmTransferName(i)).textContent()) ?? '').trim(),
            amount: ((await page.getByTestId(TID.nmTransferValue(i)).textContent()) ?? '').trim(),
            subtitle: ((await page.getByTestId(TID.nmTransferSub(i)).textContent()) ?? '').trim(),
          });
        }
        expect(
          actual,
          `${s.id}: ${s.expected.transferPlanWhy}\n  A single row of "+1,182 RON" (last-write-wins) ` +
            `or "+4,730 RON" (summed) both look plausible and are both wrong.`,
        ).toEqual(planRows);

        for (const absent of s.expected.transferPlanAbsentNames ?? []) {
          await expect(
            page.getByTestId(TID.nmTransferList),
            `${s.id}: "${absent}" must be ABSENT from the plan entirely — not rendered as a zero row`,
          ).not.toContainText(absent);
        }
        await dismissSettings(page);
      }

      // R25a — the amount/monthlyAmount/annualAmount triple, asserted per segment.
      for (const [segment, spec] of Object.entries(s.expected.segments ?? {})) {
        await page.getByTestId(TID.tabExpenses).click();
        await page
          .getByTestId(segment === 'annual' ? TID.expensesPeriodAnnual : TID.expensesPeriodMonthly)
          .click();
        for (const [slug, want] of Object.entries(spec.rows)) {
          await expect(
            page.getByTestId(TID.expenseRowAmount(slug)),
            `${s.id} [${segment}] row "${slug}" must render "${want}". ${spec.why}`,
          ).toHaveText(want);
        }
        await expect(
          page.getByTestId(TID.expensesTotal),
          `${s.id} [${segment}] segment total must be "${spec.total}"`,
        ).toHaveText(spec.total);

        const forbidden = s.expected.forbiddenDisplay?.[segment as 'monthly' | 'annual'] ?? [];
        for (const bad of forbidden) {
          await expect(
            page.getByTestId(TID.expensesScreen),
            `${s.id} [${segment}] the string "${bad}" must NOT appear. ${s.expected.forbiddenDisplay?.why}`,
          ).not.toContainText(bad);
        }
        await page.getByTestId(TID.tabDashboard).click();
      }

      // R25a — a hard cap that bites renders the uncapped target struck through.
      if (s.expected.uiInvariant?.uncappedTargetStruckThrough) {
        const uncapped = page.getByTestId(TID.efTargetUncapped);
        await expect(
          uncapped,
          `${s.id}: ${s.expected.uiInvariant.why}`,
        ).toBeVisible();
        const decoration = await uncapped.evaluate(
          (el) => getComputedStyle(el).textDecorationLine,
        );
        expect(
          decoration,
          `${s.id}: the uncapped target must be visibly STRUCK THROUGH, not merely present (got text-decoration-line: ${decoration})`,
        ).toContain('line-through');
      }

      // Split mode's "Total Monthly" lives in the Settings sheet, not the Dashboard.
      const splitTotal = display['splitTotalMonthly'];
      if (splitTotal) {
        await page.getByTestId(TID.toolbarSettings).click();

        const joint = s.expected.jointAssertion;
        if (joint) {
          // S24 — assert all three TOGETHER. Independently, a naive-rounding client
          // produces 473 + 709 = 1,182: the total matches and one side matches, so any
          // two of the three checks pass while the implementation is wrong. Comparing the
          // whole tuple in one expect is what makes this undefeatable, and it prints all
          // three actual values on failure instead of stopping at the first.
          const actual = {
            emergencyAllocation: (
              await page.getByTestId(TID.settingsSplitResolvedAmount('emergency')).textContent()
            )?.trim(),
            savingsAllocation: (
              await page.getByTestId(TID.settingsSplitResolvedAmount('savings')).textContent()
            )?.trim(),
            splitTotalMonthly: (
              await page.getByTestId(TID.settingsSplitTotalMonthly).textContent()
            )?.trim(),
          };
          const wanted = Object.fromEntries(
            joint.fields.map((f) => [f, display[f]]),
          ) as Record<string, string>;
          expect(
            actual,
            `${s.id}: ${joint.why}\n  The parts are expected to sum to 1,183 against a 1,182 total — that is iOS behaviour, not a bug to reconcile.`,
          ).toEqual(wanted);
        } else {
          await expect(
            page.getByTestId(TID.settingsSplitTotalMonthly),
            `${s.id}: Settings → Split must render Total Monthly "${splitTotal}". ${s.discriminates}`,
          ).toHaveText(splitTotal);
        }
        await dismissSettings(page);
      }

      // R3: the Expenses tab total is a DIFFERENT number from the Dashboard total.
      const tabTotal = display['expensesTabTotalMonthlyNormalised'];
      if (tabTotal) {
        await page.getByTestId(TID.tabExpenses).click();
        await expect(
          page.getByTestId(TID.expensesTotal),
          `${s.id}: the Expenses tab total is enabled-only and frequency-normalised (R3) — it must render "${tabTotal}", NOT the Dashboard's raw total`,
        ).toHaveText(tabTotal);
      }
      const counter = display['housingCategoryCounter'];
      if (counter) {
        await expect(
          page.getByTestId(TID.categoryCount('housing')),
          `${s.id}: the "n/m enabled" counter must read "${counter}"`,
        ).toHaveText(counter);
      }
    });
  }
});

test.describe('Golden vectors — NOT asserted (unverified, must be filled before they count)', () => {
  for (const s of unverified) {
    test(`${s.id}: ${s.title}`, async () => {
      const blocking = V.openQuestions
        .filter((q) => q.blocks.some((b) => b.startsWith(s.id)))
        .map((q) => `${q.id}: ${q.question}`)
        .join('\n');
      test.skip(
        true,
        `Not asserted — status is "needs-confirmation".\n${blocking}\nFlip to "binding" in Web/Docs/golden-vectors.json once Analyst fills the expected values.`,
      );
    });
  }
});

/**
 * These three vector tables are pure functions with no UI surface, so the browser
 * cannot exercise them directly — Backend asserts them in Swift. They are listed here
 * so the count of what the fixture covers is visible from one place, and so a
 * malformed table is caught even if Swift-side wiring lags.
 */
test.describe('Golden vectors — pure tables (asserted Swift-side; shape-checked here)', () => {
  test('formatter vectors are well-formed and include both half-even directions', () => {
    const cases = V.formatterVectors.cases;
    expect(cases.length, 'formatter vector count').toBeGreaterThanOrEqual(10);
    expect(
      cases.some((c) => c.raw.endsWith('.5') && c.display.replace(/[^0-9]/g, '').endsWith('2')),
      'fixture must contain a .5 case that rounds DOWN to an even integer',
    ).toBeTruthy();
    expect(
      cases.some((c) => c.raw === '1183.5' && c.display === '1,184 RON'),
      'fixture must contain a .5 case that rounds UP to an even integer',
    ).toBeTruthy();
    for (const c of cases) {
      expect(c.display, `formatter case ${c.raw} must be suffixed " RON"`).toMatch(/ RON$/);
    }
  });

  test('percent vectors all truncate, and at least two would differ under rounding', () => {
    let discriminators = 0;
    for (const c of V.percentVectors.cases) {
      const exact = Number(c.exact.replace('%', ''));
      expect(
        Math.floor(exact),
        `percent vector ${c.numerator}/${c.denominator}: fixture says ${c.percent} but truncation of ${c.exact} is ${Math.floor(exact)}`,
      ).toBe(c.percent);
      if (Math.round(exact) !== c.percent) discriminators++;
    }
    expect(
      discriminators,
      'the fixture must contain cases where rounding and truncation DISAGREE, else it proves nothing',
    ).toBeGreaterThanOrEqual(2);
  });

  test('isBalanced vectors bracket the 0.01 boundary from both sides', () => {
    const cases = V.isBalancedVectors.cases;
    expect(
      cases.some((c) => c.delta === '0.009' && c.isBalanced),
      'need a case just inside the boundary',
    ).toBeTruthy();
    expect(
      cases.some((c) => c.delta === '0.01' && !c.isBalanced),
      'need a case exactly ON the boundary — it must be false, the comparison is strict <',
    ).toBeTruthy();
    expect(
      cases.some((c) => c.delta.startsWith('-') && c.isBalanced),
      'need a negative-delta case',
    ).toBeTruthy();
  });
});

async function dismissSettings(page: Page): Promise<void> {
  const cancel = page.getByRole('button', { name: 'Cancel', exact: true }).last();
  if (await cancel.isVisible().catch(() => false)) await cancel.click().catch(() => {});
  else await page.keyboard.press('Escape').catch(() => {});
}
