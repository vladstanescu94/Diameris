/**
 * CONTENT PARITY — priority 2 in DECISIONS.md D6.
 *
 * For every screen described in Web/Docs/GROUND-TRUTH.md, assert that every
 * user-visible string listed there is actually rendered. One `test.describe`
 * per screen, so a failure names the screen.
 *
 * Assertions are SOFT on purpose: one run reports every missing string on a
 * screen rather than stopping at the first, which is what makes the output
 * usable as a to-do list for Frontend.
 */
import { expect, test, type Locator, type Page } from '@playwright/test';
import { ACCOUNT, completeOnboarding, EXPENSE, FIXED_MONTH_DISPLAY, FIXED_NOW, TID } from './flows';

/** Assert each string is visible somewhere on the page. Soft → all failures reported. */
async function expectStrings(page: Page | Locator, screen: string, strings: string[]): Promise<void> {
  for (const s of strings) {
    await expect
      .soft(page.getByText(s, { exact: false }).first(), `[${screen}] missing string: "${s}"`)
      .toBeVisible();
  }
}

/**
 * GROUND-TRUTH: 7 onboarding screens, 5 dots, dots shown only on screens 2–6.
 * `activeIndex === null` means this screen must show no indicator at all.
 */
async function expectProgressDots(
  page: Page,
  screen: string,
  activeIndex: number | null,
): Promise<void> {
  const dots = page.getByTestId(TID.onbProgressDot);
  if (activeIndex === null) {
    await expect
      .soft(dots, `[${screen}] must show NO progress dots (dots cover screens 2–6 only)`)
      .toHaveCount(0);
    return;
  }
  await expect
    .soft(dots, `[${screen}] the indicator has exactly 5 dots, one per screen 2–6`)
    .toHaveCount(5);
  await expect
    .soft(
      dots.nth(activeIndex),
      `[${screen}] dot ${activeIndex + 1} of 5 must be the active one`,
    )
    .toHaveAttribute('data-active', 'true');
}

/** Assert each accessible-name button exists. */
async function expectButtons(page: Page | Locator, screen: string, names: string[]): Promise<void> {
  for (const n of names) {
    await expect
      .soft(page.getByRole('button', { name: n }).first(), `[${screen}] missing button: "${n}"`)
      .toBeVisible();
  }
}

// ───────────────────────────── Onboarding ─────────────────────────────

test.describe('Screen: Onboarding 1 — Welcome', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'welcome');
    await expectStrings(page, 'onboarding-welcome', [
      'Take control of your money',
      "In the next few minutes, we'll build your personalized transfer plan — so payday becomes effortless.",
      'Set savings goals that fill automatically',
      'Know exactly where to transfer your money',
      'Watch your progress grow',
    ]);
    await expectButtons(page, 'onboarding-welcome', ["Let's Go"]);
    await expectProgressDots(page, 'onboarding-welcome', null);
  });
});

test.describe('Screen: Onboarding 2 — Name', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'name');
    await expectStrings(page, 'onboarding-name', [
      "First, let's get acquainted",
      'What should we call you?',
    ]);
    await expect
      .soft(
        page.getByPlaceholder('Your name'),
        '[onboarding-name] text field placeholder "Your name" missing',
      )
      .toBeVisible();
    await expectButtons(page, 'onboarding-name', ['Continue']);
    await expectProgressDots(page, 'onboarding-name', 0);
  });
});

test.describe('Screen: Onboarding 3 — Income', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'income');
    await expectStrings(page, 'onboarding-income', [
      'Nice to meet you, Vlad!',
      'How much lands in your account each month after taxes?',
      'Monthly net income',
      'RON',
      "This is your starting point — we'll help you decide where every unit goes.",
    ]);
    await expectButtons(page, 'onboarding-income', ['Continue']);
    await expectProgressDots(page, 'onboarding-income', 1);
  });
});

test.describe('Screen: Onboarding 4 — Accounts', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'accounts');
    await expectStrings(page, 'onboarding-accounts', [
      'Where does your money live?',
      'Set up your accounts. We recommend an emergency fund and savings account.',
      'Your Accounts',
      'Main Account',
      'Primary',
      'Add Another Account',
      'Recommended',
      'Emergency Fund',
      'Protects you from unexpected expenses. Recommended: 3-6 months of income.',
      'Savings Account',
      'Build wealth over time. After emergency fund is full, savings go here.',
      'Your primary account is where your salary lands',
    ]);
    await expectButtons(page, 'onboarding-accounts', ['Add', 'Continue']);
    // GROUND-TRUTH: verified against 04-onboarding-accounts.jpg — 3rd of 5 dots active.
    await expectProgressDots(page, 'onboarding-accounts', 2);
    await expect
      .soft(
        page.getByTestId(TID.addAccountEmergency),
        '[onboarding-accounts] Emergency Fund add-card accessibility label must include the 27,000 RON target',
      )
      .toHaveAttribute('aria-label', /27,000 RON/);
  });
});

