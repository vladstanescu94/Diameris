/**
 * LOCALISATION PARITY — axis 2 (content) in the Romanian catalogue.
 *
 * THIS SUITE EXISTS BECAUSE THE HARNESS HAD A HOLE. Every other suite asserts English
 * only, so an entire language could have been wrong — wrong namespace, missing key,
 * untranslated fallback — and the parity board would have stayed green. main flagged the
 * `Search expenses` namespace defect and asked whether my RO assertions would catch it.
 * They would not have: there were none. This closes that.
 *
 * The failure mode being hunted is specific and quiet: `t()` resolving a key in the WRONG
 * namespace silently falls back to English rather than erroring, so the app looks fine to
 * anyone reading English and is broken for every Romanian user. The same sentence lives in
 * several namespaces with different Romanian wording, which is exactly why R4 mandated
 * per-namespace catalogues.
 *
 * Language is selected with `?lang=ro` (App.tsx — there is no in-app picker, because iOS
 * takes the language from the device).
 */
import { expect, test, type Page } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { BASE_URL, completeOnboarding, TID } from './flows';

type Catalog = Record<string, Record<string, string>>;

const load = (lang: string): Catalog =>
  JSON.parse(
    readFileSync(fileURLToPath(new URL(`../../Client/src/locales/${lang}.json`, import.meta.url)), 'utf8'),
  );

const EN = load('en');
const RO = load('ro');

const flatten = (c: Catalog): Record<string, string> => {
  const out: Record<string, string> = {};
  for (const [ns, entries] of Object.entries(c)) {
    for (const [k, v] of Object.entries(entries)) out[`${ns}.${k}`] = v;
  }
  return out;
};
const FLAT_EN = flatten(EN);
const FLAT_RO = flatten(RO);

/**
 * Keys legitimately absent from RO or identical in both. Every entry is a deliberate
 * decision, not a backlog: format-only strings carry no words, and "Personal" is spelled
 * the same in Romanian. Anything NOT on this list that shows up untranslated is a defect.
 */
const ALLOWED_UNTRANSLATED = new Set([
  'app.%lld%%',
  'app.0',
  'app.2×',
  'app.3×',
  'dashboard.%lld%%',
  'dashboard.+%@',
  'expenses.',
  'expenses.(%@)',
  'app.Personal',
  'domain.Personal',
  'onboarding.Personal',
  'dashboard.Personal',
  'onboarding.Max:',
  'onboarding.Total: %@',
  // Correct English fallbacks — no Romanian exists anywhere in iOS. Confirmed independently
  // by Frontend. Allowlisted so G7 cannot grow to include correct behaviour.
  'app.Developer Tools',
  'dashboard.Developer Tools',
  'app.%lld percent complete',
  'dashboard.%lld percent complete',
  // ⚠️ THE MOST CONVINCING FALSE FINDING IN THIS CLASS — and it is correct behaviour.
  // The catalog holds TWO variants of each key and the Romanian sits on the STALE one:
  //   'Step %d of %d'     -> ro 'Pasul %d din %d'  ORPHANED (Swift renders Int as %lld)
  //   'Step %lld of %lld' -> ro none               LIVE
  // So iOS renders "Step 1 of 3" in Romanian, and translating the live key would be a
  // silent improvement (R26a). A translated key on one side and nothing on the other is
  // the most bug-shaped thing a catalog diff can show, and here it is right.
  // Same class as the dead 'Total %@ Expenses'. G7 closed at ZERO genuine defects.
  'dashboard.Step %lld of %lld',
  'dashboard.Target: %lld× monthly income',
  'app.Back',
  'dashboard.Back',
  // The ORPHANED variants themselves. Swift renders Int as %lld, so these %d / %@ forms are
  // unreachable at runtime; the Analyst dropped their Romanian values so a future
  // `t('Step %d of %d')` cannot resurrect the improvement. No RO value is correct here.
  'dashboard.Step %d of %d',
  'dashboard.Target: %@× monthly income',
  // Confirmed correct English by two agents independently: Frequency.displayName binds
  // Domain's bundle, which has no Romanian for these. The expenses-catalog entries are
  // unused by that code path.
  'expenses.Monthly',
  // CONFIRMED 2026-08-06 from `Web/gen-locales.py` DEAD_TRANSLATIONS — Class B: the copy has
  // Romanian but the PRODUCING module's catalog has none, so iOS falls back to English and
  // serving the Romanian would be a silent improvement (R26a). Only the `ro` value is dropped;
  // `en` stays so the key still renders.
  //   ("expenses","Monthly") ("expenses","Amount")
  //   ("dashboard","Step %d of %d") ("dashboard","Target: %@× monthly income")
  // `Annual` is DELIBERATELY EXCLUDED from that set: it has a real call site in the Expenses
  // module (ExpenseItemRow.swift:60) where `Anual` genuinely resolves. That is exactly the
  // asymmetry that looked suspicious — and it is the precise distinction, not an oversight.
  // `Amount`: SharedUI calls String(localized:) with NO `bundle:`, so it binds `.main`,
  // which has no `Amount`. The expenses catalog's "Sumă" is an orphan that call site cannot
  // reach — same Class B shape, different mechanism.
  'expenses.Amount',
]);

