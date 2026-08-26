import { expect, type APIRequestContext, type Page } from '@playwright/test';
import { fileURLToPath } from 'node:url';
import { ACCOUNT, EXPENSE, TID } from './testids';

/** The canonical test data from GROUND-TRUTH.md. */
export const DATA = {
  name: 'Vlad',
  income: '9000',
  expenses: { food: '1200', rent: '2500', gas: '450', streaming: '120' },
  savingsPercent: 25,
} as const;

/** Every rendered string GROUND-TRUTH pins down. Shared by numbers + content suites. */
export const EXPECTED = {
  income: '9,000 RON',
  expensesTotal: '4,270 RON',
  expensesNegative: '-4,270 RON',
  available: '4,730 RON',
  savings: '1,182 RON',
  personalSpending: '3,548 RON',
  emergencyTarget: '27,000 RON',
  efPercentMonth1: '4%',
  efPercentMonth2: '8%',
  efAmountsMonth1: '1,182 RON / 27,000 RON',
  efAmountsMonth2: '2,365 RON / 27,000 RON',
  savingsBalanceMonth2: '7,095 RON',
  /** wire values — decimal strings, never JS numbers (TEAM.md rule 4) */
  storedSavings: '1182.5',
  storedPersonalSpending: '3547.5',
} as const;

export const BASE_URL = process.env.DIAMERIS_URL ?? 'http://localhost:8080';

/**
 * DECISIONS.md R17 — `currentMonthDisplay` reads the SERVER clock, so the Dashboard
 * large title flakes at month boundaries unless the date is pinned. The harness pins it
 * two ways: `X-Diameris-Now` on every request (server side, must be honoured by Backend
 * in dev builds) and Playwright's clock API (browser side, for any client-rendered date).
 *
 * The reference screenshots were taken in August 2026, so that is the pinned month.
 */
export const FIXED_NOW = process.env.PARITY_NOW ?? '2026-08-06T12:00:00.000Z';

/** The month+year string the Dashboard title must render for FIXED_NOW, in EN. */
export const FIXED_MONTH_DISPLAY = new Intl.DateTimeFormat('en-US', {
  month: 'long',
  year: 'numeric',
  timeZone: 'UTC',
}).format(new Date(FIXED_NOW));

/** Where captures and REPORT.md live. */
export const OUTPUT_DIR = fileURLToPath(new URL('../output/', import.meta.url));

/**
 * Wipe the store via the dev-tools endpoint and land on a fresh onboarding.
 * Fails loudly and specifically if the server is not answering.
 */
export async function resetAndOpen(page: Page, request: APIRequestContext): Promise<void> {
  const res = await request.post(`${BASE_URL}/api/reset`).catch((e: Error) => {
    throw new Error(
      `Cannot reach the Diameris web server at ${BASE_URL} (POST /api/reset failed: ${e.message}).\n` +
        `Start it with:  ./Web/run.sh`,
    );
  });
  if (!res.ok()) {
    throw new Error(
      `POST ${BASE_URL}/api/reset returned ${res.status()} ${res.statusText()}.\n` +
        `The reset endpoint is required by the parity harness (see Web/Docs/DECISIONS.md D4).`,
    );
  }
  await page.goto(`${BASE_URL}/`);
  await expect(
    page.getByTestId(TID.onbWelcome),
    'after POST /api/reset the app must land on onboarding step 1 (Welcome)',
  ).toBeVisible();
}

async function fillAmount(page: Page, testId: string, value: string): Promise<void> {
  const field = page.getByTestId(testId);
  await expect(field, `amount field [data-testid="${testId}"] must exist`).toBeVisible();
  await field.fill(value);
}

/** Onboarding step 1 -> 2. */
export async function stepWelcome(page: Page): Promise<void> {
  await page.getByRole('button', { name: "Let's Go" }).click();
}

/** Onboarding step 2 (Name) -> 3. */
export async function stepName(page: Page, name = DATA.name): Promise<void> {
  await expect(page.getByTestId(TID.onbName)).toBeVisible();
  const cont = page.getByRole('button', { name: 'Continue' });
  await expect(cont, 'Continue must be disabled while the name field is empty').toBeDisabled();
  await page.getByTestId(TID.nameField).fill(name);
  await expect(cont, 'Continue must enable once a name is entered').toBeEnabled();
  await cont.click();
}

/** Onboarding step 3 (Income) -> 4. */
export async function stepIncome(page: Page, income = DATA.income): Promise<void> {
  await expect(page.getByTestId(TID.onbIncome)).toBeVisible();
  await fillAmount(page, TID.incomeField, income);
  await page.getByRole('button', { name: 'Continue' }).click();
}

/** Onboarding step 4 (Accounts) -> 5. Adds Emergency Fund + Savings. */
export async function stepAccounts(page: Page): Promise<void> {
  await expect(page.getByTestId(TID.onbAccounts)).toBeVisible();
  await page.getByTestId(TID.addAccountEmergency).click();
  await page.getByTestId(TID.addAccountSavings).click();
  await page.getByRole('button', { name: 'Continue' }).click();
}

/** Onboarding step 5 (Expenses) -> 6. */
export async function stepExpenses(page: Page): Promise<void> {
  await expect(page.getByTestId(TID.onbExpenses)).toBeVisible();
  await fillAmount(page, TID.expenseAmount(EXPENSE.food), DATA.expenses.food);
  await fillAmount(page, TID.expenseAmount(EXPENSE.rent), DATA.expenses.rent);
  await fillAmount(page, TID.expenseAmount(EXPENSE.gas), DATA.expenses.gas);
  await fillAmount(page, TID.expenseAmount(EXPENSE.streaming), DATA.expenses.streaming);
  await page.getByRole('button', { name: 'Continue' }).click();
}