test.describe('Screen: Onboarding 5 — Expenses', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'expenses');
    await expectStrings(page, 'onboarding-expenses', [
      'Where does your money go?',
      "A quick look at your main expenses. Don't worry about being exact — estimates are fine.",
      'Food',
      'Rent',
      'Gas',
      'Streaming',
      'From:',
      'Main',
      'After expenses',
      'available for your goals',
      'By default, expenses are paid from your main account',
    ]);
    await expectButtons(page, 'onboarding-expenses', ['Continue', 'Skip for now']);
    await expectProgressDots(page, 'onboarding-expenses', 3);
  });
});

test.describe('Screen: Onboarding 6 — Savings', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'savings');
    await expectStrings(page, 'onboarding-savings', [
      'How much do you want to save?',
      'Savings are calculated from your income after expenses.',
      'Allocation Strategy',
      'Priority',
      'Split',
      'Emergency fund fills first, then savings',
      'Monthly Savings',
      'Percentage',
      'Fixed Amount',
      '%',
      "That's 1,182 RON/month",
      '25% recommended',
      '5%',
      '50%',
      'Great savings rate!',
      'Savings Boost',
      'Triple your savings temporarily',
      'How your savings are distributed',
      'Emergency fund fills first until target reached',
      'Remaining savings go to your savings account',
      "This month's savings",
      'going to your accounts',
    ]);
    await expectButtons(page, 'onboarding-savings', ['Continue', 'Skip for now']);
    await expectProgressDots(page, 'onboarding-savings', 4);
  });
});

test.describe('Screen: Onboarding 7 — First-month summary', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'summary');
    await expectStrings(page, 'onboarding-summary', [
      'Your First Month',
      "Here's your personalized transfer plan, Vlad!",
      'Monthly Income',
      'Your Transfers',
      'Emergency Fund',
      '0% → 4%',
      'Target: 27,000 RON',
      'Stays in Primary',
      'For automatic bill payments',
      'Remaining Money',
      'Available after savings',
      'Where should this go?',
      'Primary Savings',
      'Add to your savings for future goals',
      'Keep in Primary',
      'Leave in your main account',
      'Total: 9,000 RON',
      'All accounted for!',
      'Tip: Do these transfers right after payday for best results!',
    ]);
    await expectButtons(page, 'onboarding-summary', ['Start Using Diameris']);
    // GROUND-TRUTH gap 5, resolved 2026-08-06 (OnboardingViewModel.swift:29): the
    // .primarySavings destination is the DEFAULT and is inserted at index 0, so the
    // Primary Savings card is both first and already highlighted. Ref 08's Savings
    // balance of 3,548 reflects that default, not a user choice.
    await expect
      .soft(
        page.getByTestId(TID.summaryRemainingChoiceSavings),
        '[onboarding-summary] "Primary Savings" is the DEFAULT remaining-money destination and must arrive preselected — no tap required',
      )
      .toHaveAttribute('data-selected', 'true');
    await expect
      .soft(
        page.getByTestId(TID.summaryRemainingChoicePrimary),
        '[onboarding-summary] "Keep in Primary" must NOT be selected by default',
      )
      .not.toHaveAttribute('data-selected', 'true');
    await expectProgressDots(page, 'onboarding-summary', null);
  });
});

// ───────────────────────────── Main app ─────────────────────────────

test.describe('Screen: App chrome — tab bar and toolbar', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await expectStrings(page, 'app-chrome', ['Dashboard', 'Expenses', 'Insights', 'New Month']);
    for (const [label, tid] of [
      ['Dashboard tab', TID.tabDashboard],
      ['Expenses tab', TID.tabExpenses],
      ['Insights tab', TID.tabInsights],
      ['New Month accessory', TID.newMonthButton],
      ['Settings toolbar item', TID.toolbarSettings],
    ] as const) {
      await expect.soft(page.getByTestId(tid), `[app-chrome] missing ${label}`).toBeVisible();
    }

    // R16 — Dev Tools is `#if DEBUG` on iOS, so it is not shipped parity surface. Assert
    // its ABSENCE. Asserting presence would have forced a debug affordance into the
    // production build purely to satisfy a parity test.
    await expect
      .soft(
        page.getByTestId(TID.toolbarDevTools),
        '[app-chrome] the Developer Tools button must NOT exist in a production build (R16 — ' +
          'it is #if DEBUG on iOS). If this is present, a debug-only affordance has shipped.',
      )
      .toHaveCount(0);
  });
});