/**
 * Absences that are NOT yet confirmed either way. Kept separate from the allowlist on
 * purpose: allowlisting an unverified absence is how a real defect becomes permanent
 * silence. These fail loudly, and the failure names the question rather than the value.
 */
const UNCONFIRMED_ABSENCES = new Map<string, string>([
  // Empty: every absence is now backed by evidence. Keep this mechanism — an absence with no
  // recorded reason must fail in a bucket that names the QUESTION, never be allowlisted on
  // the assumption it is fine. Allowlisting an unverified absence is how a real defect
  // becomes permanent silence.
]);

// ─────────────────── catalogue integrity (offline, no server) ───────────────────

test.describe('Locale catalogues — static integrity', () => {
  test('every EN key has a Romanian counterpart, or a recorded reason not to', () => {
    const missing = Object.keys(FLAT_EN).filter(
      (k) => !(k in FLAT_RO) && !ALLOWED_UNTRANSLATED.has(k),
    );
    const unconfirmed = missing.filter((k) => UNCONFIRMED_ABSENCES.has(k));
    const unexplained = missing.filter((k) => !UNCONFIRMED_ABSENCES.has(k));

    expect(
      unexplained,
      `Keys in en.json with no Romanian value and no recorded reason. A missing key falls back ` +
        `to English SILENTLY — nothing errors, and the app simply speaks English at a Romanian ` +
        `user. Either translate it, or allowlist it WITH the reason it is correct.`,
    ).toEqual([]);

    expect(
      unconfirmed.map((k) => `${k} — ${UNCONFIRMED_ABSENCES.get(k)}`),
      `Absences awaiting confirmation. Deliberately NOT allowlisted: allowlisting an ` +
        `unverified absence is how a real defect becomes permanent silence. Resolve each, then ` +
        `move it to ALLOWED_UNTRANSLATED with its reason or fix the catalogue.`,
    ).toEqual([]);
  });

  test('no Romanian value is an untranslated copy of the English one', () => {
    const copies = Object.keys(FLAT_EN).filter(
      (k) =>
        k in FLAT_RO &&
        FLAT_EN[k] === FLAT_RO[k] &&
        FLAT_EN[k].length > 3 &&
        !/^[%\d\s×+.:-]*$/.test(FLAT_EN[k]) &&
        !ALLOWED_UNTRANSLATED.has(k),
    );
    expect(
      copies,
      `Romanian values identical to English. Some are legitimate (allowlist them explicitly ` +
        `in ALLOWED_UNTRANSLATED with a reason); the rest are untranslated strings that will ` +
        `never be noticed by an English-reading reviewer.`,
    ).toEqual([]);
  });

  test('keys that exist in several namespaces with DIFFERENT Romanian wording are enumerated', () => {
    // These are the namespace landmines: resolving one in the wrong namespace yields a
    // real Romanian string rather than an obvious fallback, so the bug reads as a typo.
    const byKey = new Map<string, Set<string>>();
    for (const full of Object.keys(FLAT_RO)) {
      const [, ...rest] = full.split('.');
      const key = rest.join('.');
      if (!byKey.has(key)) byKey.set(key, new Set());
      byKey.get(key)!.add(FLAT_RO[full]);
    }
    const divergent = [...byKey.entries()].filter(([, vals]) => vals.size > 1);
    test
      .info()
      .annotations.push({
        type: 'namespace-landmines',
        description: divergent.map(([k, v]) => `${k}: ${[...v].join(' | ')}`).join('\n'),
      });
    // Not a failure — a recorded inventory. The point is that these keys CANNOT be
    // verified by reading English, so they need per-screen assertions below.
    expect(Array.isArray(divergent)).toBe(true);
  });
});

