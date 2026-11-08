/**
 * CONTRACT PREFLIGHT — does the client actually implement `testids.ts`?
 *
 * WHY THIS EXISTS: a missing test id does not degrade a run, it *fails* it, and it fails
 * disguised as a broken screen. `onb-name-field` was absent, so `stepName()` never filled
 * the field, Continue stayed correctly disabled, and the run died on a 180s timeout whose
 * page snapshot read exactly like a genuine UI bug. It took 17 screens × 2 themes ×
 * 2 viewports down with it. One missing hook, an entire visual sweep lost, and the
 * evidence pointed at the wrong layer.
 *
 * WHY IT IS RUNTIME AND NOT A GREP: two separate agents grepped the source for
 * `data-testid="literal"` and got 105/105 and 50/83 "missing" respectively — both wildly
 * wrong, because ids arrive via JSX expressions, `testId` props and template literals
 * (`` data-testid={`onb-${step}`} ``). A source grep cannot see how an id is constructed;
 * only the DOM can. A preflight that lies about the contract is worse than none, so this
 * one drives the app and reads the rendered attributes.
 *
 * It reports MISSING ids as one readable list instead of letting the first one time out
 * mid-sweep. Run it before anything else: `npm run parity:contract`.
 */
import { expect, test } from '@playwright/test';
import { BASE_URL, completeOnboarding, TID } from './flows';

/**
 * LITERAL ids only.
 *
 * The first version of this function also expanded every templated id against a list of
 * representative arguments, and reported **232 missing** — of which ~209 were combinatorial
 * nonsense it had invented itself (`onb-expense-amount-main`: expense slugs are rent/food/
 * gas/streaming, never account slugs). A preflight whose job is to stop false positives,
 * generating 209 of them on its first run.
 *
 * Templated ids cannot be enumerated without knowing which arguments are valid for which
 * template, and that knowledge lives in the fixture, not here. So they are counted and
 * reported as UNCHECKED rather than guessed at. An honest gap beats an invented finding.
 */
function literalContractIds(): string[] {
  return (Object.values(TID) as unknown[]).filter(
    (v): v is string => typeof v === 'string',
  );
}

function templatedCount(): number {
  return (Object.values(TID) as unknown[]).filter((v) => typeof v === 'function').length;
}

/** Collect every data-testid currently in the DOM. */
async function domIds(page: import('@playwright/test').Page): Promise<Set<string>> {
  return new Set(
    await page.$$eval('[data-testid]', (els) =>
      els.map((e) => e.getAttribute('data-testid') ?? ''),
    ),
  );
}

test.describe('Contract preflight — every test id resolves in the live DOM', () => {
  test('walk the app and report every contract id that never appears', async ({
    page,
    request,
  }) => {
    test.slow();
    const seen = new Set<string>();
    const collect = async () => (await domIds(page)).forEach((id) => seen.add(id));

    // Walk every surface. Each step is defensive: a failure here must not stop the sweep,
    // because the whole point is to report the FULL list rather than die on the first gap.
    const visit = async (label: string, fn: () => Promise<void>) => {
      try {
        await fn();
        await collect();
      } catch {
        test.info().annotations.push({ type: 'unreachable', description: label });
      }
    };

    for (const stop of [
      'welcome',
      'name',
      'income',
      'accounts',
      'expenses',
      'savings',
      'summary',
      'dashboard',
    ] as const) {
      await visit(`onboarding:${stop}`, async () => {
        await completeOnboarding(page, request, stop);
      });
    }

    await visit('expenses tab', async () => {
      await page.getByTestId(TID.tabExpenses).click();
    });
    await visit('insights tab', async () => {
      await page.getByTestId(TID.tabInsights).click();
    });
    await visit('settings', async () => {
      await page.getByTestId(TID.tabDashboard).click();
      await page.getByTestId(TID.toolbarSettings).click();
    });
    await visit('new month', async () => {
      await page.goto(`${BASE_URL}/`);
      await page.getByTestId(TID.newMonthButton).click();
    });

    const unreachable = test
      .info()
      .annotations.filter((a) => a.type === 'unreachable')
      .map((a) => a.description);

    const missing = literalContractIds()
      .filter((id) => !seen.has(id))
      // Deliberately absent from production: R16 gates Dev Tools out of the shipped build.
      .filter((id) => id !== TID.toolbarDevTools);

    expect(
      missing,
      `${missing.length} contract id(s) UNVERIFIED — absent from the DOM, **or on a screen ` +
        `this preflight could not reach**. Those are different verdicts and this run cannot ` +
        `separate them.\n\n` +
        (unreachable.length
          ? `UNREACHABLE SURFACES (${unreachable.length}): ${unreachable.join(', ')}\n` +
            `Ids belonging to these screens are unverified, NOT proven missing. Fix the ` +
            `navigation blocker first, then re-run — the list below will shrink to the real gaps.\n\n`
          : `Every surface was reachable, so these ids are genuinely ABSENT.\n\n`) +
        `A truly missing id surfaces later as a timeout that looks like a broken screen ` +
        `rather than a missing hook, so resolve these before reading any other suite.\n\n` +
        `Ids observed live: ${seen.size}. ` +
        `Templated ids NOT checked: ${templatedCount()} (their valid arguments live in the ` +
        `fixture, not the contract — guessing them invents findings).\n` +
        missing.map((m) => `  - ${m}`).join('\n'),
    ).toEqual([]);
  });
});