test.describe('Screen: Dashboard', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await page.clock.setFixedTime(new Date(FIXED_NOW));
    await completeOnboarding(page, request, 'dashboard');
    await expect
      .soft(
        page.getByTestId(TID.dashTitle),
        `[dashboard] large title is the current month + year. R17: the clock is pinned to ` +
          `${FIXED_NOW} (X-Diameris-Now header + browser clock), so this must be ` +
          `"${FIXED_MONTH_DISPLAY}" on every machine, every day.`,
      )
      .toHaveText(FIXED_MONTH_DISPLAY);
    await expectStrings(page, 'dashboard', [
      'Monthly Summary',
      'Income',
      'Expenses',
      'Savings',
      'Personal Spending',
      'Emergency Fund',
      'Target: 3× monthly income',
      'Account Balances',
      'Main Account',
      'Primary',
      'Expense Breakdown',
      'Rent',
      'Food',
      'Gas',
      'Streaming',
    ]);
  });
});

test.describe('Screen: Expenses', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.tabExpenses).click();
    await expectStrings(page, 'expenses', [
      'Expenses',
      'Total Monthly Expenses',
      'Monthly',
      'Annual',
      'Auto/Transport',
      'Subscriptions',
      'Housing',
      'Food/Groceries',
      'enabled',
    ]);
    await expect
      .soft(page.getByTestId(TID.addExpenseButton), '[expenses] missing "+" Add Expense toolbar item')
      .toBeVisible();
    await expect
      .soft(page.getByTestId(TID.expensesOverflowMenu), '[expenses] missing "…" overflow menu')
      .toBeVisible();
  });
});

test.describe('Screen: Expenses — category expanded (accordion)', () => {
  test('expanding Housing reveals its rows inline, not a new screen', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.tabExpenses).click();
    await page.getByTestId(TID.categoryRow('housing')).click();
    await expect
      .soft(
        page.getByTestId(TID.expensesScreen),
        '[expenses-category-expanded] category rows must expand inline — the Expenses screen must still be mounted',
      )
      .toBeVisible();
    await expectStrings(page, 'expenses-category-expanded', ['Housing', 'Rent']);
    await expect
      .soft(
        page.getByTestId(TID.categoryRow('housing')).getByRole('switch').first(),
        '[expenses-category-expanded] each revealed expense needs an enable/disable toggle',
      )
      .toBeVisible();
  });
});

test.describe('Screen: Add Expense sheet', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.tabExpenses).click();
    await page.getByTestId(TID.addExpenseButton).click();
    const sheet = page.getByTestId(TID.addExpenseSheet);
    await expect.soft(sheet, '[add-expense-sheet] sheet did not present').toBeVisible();
    await expectStrings(sheet, 'add-expense-sheet', [
      'Add Expense',
      'Details',
      'Name',
      'RON',
      'Monthly',
      'Annual',
      'Category',
      'None',
      'New Category...',
      'Account',
      'Pay From',
      'Primary',
      'Choose which account this expense is paid from.',
      'Icon',
    ]);
    await expectButtons(sheet, 'add-expense-sheet', ['Cancel', 'Save']);
    await expect
      .soft(
        sheet.getByRole('button', { name: 'Save' }),
        '[add-expense-sheet] Save must be disabled until the form is valid',
      )
      .toBeDisabled();
    // CORRECTED 2026-08-06: this grid is **37** symbols, not 18. The server was returning
    // exactly the first 18, truncating at `creditcard.fill` — which is precisely where the
    // original miscount stopped, so an 18-assertion would have ratified the bug. The full
    // list ends at `sparkles`; assert the count AND the tail, so a partial fix cannot pass.
    const expenseIcons = sheet.getByTestId(TID.addExpenseIconGrid).getByRole('button');
    await expect
      .soft(
        expenseIcons,
        '[add-expense-sheet] icon grid must hold exactly 37 symbols. Exactly 18 means the server is still truncating at creditcard.fill (the original miscount).',
      )
      .toHaveCount(37);
    await expect
      .soft(
        expenseIcons.last(),
        '[add-expense-sheet] the icon list must END at `sparkles` — a truncated list can have the right prefix and still be wrong',
      )
      .toHaveAttribute('data-symbol', 'sparkles');
  });
});