// ─────────────────── rendered Romanian (needs the app) ───────────────────

async function openRomanian(page: Page, path = '/'): Promise<void> {
  await page.goto(`${BASE_URL}${path}?lang=ro`);
}

test.describe('Interpolation — positional specifiers must never reach the DOM', () => {
  // A client defect made `i18n.ts`'s regex miss `%1$lld`, and the live English value of
  // `dashboard."Step %lld of %lld"` is "Step %1$lld of %2$lld". It was inert only while
  // onboarding bound a namespace lacking the key; New Month binds `dashboard` and would
  // have rendered the raw format string. This is the GENERAL guard: it catches any future
  // positional key regardless of which string introduces it, in either language.
  for (const lang of ['en', 'ro'] as const) {
    test(`no rendered text contains %1$ or %2$ (${lang})`, async ({ page, request }) => {
      await completeOnboarding(page, request, 'dashboard');
      await page.goto(`${BASE_URL}/${lang === 'ro' ? '?lang=ro' : ''}`);
      for (const marker of ['%1$', '%2$']) {
        await expect
          .soft(
            page.locator('body'),
            `[${lang}] an unsubstituted positional specifier "${marker}" reached the DOM — ` +
              `the interpolator did not match it and the raw format string is on screen`,
          )
          .not.toContainText(marker);
      }
    });
  }
});

