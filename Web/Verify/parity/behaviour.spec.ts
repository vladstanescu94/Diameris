/**
 * BEHAVIOURAL PARITY — priority 3 in DECISIONS.md D6 ("same navigation, same modals,
 * same enable/disable rules, same defaults"). This axis had no suite until now.
 *
 * The headline case is GROUND-TRUTH gap 9, resolved 2026-08-06 from source: the two
 * "Skip for now" buttons look identical and do DIFFERENT things. Both advance exactly one
 * step — neither jumps to the summary — but:
 *
 *   - Expenses skip  → zeroes all four amounts, persists ZERO Expense rows,
 *                      so availableIncome == gross income.
 *   - Savings skip   → does NOT zero. Resets to a fresh SavingsAllocationEntry
 *                      (25% / priority / percentage) and a row IS persisted.
 *
 * Both are "discard my edits"; neither is "opt out". An implementation that treats skip
 * uniformly as "set to zero" gets the savings case wrong and silently saves nothing.
 */
import { expect, test } from '@playwright/test';
import { completeOnboarding, stepSavings, stepSummary, TID } from './flows';

test.describe('Behaviour: "Skip for now" on the Expenses step', () => {
  test('advances exactly one step — to Savings, not to the summary', async ({ page, request }) => {
    await completeOnboarding(page, request, 'expenses');
    await page.getByRole('button', { name: 'Skip for now' }).click();
    await expect(
      page.getByTestId(TID.onbSavings),
      'GROUND-TRUTH gap 9: the Expenses skip advances ONE step, landing on Savings',
    ).toBeVisible();
    await expect(
      page.getByTestId(TID.onbSummary),
      'GROUND-TRUTH gap 9: skip must NOT jump to the first-month summary',
    ).toHaveCount(0);
  });

  test('persists no expenses, so availableIncome equals gross income (9,000 → savings 2,250)', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'expenses');
    await page.getByRole('button', { name: 'Skip for now' }).click();
    await stepSavings(page);
    await stepSummary(page);

    await expect(
      page.getByTestId(TID.dashExpenses),
      'golden vector S22: skipping expenses persists ZERO expense rows, so the Dashboard total is 0',
    ).toHaveText('0 RON');
    await expect(
      page.getByTestId(TID.dashSavings),
      'golden vector S22: with no expenses, availableIncome == 9,000 and 25% of that is "2,250 RON" — NOT the 1,182 the seeded expenses would produce',
    ).toHaveText('2,250 RON');
    await expect(
      page.getByTestId(TID.dashPersonalSpending),
      'golden vector S22: 9000 − 2250 = "6,750 RON"',
    ).toHaveText('6,750 RON');
  });
});

test.describe('Behaviour: "Skip for now" on the Savings step', () => {
  test('advances exactly one step — to the summary', async ({ page, request }) => {
    await completeOnboarding(page, request, 'savings');
    await page.getByRole('button', { name: 'Skip for now' }).click();
    await expect(
      page.getByTestId(TID.onbSummary),
      'GROUND-TRUTH gap 9: the Savings skip advances one step, to the first-month summary',
    ).toBeVisible();
  });

  test('does NOT zero — a fresh 25% priority/percentage entry is still persisted', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'savings');
    await page.getByRole('button', { name: 'Skip for now' }).click();
    await stepSummary(page);

    await expect(
      page.getByTestId(TID.dashSavings),
      'golden vector S23: the Savings skip resets to a FRESH SavingsAllocationEntry (25%, priority, percentage) and persists it — so savings is still "1,182 RON". A 0 here means skip was implemented as "zero", which is the Expenses-step behaviour, not this one.',
    ).toHaveText('1,182 RON');
    await expect(
      page.getByTestId(TID.dashEfPercent),
      'golden vector S23: the emergency fund still receives its 1,182.5, so the ring reads 4%',
    ).toHaveText('4%');
  });
});

test.describe('Behaviour: the two skips are NOT interchangeable', () => {
  test('skipping expenses and skipping savings produce different savings figures', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'expenses');
    await page.getByRole('button', { name: 'Skip for now' }).click();
    await stepSavings(page);
    await stepSummary(page);
    const afterExpensesSkip = await page.getByTestId(TID.dashSavings).textContent();

    await completeOnboarding(page, request, 'savings');
    await page.getByRole('button', { name: 'Skip for now' }).click();
    await stepSummary(page);
    const afterSavingsSkip = await page.getByTestId(TID.dashSavings).textContent();

    expect(
      afterExpensesSkip,
      'GROUND-TRUTH gap 9: the two "Skip for now" buttons must NOT behave identically — ' +
        'skipping expenses gives 2,250 RON (no expenses subtracted), skipping savings gives ' +
        '1,182 RON (defaults still applied). Identical results mean one of them is wrong.',
    ).not.toBe(afterSavingsSkip);
    expect(afterExpensesSkip?.trim()).toBe('2,250 RON');
    expect(afterSavingsSkip?.trim()).toBe('1,182 RON');
  });
});