test.describe('Screen: Expenses — "…" overflow menu', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.tabExpenses).click();
    await page.getByTestId(TID.expensesOverflowMenu).click();
    for (const item of ['Expand All', 'Collapse All', 'Manage Categories']) {
      await expect
        .soft(
          page.getByRole('menuitem', { name: item }),
          `[expenses-overflow-menu] missing item: "${item}"`,
        )
        .toBeVisible();
    }
  });
});

test.describe('Screen: Manage Categories sheet', () => {
  test('all 8 default categories are listed, even those with no expenses', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.tabExpenses).click();
    await page.getByTestId(TID.expensesOverflowMenu).click();
    await page.getByRole('menuitem', { name: 'Manage Categories' }).click();
    const sheet = page.getByTestId(TID.manageCategoriesSheet);
    await expect.soft(sheet, '[manage-categories] sheet did not present').toBeVisible();
    await expectStrings(sheet, 'manage-categories', [
      'Categories',
      'Default Categories',
      'Default categories cannot be deleted.',
      // GROUND-TRUTH / DECISIONS R6: one canonical set of 8, in this order.
      'Auto/Transport',
      'Subscriptions',
      'Lifestyle',
      'Housing',
      'Pets',
      'Health/Fitness',
      'Food/Groceries',
      'Entertainment',
      'Default',
    ]);
    await expectButtons(sheet, 'manage-categories', ['Done']);
  });
});

test.describe('Screen: New Category sheet', () => {
  test('all GROUND-TRUTH strings present, and its icon grid is the SHORT 12-symbol set (vs 37)', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.tabExpenses).click();
    await page.getByTestId(TID.expensesOverflowMenu).click();
    await page.getByRole('menuitem', { name: 'Manage Categories' }).click();
    await page
      .getByTestId(TID.manageCategoriesSheet)
      .getByRole('button', { name: /^\+$|Add Category/ })
      .click();
    const sheet = page.getByTestId(TID.newCategorySheet);
    await expect.soft(sheet, '[new-category-sheet] sheet did not present').toBeVisible();
    await expectStrings(sheet, 'new-category-sheet', [
      'New Category',
      'Category Name',
      'Icon',
      'Color',
      'Preview',
      'Category Name',
    ]);
    await expect
      .soft(
        sheet.getByPlaceholder('Name'),
        '[new-category-sheet] category name placeholder "Name" missing',
      )
      .toBeVisible();
    await expectButtons(sheet, 'new-category-sheet', ['Cancel', 'Add']);
    await expect
      .soft(
        sheet.getByRole('button', { name: 'Add' }),
        '[new-category-sheet] Add must be disabled until the category is named',
      )
      .toBeDisabled();
    // GROUND-TRUTH ⚠️ this grid is 12 symbols, NOT the 37 in the Add Expense sheet.
    await expect
      .soft(
        sheet.getByTestId(TID.newCategoryIconGrid).getByRole('button'),
        '[new-category-sheet] icon grid must hold exactly 12 symbols (the Add Expense grid has 37 — do not share one list)',
      )
      .toHaveCount(12);
    await expect
      .soft(
        sheet.getByTestId(TID.newCategoryColorSwatches).getByRole('button'),
        '[new-category-sheet] colour picker must hold exactly 10 swatches',
      )
      .toHaveCount(10);
  });
});

// NOTE: the "Screen: Developer Tools sheet" describe was REMOVED 2026-08-06. Dev Tools is
// `#if DEBUG` on iOS and gated behind `import.meta.env.DEV` on the web, so under R16 it is
// not shipped parity surface. Its absence is asserted in the app-chrome test instead.

test.describe('Screen: Insights', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.tabInsights).click();
    await expectStrings(page, 'insights', ['Insights', 'Coming soon']);
  });
});