test.describe('Romanian rendering — no English leakage', () => {
  test('the SAME word renders English in the control and Romanian in the row caption', () => {
    // ⚠️ CORRECTED 2026-08-06. My first version asserted `Lunar`/`Anual` on the segmented
    // control. That was wrong and would have FAILED A CORRECT IMPLEMENTATION.
    //
    // `Frequency.displayName` (Frequency.swift:35-36) is *Domain* code binding Domain's
    // bundle, and `Monthly`/`Annual` are absent from the Domain catalog — so the control
    // renders ENGLISH. The `Lunar`/`Anual` entries live in the *expenses* catalog, which
    // that code never reads. The row caption (ExpenseItemRow.swift:60) DOES bind the
    // Expenses bundle, so it renders `(Anual)`.
    //
    // Result: one screenshot shows a control reading `Annual` directly above a row reading
    // `(Anual)`. Both are correct. That is what ships and that is the parity target.
    expect(FLAT_RO['expenses.Annual'], 'the expenses catalog holds the RO word').toBe('Anual');
    expect(
      RO['domain']?.['Annual'],
      'the DOMAIN catalog must NOT hold it — its absence is why the control renders English',
    ).toBeUndefined();
  });

  test('the dead `Total %@ Expenses` translation is never used', () => {
    // Standing rule #3. `"Total \(x) Expenses".localized` interpolates BEFORE localisation,
    // so the runtime key is "Total Monthly Expenses" and can never match the catalog's
    // "Total %@ Expenses". iOS therefore renders it fully English. The Romanian value
    // exists but is unreachable — if the web wires it through t(), we show Romanian where
    // iOS shows English: a silent improvement, which R26a forbids.
    //
    // Scope: this is the ONLY dead interpolated key in the codebase. Most %@ keys resolve
    // fine, so this must not generalise into a rule against interpolated keys.
    expect(
      FLAT_RO['expenses.Total %@ Expenses'],
      'if this entry is gone the negative assertion below is vacuous — keep it and keep it unused',
    ).toBe('Cheltuieli %@ totale');
  });

  test('Expenses screen speaks Romanian', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await openRomanian(page);
    await page.getByTestId(TID.tabExpenses).click();
    const screen = page.getByTestId(TID.expensesScreen);

    // The segmented control renders ENGLISH in Romanian — Domain's bundle has no key.
    await expect
      .soft(
        page.getByTestId(TID.expensesPeriodMonthly),
        'the Monthly segment renders ENGLISH in Romanian (Frequency.displayName binds the ' +
          'Domain bundle, which lacks the key). "Lunar" here would be a silent improvement ' +
          'over iOS, which R26a forbids.',
      )
      .toHaveText('Monthly');
    await expect
      .soft(page.getByTestId(TID.expensesPeriodAnnual), 'the Annual segment renders ENGLISH')
      .toHaveText('Annual');

    // The `Search expenses` defect: resolved in the `app` namespace it falls back to
    // English, which looks like nothing is wrong unless you read Romanian.
    await expect
      .soft(
        page.getByPlaceholder('Caută cheltuieli'),
        'the search placeholder must resolve in the `expenses` namespace → "Caută cheltuieli". ' +
          'If it renders "Search expenses", t() resolved it in `app` and fell back silently.',
      )
      .toBeVisible();

    // English that is CORRECT here, allowlisted with its reason so the sweep does not
    // flag correct behaviour: `Monthly`/`Annual` come from Domain's bundle (no RO key);
    // `Developer Tools` and `%lld percent complete` have no Romanian anywhere in iOS.
    const ALLOWED_ENGLISH = ['Monthly', 'Annual', 'Developer Tools', 'percent complete'];
    for (const english of ['Search expenses']) {
      await expect
        .soft(
          screen,
          `English leakage: "${english}" must not appear on the Romanian Expenses screen`,
        )
        .not.toContainText(english);
    }
    test.info().annotations.push({
      type: 'allowed-english',
      description: ALLOWED_ENGLISH.join(', '),
    });

    // The dead translation must never reach the DOM (Standing rule #3 / R26a).
    await expect
      .soft(
        page.getByText('Cheltuieli', { exact: false }),
        'the dead `Total %@ Expenses` -> "Cheltuieli %@ totale" translation must NEVER render: ' +
          'iOS cannot reach it, so showing it would be a silent improvement over the app we are porting',
      )
      .toHaveCount(0);
  });

  test('the Expenses header is FULLY ENGLISH in Romanian', async ({ page, request }) => {
    // ⚠️ CORRECTED. An earlier instruction said the target was the mixed "Total Lunar
    // Expenses" and I pinned that. It is wrong. iOS renders "Total Monthly Expenses" —
    // both words English — for two INDEPENDENT reasons, which is why the mixed reading
    // looked plausible: (1) the wrapper is a dead lookup, `"Total \(x) Expenses".localized`
    // interpolates before localising so the runtime key can never match "Total %@ Expenses";
    // (2) the inner word is already English via the Domain-bundle mismatch.
    await completeOnboarding(page, request, 'dashboard');
    await openRomanian(page);
    await page.getByTestId(TID.tabExpenses).click();
    await expect
      .soft(
        page.getByText('Total Monthly Expenses'),
        'iOS renders this header fully English in Romanian. Neither "Total Lunar Expenses" ' +
          '(mixed) nor "Cheltuieli lunare totale" (translated) is the target — both would be ' +
          'improvements on iOS, and R26a forbids silent improvement.',
      )
      .toBeVisible();
  });

  test('Onboarding welcome speaks Romanian', async ({ page, request }) => {
    await completeOnboarding(page, request, 'welcome');
    await openRomanian(page);
    const ro = FLAT_RO['onboarding.Take control of your money'];
    test.skip(!ro, 'catalogue has no RO welcome title — caught by the static integrity test');
    await expect
      .soft(page.getByText(ro), `the welcome title must render "${ro}"`)
      .toBeVisible();
    await expect
      .soft(
        page.getByTestId(TID.onbWelcome),
        'English leakage on the Romanian welcome screen',
      )
      .not.toContainText('Take control of your money');
  });
});
