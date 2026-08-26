/**
 * NUMERIC PARITY — priority 1 in DECISIONS.md D6, non-negotiable.
 *
 * Every row of the "Verified numbers" table in Web/Docs/GROUND-TRUTH.md is encoded
 * here as an assertion on **rendered text**, driven through the real UI with the
 * canonical data set (Vlad / 9000 / 1200+2500+450+120 / 25% Priority+Percentage /
 * Main + Emergency Fund + Savings).
 *
 * Rendered text — not internal state — is what parity means. The two `stored`
 * assertions at the bottom are the deliberate exception: they check the *wire*
 * decimal survives (TEAM.md rule 4), and they say so in their titles.
 */
import { expect, test } from '@playwright/test';
import {
  ACCOUNT,
  completeNewMonth,
  completeOnboarding,
  EXPECTED,
  EXPENSE,
  BASE_URL,
  TID,
} from './flows';

test.describe('Numeric parity — onboarding-derived values', () => {
  test('GT row 3: "After expenses" on the onboarding expenses step renders 4,730 RON', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'expenses');
    // fill the four seeded amounts without advancing, so the live summary is observable
    await page.getByTestId(TID.expenseAmount(EXPENSE.food)).fill('1200');
    await page.getByTestId(TID.expenseAmount(EXPENSE.rent)).fill('2500');
    await page.getByTestId(TID.expenseAmount(EXPENSE.gas)).fill('450');
    await page.getByTestId(TID.expenseAmount(EXPENSE.streaming)).fill('120');
    await expect(
      page.getByTestId(TID.onbAfterExpensesValue),
      'GROUND-TRUTH: 9000 − 4270 = "4,730 RON" in the live "After expenses" card',
    ).toHaveText(EXPECTED.available);
  });

  test('GT row 4: savings step shows 25 / "That\'s 1,182 RON/month" / "1,182 RON"', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'savings');
    await expect(
      page.getByTestId(TID.savingsPercentValue),
      'GROUND-TRUTH gap 8: 25 is the shipped DEFAULT, arrived at without any interaction',
    ).toHaveText('25');
    await expect(
      page.getByTestId(TID.savingsPerMonthCaption),
      'GROUND-TRUTH: 0.25 × 4730 = 1182.5 → caption "That\'s 1,182 RON/month"',
    ).toHaveText("That's 1,182 RON/month");
    await expect(
      page.getByTestId(TID.savingsThisMonthValue),
      'GROUND-TRUTH: "This month\'s savings" = "1,182 RON"',
    ).toHaveText(EXPECTED.savings);
  });

  test('GT rows 1,4,5,6,7: first-month summary transfer plan', async ({ page, request }) => {
    await completeOnboarding(page, request, 'summary');
    await expect(
      page.getByTestId(TID.summaryIncomeValue),
      'GROUND-TRUTH row 1: Monthly Income = "9,000 RON"',
    ).toHaveText(EXPECTED.income);
    await expect(
      page.getByTestId(TID.summaryTransferEmergencyValue),
      'GROUND-TRUTH row 4: Emergency Fund transfer = "1,182 RON"',
    ).toHaveText(EXPECTED.savings);
    await expect(
      page.getByTestId(TID.summaryTransferEmergencyProgress),
      'GROUND-TRUTH row 7: emergency progress goes "0% → 4%" in month 1',
    ).toHaveText('0% → 4%');
    await expect(
      page.getByTestId(TID.summaryEmergencyTarget),
      'GROUND-TRUTH row 6: 3 × 9,000 → "Target: 27,000 RON"',
    ).toHaveText(`Target: ${EXPECTED.emergencyTarget}`);
    await expect(
      page.getByTestId(TID.summaryStaysInPrimaryValue),
      'GROUND-TRUTH row 2: "Stays in Primary" = the expense total "4,270 RON"',
    ).toHaveText(EXPECTED.expensesTotal);
    await expect(
      page.getByTestId(TID.summaryRemainingValue),
      'GROUND-TRUTH row 5: 4730 − 1182.5 = 3547.5 → "3,548 RON"',
    ).toHaveText(EXPECTED.personalSpending);
    await expect(
      page.getByTestId(TID.summaryTotal),
      'GROUND-TRUTH: everything must reconcile to "Total: 9,000 RON"',
    ).toHaveText(`Total: ${EXPECTED.income}`);
  });
});