test.describe('Screen: Settings sheet', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.toolbarSettings).click();
    const sheet = page.getByTestId(TID.settingsSheet);
    await expect.soft(sheet, '[settings] sheet did not present').toBeVisible();
    await expectStrings(sheet, 'settings', [
      'Settings',
      'Profile',
      'Name',
      'Currency',
      'Romanian Leu (RON)',
      'Savings',
      'Priority',
      'Split',
      'Percentage',
      'Fixed Amount',
      'Savings Rate',
      '25%',
      'Savings Boost',
      'Savings are calculated from income after expenses.',
      'Accounts',
      'Main Account',
      'Emergency Fund',
    ]);
    // GROUND-TRUTH gap 7, resolved: this subtitle is 2–3 SEPARATE Text views in an
    // HStack(spacing: Spacing.xs), each its own colour — the apparent double space was a
    // flattened accessibility label, not rendered text. So assert per element, and assert
    // that no single node carries a doubled space.
    const emergencyRow = sheet.getByTestId(TID.settingsAccountRow(ACCOUNT.emergency));
    const parts = emergencyRow.getByTestId(TID.settingsAccountSubtitlePart);

    // The server still serves the flattened, double-spaced string today, so the tolerant
    // match is the one that must pass. The strict per-element check activates AUTOMATICALLY
    // the moment Backend starts serving the parts — no edit needed here, and no window in
    // which the doubled space silently becomes acceptable.
    if ((await parts.count()) > 0) {
      await expect
        .soft(parts, '[settings] subtitle is an HStack of 2–3 separately-coloured Text views')
        .toHaveCount(2);
      await expect
        .soft(parts.nth(0), '[settings] first subtitle part is the account type')
        .toHaveText('Emergency');
      await expect
        .soft(parts.nth(1), '[settings] second subtitle part is the multiplier')
        .toHaveText('• 3× income');
      await expect
        .soft(
          emergencyRow,
          '[settings] once the parts are served, no node may contain a doubled space — the 8pt gap is layout, not whitespace',
        )
        .not.toContainText('  ');
    } else {
      await expect
        .soft(
          sheet.getByText(/Emergency\s+•\s+3×\s+income/).first(),
          '[settings] Emergency row subtitle missing. NOTE: matched whitespace-tolerantly because the server still flattens this into one double-spaced string; Backend is splitting it into 2–3 elements, at which point this test tightens on its own.',
        )
        .toBeVisible();
    }
    await expectButtons(sheet, 'settings', ['Cancel', 'Save']);
  });
});

test.describe('Screen: Settings — R36 shadowed displayName', () => {
  test('.primary reads "Primary Account" in Settings but "Keep in Primary" in onboarding', async ({
    page,
    request,
  }) => {
    // R36: SettingsSheet.swift privately SHADOWS RemainingMoneyDestination.displayName, so
    // one enum case carries two labels. Both are translated, both ship. A uniform
    // implementation is wrong on one screen — same shape as R30's completion strings.
    await completeOnboarding(page, request, 'summary');
    await expect
      .soft(
        page.getByTestId(TID.summaryRemainingChoicePrimary),
        '[onboarding-summary] .primary reads "Keep in Primary" here',
      )
      .toContainText('Keep in Primary');

    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.toolbarSettings).click();
    const sheet = page.getByTestId(TID.settingsSheet);
    await expect
      .soft(
        sheet,
        '[settings] the SAME enum case reads "Primary Account" here, because SettingsSheet ' +
          'shadows displayName. Do not unify the two labels.',
      )
      .toContainText('Primary Account');
    await expect
      .soft(sheet, '[settings] must NOT use the onboarding label')
      .not.toContainText('Keep in Primary');
  });
});