/**
 * Onboarding step 6 (Savings) -> 7.
 *
 * GROUND-TRUTH gap 8: **25% / Priority / Percentage are the shipped DEFAULTS**. This step
 * must NOT click them — clicking would mask a wrong default by setting the right one on the
 * way past. It asserts the arrived-at state, then continues.
 *
 * ⚠️ CORRECTED 2026-08-06: this asserted `aria-checked="true"`. The control is
 * `role="tablist"` / `role="tab"`, and **`aria-checked` is not permitted on `role="tab"`** —
 * it belongs to `radio`/`checkbox`. So the assertion demanded the client emit INVALID ARIA,
 * and it was the single largest cause on the board (~35 failures) — all of them my contract,
 * not the client. Exactly the rule I set when I had pinned `Lunar` on a control iOS renders
 * in English: a test that demands the wrong value pushes the implementer to break the thing
 * it exists to protect.
 */
export async function stepSavings(page: Page): Promise<void> {
  await expect(page.getByTestId(TID.onbSavings)).toBeVisible();
  await expect(
    page.getByTestId(TID.strategyPriority),
    'GROUND-TRUTH: Priority is the DEFAULT allocation strategy — it must already be selected',
    // `aria-selected`, NOT `aria-checked`. The control is `role="tablist"` / `role="tab"`
    // (`primitives.tsx` SegmentedControl), where `aria-selected` is the correct and
    // `aria-checked` an INVALID attribute — it belongs to `radio`/`checkbox`. Asserting
    // `aria-checked` demanded the client emit invalid ARIA, and the failure inside
    // `stepSavings` cascaded into ~35 results plus six unreachable surfaces. This is the
    // Reviewer's own rule turned on its own harness: a test that demands the wrong value is
    // worse than no test, because it pushes the implementer to break parity to go green.
  ).toHaveAttribute('aria-selected', 'true');
  await expect(
    page.getByTestId(TID.modePercentage),
    'GROUND-TRUTH: Percentage is the DEFAULT savings mode — it must already be selected',
    // `aria-selected`, NOT `aria-checked`. The control is `role="tablist"` / `role="tab"`
    // (`primitives.tsx` SegmentedControl), where `aria-selected` is the correct and
    // `aria-checked` an INVALID attribute — it belongs to `radio`/`checkbox`. Asserting
    // `aria-checked` demanded the client emit invalid ARIA, and the failure inside
    // `stepSavings` cascaded into ~35 results plus six unreachable surfaces. This is the
    // Reviewer's own rule turned on its own harness: a test that demands the wrong value is
    // worse than no test, because it pushes the implementer to break parity to go green.
  ).toHaveAttribute('aria-selected', 'true');
  await expect(
    page.getByTestId(TID.savingsPercentValue),
    'GROUND-TRUTH: 25 is the DEFAULT savings rate — it must already be set',
  ).toHaveText('25');
  await page.getByRole('button', { name: 'Continue' }).click();
}

/** Onboarding step 7 (First-month summary) -> main app. */
export async function stepSummary(page: Page): Promise<void> {
  await expect(page.getByTestId(TID.onbSummary)).toBeVisible();
  await page.getByRole('button', { name: 'Start Using Diameris' }).click();
  await expect(page.getByTestId(TID.dashboard), 'onboarding must finish on the Dashboard').toBeVisible();
}

/**
 * Full onboarding with the GROUND-TRUTH data set, stopping at `stopAt`
 * (the screen that should be on-screen when this returns).
 */
export type OnboardingStop =
  | 'welcome'
  | 'name'
  | 'income'
  | 'accounts'
  | 'expenses'
  | 'savings'
  | 'summary'
  | 'dashboard';

export async function completeOnboarding(
  page: Page,
  request: APIRequestContext,
  stopAt: OnboardingStop = 'dashboard',
): Promise<void> {
  await resetAndOpen(page, request);
  if (stopAt === 'welcome') return;
  await stepWelcome(page);
  if (stopAt === 'name') return;
  await stepName(page);
  if (stopAt === 'income') return;
  await stepIncome(page);
  if (stopAt === 'accounts') return;
  await stepAccounts(page);
  if (stopAt === 'expenses') return;
  await stepExpenses(page);
  if (stopAt === 'savings') return;
  await stepSavings(page);
  if (stopAt === 'summary') return;
  await stepSummary(page);
}

/** Open the New Month modal and walk to a given step (1..3), accepting prefilled values. */
export async function openNewMonth(page: Page, stopAtStep: 1 | 2 | 3 = 3): Promise<void> {
  await page.getByTestId(TID.newMonthButton).click();
  await expect(page.getByTestId(TID.newMonthSheet)).toBeVisible();
  if (stopAtStep === 1) return;
  await page.getByTestId(TID.nmNextButton).click(); // step 1 -> 2, keep prefilled income
  if (stopAtStep === 2) return;
  await page.getByTestId(TID.nmNextButton).click(); // step 2 -> 3, keep projected balances
  await expect(page.getByTestId(TID.nmPlanAvailable)).toBeVisible();
}

/** Complete the New Month flow (month 2 applied). */
export async function completeNewMonth(page: Page): Promise<void> {
  await openNewMonth(page, 3);
  await page.getByTestId(TID.nmDoneButton).click();
  await expect(page.getByTestId(TID.dashboard), 'New Month must return to the Dashboard').toBeVisible();
}

export { ACCOUNT, EXPENSE, TID };