test.describe('Numeric parity — dashboard, month 1', () => {
  test.beforeEach(async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
  });

  test('GT rows 1,2,4,5: Monthly Summary card', async ({ page }) => {
    await expect(
      page.getByTestId(TID.dashIncome),
      'GROUND-TRUTH row 1: Income = "9,000 RON"',
    ).toHaveText(EXPECTED.income);
    await expect(
      page.getByTestId(TID.dashExpenses),
      'GROUND-TRUTH row 2: Expenses render negative and red = "-4,270 RON"',
    ).toHaveText(EXPECTED.expensesNegative);
    await expect(
      page.getByTestId(TID.dashSavings),
      'GROUND-TRUTH row 4: Savings = "1,182 RON" (1182.5 formatted with 0 fraction digits)',
    ).toHaveText(EXPECTED.savings);
    await expect(
      page.getByTestId(TID.dashPersonalSpending),
      'GROUND-TRUTH row 5: Personal Spending = "3,548 RON" (3547.5 → half-even → 3548)',
    ).toHaveText(EXPECTED.personalSpending);
  });

  test('GT rows 6,7: Emergency Fund card shows 4% and 1,182 / 27,000', async ({ page }) => {
    await expect(
      page.getByTestId(TID.dashEfPercent),
      'GROUND-TRUTH row 7: 1182.5 / 27000 = 4.38% → rounded percent "4%"',
    ).toHaveText(EXPECTED.efPercentMonth1);
    await expect(
      page.getByTestId(TID.dashEfAmounts),
      'GROUND-TRUTH rows 4+6: "1,182 RON / 27,000 RON"',
    ).toHaveText(EXPECTED.efAmountsMonth1);
    await expect(
      page.getByTestId(TID.dashEfTargetCaption),
      'GROUND-TRUTH row 6: the 27,000 comes from the 3× income default',
    ).toHaveText('Target: 3× monthly income');
  });

  test('GT row 2: Expenses tab total is 4,270 RON', async ({ page }) => {
    await page.getByTestId(TID.tabExpenses).click();
    await expect(
      page.getByTestId(TID.expensesTotal),
      'GROUND-TRUTH row 2: 1200+2500+450+120 = "4,270 RON"',
    ).toHaveText(EXPECTED.expensesTotal);
  });

  test('Expense breakdown amounts and TRUNCATED percents-of-total, descending', async ({
    page,
  }) => {
    // GROUND-TRUTH §2: percentages truncate — Int((amount/total)*100). Rounding would
    // render Gas 11% and Streaming 3%; the live app renders 10% and 2%.
    const rows = [
      { slug: EXPENSE.rent, amount: '2,500 RON', percent: '58%', exact: '58.55%' },
      { slug: EXPENSE.food, amount: '1,200 RON', percent: '28%', exact: '28.10%' },
      { slug: EXPENSE.gas, amount: '450 RON', percent: '10%', exact: '10.53%' },
      { slug: EXPENSE.streaming, amount: '120 RON', percent: '2%', exact: '2.81%' },
    ];
    for (const r of rows) {
      await expect(
        page.getByTestId(TID.breakdownAmount(r.slug)),
        `GROUND-TRUTH Expense Breakdown: ${r.slug} amount`,
      ).toHaveText(r.amount);
      await expect(
        page.getByTestId(TID.breakdownPercent(r.slug)),
        `GROUND-TRUTH Expense Breakdown: ${r.slug} is ${r.exact} of 4,270 → truncated to "${r.percent}" (rounding is WRONG here)`,
      ).toHaveText(r.percent);
    }
  });
});

/**
 * These values are NOT in the GROUND-TRUTH "Verified numbers" table but are legible in the
 * reference screenshots, so they are ground truth too. Flagged to `main` as spec gaps.
 * Source: reference-screens/08-dashboard.jpg and 09-expenses.jpg.
 */
test.describe('Numeric parity — read off the reference screenshots', () => {
  test.beforeEach(async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
  });

  test('08-dashboard.jpg: Account Balances show Main 4,270 RON and Savings 3,548 RON', async ({
    page,
  }) => {
    await expect(
      page.getByTestId(TID.dashAccountBalance(ACCOUNT.main)),
      'reference 08: the primary account holds exactly the expense total after month 1',
    ).toHaveText(EXPECTED.expensesTotal);
    await expect(
      page.getByTestId(TID.dashAccountBalance(ACCOUNT.savings)),
      'reference 08: month-1 remaining money (3547.5) lands in Savings → "3,548 RON"',
    ).toHaveText(EXPECTED.personalSpending);
  });

  test('09-expenses.jpg: category totals and "1/1 enabled" counters', async ({ page }) => {
    await page.getByTestId(TID.tabExpenses).click();
    const rows = [
      { slug: 'auto-transport', total: '450 RON' },
      { slug: 'subscriptions', total: '120 RON' },
      { slug: 'housing', total: '2,500 RON' },
      { slug: 'food-groceries', total: '1,200 RON' },
    ];
    for (const r of rows) {
      await expect(
        page.getByTestId(TID.categoryTotal(r.slug)),
        `reference 09: category "${r.slug}" total`,
      ).toHaveText(r.total);
      await expect(
        page.getByTestId(TID.categoryCount(r.slug)),
        `reference 09: each seeded category holds one expense → "1/1 enabled"`,
      ).toHaveText('1/1 enabled');
    }
  });
});