test.describe('Screen: Settings — Split allocation mode', () => {
  test('Split reveals two independent per-account blocks with the measured defaults', async ({
    page,
    request,
  }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.toolbarSettings).click();
    const sheet = page.getByTestId(TID.settingsSheet);
    await page.getByTestId(TID.settingsStrategySplit).click();

    await expectStrings(sheet, 'settings-split', [
      'Fixed amounts to each account every month',
      'Emergency',
      'Savings',
      'Percentage',
      'Fixed Amount',
      'Total Monthly',
      'Savings are calculated from income after expenses.',
    ]);

    // GROUND-TRUTH: on first switch BOTH sides are Fixed at 0, so the total is 0 RON.
    await expect
      .soft(
        page.getByTestId(TID.settingsSplitTotalMonthly),
        '[settings-split] on first switching to Split both sides default to Fixed Amount at 0, so Total Monthly must be "0 RON" — not the 1,182 carried over from Priority',
      )
      .toHaveText('0 RON');

    // Emergency 10% only -> 0.10 x 4730 = 473 exactly. Proves the denominator is
    // availableIncome (4,730), not gross income (9,000 -> would give 900).
    await page.getByTestId(TID.settingsSplitModePercentage('emergency')).click();
    await expect
      .soft(
        page.getByTestId(TID.settingsSplitRate('emergency')),
        '[settings-split] the Emergency side default rate is 10%',
      )
      .toHaveText('10%');
    await expect
      .soft(
        page.getByTestId(TID.settingsSplitTotalMonthly),
        '[settings-split] 0.10 x availableIncome(4730) = "473 RON". If this reads "900 RON" the percentage is resolving against GROSS income.',
      )
      .toHaveText('473 RON');

    // Adding Savings 15% brings the total to 25% — the same 1,182 RON Priority shows.
    await page.getByTestId(TID.settingsSplitModePercentage('savings')).click();
    await expect
      .soft(
        page.getByTestId(TID.settingsSplitRate('savings')),
        '[settings-split] the Savings side default rate is 15%',
      )
      .toHaveText('15%');
    await expect
      .soft(
        page.getByTestId(TID.settingsSplitTotalMonthly),
        '[settings-split] (0.10+0.15) x 4730 = 1182.5 -> half-even -> "1,182 RON". NOTE: Priority mode shows the same string, so this assertion alone cannot tell the modes apart — golden vector S20 pins the per-side 473 / 709.5.',
      )
      .toHaveText('1,182 RON');
  });
});

test.describe('Screen: New Month — step 1', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.newMonthButton).click();
    const sheet = page.getByTestId(TID.newMonthSheet);
    await expectStrings(sheet, 'newmonth-step1', [
      'Step 1 of 3',
      'How much did you receive?',
      'Last month: 9,000 RON',
    ]);
  });
});

test.describe('Screen: New Month — step 2', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.newMonthButton).click();
    await page.getByTestId(TID.nmNextButton).click();
    const sheet = page.getByTestId(TID.newMonthSheet);
    await expectStrings(sheet, 'newmonth-step2', [
      'Step 2 of 3',
      'Update your account balances',
      'Did you use any savings this month?',
    ]);
    // GROUND-TRUTH gap 6, resolved 2026-08-06: the caption shows the account's CURRENT
    // balance, not a historical one. The wording is misleading but it ships that way —
    // assert the literal, never compute a previous value. After month 1 the balances are
    // Emergency 1182.5 and Savings 3547.5, so the captions read 1,182 / 3,548.
    for (const [slug, caption] of [
      [ACCOUNT.emergency, 'was 1,182 RON last month'],
      [ACCOUNT.savings, 'was 3,548 RON last month'],
    ] as const) {
      await expect
        .soft(
          sheet.getByText(caption).first(),
          `[newmonth-step2] ${slug} caption must read the literal "${caption}" — it echoes the CURRENT balance, so do not compute a previous month's value`,
        )
        .toBeVisible();
    }
    for (const slug of [ACCOUNT.emergency, ACCOUNT.savings]) {
      await expect
        .soft(
          sheet.getByTestId(TID.nmBalanceField(slug)),
          `[newmonth-step2] missing balance field for non-primary account "${slug}"`,
        )
        .toBeVisible();
    }
    await expect
      .soft(
        sheet.getByTestId(TID.nmBalanceField(ACCOUNT.main)),
        '[newmonth-step2] the PRIMARY account must NOT get a balance field',
      )
      .toHaveCount(0);
  });
});

test.describe('Screen: New Month — step 3', () => {
  test('all GROUND-TRUTH strings present', async ({ page, request }) => {
    await completeOnboarding(page, request, 'dashboard');
    await page.getByTestId(TID.newMonthButton).click();
    await page.getByTestId(TID.nmNextButton).click();
    await page.getByTestId(TID.nmNextButton).click();
    const sheet = page.getByTestId(TID.newMonthSheet);
    await expectStrings(sheet, 'newmonth-step3', [
      'Step 3 of 3',
      'Your Transfer Plan',
      'Income',
      'Expenses',
      'Available',
      'Transfers to make',
      'Emergency Fund',
      '4% → 8%',
      'Savings',
      'remaining money',
      'stays for automatic payments',
      'All amounts add up correctly',
      'Done – I made the transfers',
    ]);
    await expect
      .soft(sheet.getByTestId(TID.nmBackButton), '[newmonth-step3] header back chevron missing')
      .toBeVisible();
  });
});

// GROUND-TRUTH names Food, Rent, Gas, Streaming as the seeded onboarding expenses;
// keep the slug constants referenced so an accidental rename fails the type check.
void EXPENSE;