test.describe('Numeric parity — New Month flow, month 2', () => {
  test.beforeEach(async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
  });

  test('Step 1 caption repeats last income; step 2 prefills the PERSISTED currentBalance', async ({
    page,
  }) => {
    await page.getByTestId(TID.newMonthButton).click();
    await expect(
      page.getByTestId(TID.newMonthSheet).getByText(`Last month: ${EXPECTED.income}`),
      'GROUND-TRUTH New Month step 1: caption "Last month: 9,000 RON"',
    ).toBeVisible();
    await page.getByTestId(TID.nmNextButton).click();
    // Separator is a literal '.' since Backend pinned the formatter locale to en_US (OQ11).
    // GROUND-TRUTH ⚠️ NewMonthSheet.swift:109 — the prefill is the plain persisted
    // currentBalance, NOT a projection. It equals 3547,5 / 1182,5 here only because
    // month 1 has already been committed. Implementing a projection produces wrong numbers.
    await expect(
      page.getByTestId(TID.nmBalanceField(ACCOUNT.savings)),
      'New Month step 2: Savings prefilled with its persisted currentBalance (3547,5 after month 1)',
    ).toHaveValue('3547.5');
    await expect(
      page.getByTestId(TID.nmBalanceField(ACCOUNT.emergency)),
      'New Month step 2: Emergency prefilled with its persisted currentBalance (1182,5 after month 1)',
    ).toHaveValue('1182.5');
  });

  test('Step 3 transfer plan: +1,182 RON "4% → 8%", +3,548 RON, 4,270 RON stays', async ({
    page,
  }) => {
    await page.getByTestId(TID.newMonthButton).click();
    await page.getByTestId(TID.nmNextButton).click();
    await page.getByTestId(TID.nmNextButton).click();
    await expect(
      page.getByTestId(TID.nmPlanIncome),
      'GROUND-TRUTH row 1: plan Income = "9,000 RON"',
    ).toHaveText(EXPECTED.income);
    await expect(
      page.getByTestId(TID.nmPlanExpenses),
      'GROUND-TRUTH row 2: plan Expenses = "4,270 RON"',
    ).toHaveText(EXPECTED.expensesTotal);
    await expect(
      page.getByTestId(TID.nmPlanAvailable),
      'GROUND-TRUTH row 3: plan Available = "4,730 RON"',
    ).toHaveText(EXPECTED.available);
    // Rows are asserted by ORDINAL POSITION, not by account — one account can appear twice
    // (see the split-at-target vector S27), so an account-keyed lookup is unsound.
    await expect(
      page.getByTestId(TID.nmTransferList).getByTestId(/^nm-transfer-row-/),
      'GROUND-TRUTH: the priority-mode plan has exactly two transfer rows',
    ).toHaveCount(2);
    await expect(
      page.getByTestId(TID.nmTransferName(0)),
      'GROUND-TRUTH: first transfer row is the Emergency Fund',
    ).toHaveText('Emergency Fund');
    await expect(
      page.getByTestId(TID.nmTransferValue(0)),
      'GROUND-TRUTH row 4: Emergency transfer = "+1,182 RON"',
    ).toHaveText(`+${EXPECTED.savings}`);
    await expect(
      page.getByTestId(TID.nmTransferSub(0)),
      'GROUND-TRUTH rows 7+8: emergency progress "4% → 8%"',
    ).toHaveText('4% → 8%');
    await expect(
      page.getByTestId(TID.nmTransferName(1)),
      'GROUND-TRUTH: second transfer row is Savings',
    ).toHaveText('Savings');
    await expect(
      page.getByTestId(TID.nmTransferValue(1)),
      'GROUND-TRUTH row 5: Savings transfer = "+3,548 RON"',
    ).toHaveText(`+${EXPECTED.personalSpending}`);
    await expect(
      page.getByTestId(TID.nmPrimaryValue),
      'GROUND-TRUTH row 2: "4,270 RON" stays in Primary for automatic payments',
    ).toHaveText(EXPECTED.expensesTotal);
  });

  test('GT rows 8,9: after completing month 2 the dashboard shows 8%, 2,365 / 27,000 and Savings 7,095 RON', async ({
    page,
  }) => {
    await completeNewMonth(page);
    await expect(
      page.getByTestId(TID.dashEfPercent),
      'GROUND-TRUTH row 8: 1182.5+1182.5 = 2365; 2365/27000 = 8.76% → "8%"',
    ).toHaveText(EXPECTED.efPercentMonth2);
    await expect(
      page.getByTestId(TID.dashEfAmounts),
      'GROUND-TRUTH row 8: "2,365 RON / 27,000 RON"',
    ).toHaveText(EXPECTED.efAmountsMonth2);
    await expect(
      page.getByTestId(TID.dashAccountBalance(ACCOUNT.savings)),
      'GROUND-TRUTH row 9: 3547.5 × 2 = 7095 → "7,095 RON"',
    ).toHaveText(EXPECTED.savingsBalanceMonth2);
  });
});

test.describe('Wire format — the decimal must survive (not rendered text; TEAM.md rule 4)', () => {
  test('GET /api/state returns 1182.5 / 3547.5 as decimal STRINGS, never JS numbers', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'dashboard');
    const res = await request.get(`${BASE_URL}/api/state`);
    expect(res.ok(), `GET ${BASE_URL}/api/state must succeed`).toBeTruthy();
    const raw = await res.text();
    expect(
      raw,
      'GROUND-TRUTH: display truncates to 1,182 but storage keeps 1182.5 — and it must be a quoted decimal string',
    ).toContain(`"${EXPECTED.storedSavings}"`);
    expect(
      raw,
      'GROUND-TRUTH: personal spending stores 3547.5 as a quoted decimal string',
    ).toContain(`"${EXPECTED.storedPersonalSpending}"`);
  });
});

/**
 * R20 — the best "looks right, isn't" class of bug in the project, and one that a
 * screenshot comparison cannot reliably catch: the truncated percent leaking into the
 * GEOMETRY. At the ground-truth month-2 case (8.759% rendering as 8%) the bar is off by
 * 2.69px at the graded 402px column — enough to fail the ±2px criterion, while looking
 * completely correct to a human and pointing the investigation at CSS instead of at a
 * wrong server field.
 *
 * So this is asserted in the DOM, not in pixels: the label must be the truncated int and
 * the arc must be drawn from the unrounded double, at the same moment.
 */
test.describe('R20 — progress geometry uses the full double, labels use the truncated int', () => {
  const EXPECTED_MONTH_1 = { label: '4%', progress: 1182.5 / 27000 }; // 0.043796…
  const EXPECTED_MONTH_2 = { label: '8%', progress: 2365 / 27000 }; // 0.087592…

  async function assertRing(
    page: import('@playwright/test').Page,
    expected: { label: string; progress: number },
    when: string,
  ) {
    await expect(
      page.getByTestId(TID.dashEfPercent),
      `${when}: the LABEL uses the truncated integer`,
    ).toHaveText(expected.label);

    const arc = page.getByTestId(TID.dashEfRingArc);
    const raw = await arc.getAttribute('data-progress');
    expect(
      raw,
      `${when}: the arc must expose the unrounded progress it was drawn from as data-progress (R20)`,
    ).not.toBeNull();

    const drawn = Number(raw);
    const truncated = Number(expected.label.replace('%', '')) / 100;
    expect(
      drawn,
      `${when}: the arc is drawn from ${drawn}, which is the TRUNCATED ${truncated}. ` +
        `R20: geometry must use the full double ${expected.progress}. This is invisible to the eye ` +
        `but is a 2.69px error on the bar at the graded 402px column — it would be misdiagnosed as a CSS bug.`,
    ).not.toBeCloseTo(truncated, 6);
    expect(drawn, `${when}: arc progress must equal the server's full double`).toBeCloseTo(
      expected.progress,
      6,
    );

    // and the geometry must actually follow that value, not just carry it as an attribute
    const dash = await arc.getAttribute('stroke-dasharray');
    const pathLength = await arc.getAttribute('pathLength');
    expect(
      pathLength,
      `${when}: R20 prescribes pathLength="1" so the dasharray is the progress verbatim`,
    ).toBe('1');
    expect(
      Number(String(dash).trim().split(/\s+/)[0]),
      `${when}: stroke-dasharray must be "<full double> 1", got "${dash}"`,
    ).toBeCloseTo(expected.progress, 6);
  }

  test('month 1: label 4%, arc drawn from 0.043796…', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await assertRing(page, EXPECTED_MONTH_1, 'month 1');
  });

  test('month 2 (the 8.759% case R20 was written for): label 8%, arc drawn from 0.087592…', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'dashboard');
    await completeNewMonth(page);
    await assertRing(page, EXPECTED_MONTH_2, 'month 2');
  });
});
