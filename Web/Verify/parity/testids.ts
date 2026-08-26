/**
 * TEST ID CONTRACT — owned by Reviewer, consumed by Frontend.
 *
 * The parity suites drive the *real UI*. Wherever a value is a number or a
 * control (not a stable human-readable label) the suite needs a stable hook.
 * Frontend must add `data-testid="…"` attributes matching these exact strings.
 *
 * Rule of thumb used here:
 *   - Text that a user reads and that is fixed by GROUND-TRUTH  -> queried by text.
 *   - Numbers, inputs, sliders, tabs, sheets                     -> queried by testid.
 *
 * If a testid below is wrong for the implementation, message Reviewer — do not
 * silently rename it, the suites are the parity contract.
 */
export const TID = {
  // ---- onboarding: screen roots (used for screenshots + presence) ----
  onbWelcome: 'onb-welcome',
  onbName: 'onb-name',
  onbIncome: 'onb-income',
  onbAccounts: 'onb-accounts',
  onbExpenses: 'onb-expenses',
  onbSavings: 'onb-savings',
  onbSummary: 'onb-summary',
  /**
   * GROUND-TRUTH: onboarding is **7 screens** with a **5-dot** indicator covering only
   * screens 2–6 (name → income → accounts → expenses → savings). Welcome and the
   * first-month summary show NO dots. Derive the count from the step list; the active
   * dot must carry `data-active="true"`.
   */
  onbProgressDots: 'onb-progress-dots',
  onbProgressDot: 'onb-progress-dot',

  // ---- onboarding: controls ----
  nameField: 'onb-name-field',
  incomeField: 'onb-income-field',
  addAccountEmergency: 'onb-add-account-emergency',
  addAccountSavings: 'onb-add-account-savings',
  addAnotherAccount: 'onb-add-another-account',

  /** expense amount inputs, keyed by seeded category slug */
  expenseAmount: (slug: string) => `onb-expense-amount-${slug}`,
  /** "After expenses" live summary value on the onboarding expenses step */
  onbAfterExpensesValue: 'onb-after-expenses-value',

  // savings step
  strategyPriority: 'onb-strategy-priority',
  strategySplit: 'onb-strategy-split',
  modePercentage: 'onb-mode-percentage',
  modeFixed: 'onb-mode-fixed',
  savingsPercentSlider: 'onb-savings-percent-slider',
  savingsPercentValue: 'onb-savings-percent-value',
  savingsPerMonthCaption: 'onb-savings-permonth-caption',
  savingsThisMonthValue: 'onb-savings-thismonth-value',
  savingsBoostSwitch: 'onb-savings-boost-switch',

  // summary step
  summaryIncomeValue: 'onb-summary-income-value',
  summaryTransferEmergencyValue: 'onb-summary-transfer-emergency-value',
  summaryTransferEmergencyProgress: 'onb-summary-transfer-emergency-progress',
  summaryEmergencyTarget: 'onb-summary-emergency-target',
  summaryStaysInPrimaryValue: 'onb-summary-stays-in-primary-value',
  summaryRemainingValue: 'onb-summary-remaining-value',
  summaryRemainingChoiceSavings: 'onb-summary-remaining-choice-savings',
  summaryRemainingChoicePrimary: 'onb-summary-remaining-choice-primary',
  summaryTotal: 'onb-summary-total',

  // ---- main app chrome ----
  tabDashboard: 'tab-dashboard',
  tabExpenses: 'tab-expenses',
  tabInsights: 'tab-insights',
  newMonthButton: 'new-month-button',
  toolbarSettings: 'toolbar-settings',
  /**
   * ⚠️ RULED 2026-08-06: this id must NOT exist in a production build.
   *
   * Dev Tools is `#if DEBUG` on iOS — both the view and its entry point — so under R16 it is
   * **not shipped parity surface**. Frontend gated it behind `import.meta.env.DEV`, which is
   * correct. The harness therefore asserts its ABSENCE from the built app rather than its
   * presence, and the dev-tools screen is excluded from content and capture.
   *
   * Asserting presence would have forced Frontend to ship a debug affordance to make a
   * parity test pass — the test manufacturing the divergence it exists to prevent.
   */
  toolbarDevTools: 'toolbar-devtools',

  // ---- dashboard ----
  dashboard: 'screen-dashboard',
  dashTitle: 'dashboard-title',
  dashIncome: 'dash-summary-income',
  dashExpenses: 'dash-summary-expenses',
  dashSavings: 'dash-summary-savings',
  dashPersonalSpending: 'dash-summary-personal-spending',
  dashEfPercent: 'dash-ef-percent',
  /**
   * DECISIONS.md R20 — the progress ARC and BAR must be driven by the server's full
   * double (`emergencyProgress`), while the LABEL uses the truncated integer
   * (`emergencyProgressPercent`). Two server fields, two jobs, neither derived from the
   * other client-side.
   *
   * The arc element must expose the unrounded value it was drawn from as `data-progress`
   * and use `pathLength="1"` with `stroke-dasharray="<progress> 1"`.
   */
  dashEfRingArc: 'dash-ef-ring-arc',
  progressBarFill: (slug: string) => `progress-bar-fill-${slug}`,
  dashEfAmounts: 'dash-ef-amounts',
  dashEfTargetCaption: 'dash-ef-target-caption',
  /** R25a — when a hard cap bites, the uncapped target renders struck through beside it. */
  efTargetEffective: 'ef-target-effective',
  efTargetUncapped: 'ef-target-uncapped',
  dashAccountBalance: (slug: string) => `dash-account-balance-${slug}`,
  breakdownAmount: (slug: string) => `dash-breakdown-amount-${slug}`,
  breakdownPercent: (slug: string) => `dash-breakdown-percent-${slug}`,

  // ---- expenses screen ----
  expensesScreen: 'screen-expenses',
  expensesTotal: 'expenses-total',
  expensesPeriodMonthly: 'expenses-period-monthly',
  expensesPeriodAnnual: 'expenses-period-annual',
  categoryRow: (slug: string) => `expenses-category-${slug}`,
  categoryCount: (slug: string) => `expenses-category-count-${slug}`,
  categoryTotal: (slug: string) => `expenses-category-total-${slug}`,
  /**
   * R25a — iOS NEVER displays `expense.amount`. ExpenseItemRow.swift:31 renders
   * `monthlyAmount` or `annualAmount` depending on the segment; `amount` exists only to
   * seed the edit field. A row rendering `amount` is 12x wrong on any annual expense.
   */
  expenseRowAmount: (slug: string) => `expense-row-amount-${slug}`,
  expenseRow: (slug: string) => `expense-row-${slug}`,
  addExpenseButton: 'expenses-add-button',
  addExpenseSheet: 'add-expense-sheet',
  expensesOverflowMenu: 'expenses-overflow-menu',
  addExpenseIconGrid: 'add-expense-icon-grid',
  // --- AddExpenseSheet controls (Frontend2, task #22) ---
  addExpenseName: 'add-expense-name',
  addExpenseAmount: 'add-expense-amount',
  addExpensePeriodMonthly: 'add-expense-period-monthly',
  addExpensePeriodAnnual: 'add-expense-period-annual',
  /** the ÷12 draft preview — R18 describes it as ×12, which is 144x wrong; it is amount ÷ 12 */
  addExpenseMonthlyEquivalent: 'add-expense-monthly-equivalent',
  addExpenseCategoryMenu: 'add-expense-category-menu',
  addExpenseNewCategoryRow: 'add-expense-new-category-row',
  addExpensePayFromMenu: 'add-expense-pay-from-menu',
  addExpenseNotes: 'add-expense-notes',
  addExpenseEnabledToggle: 'add-expense-enabled-toggle',
  addExpenseDelete: 'add-expense-delete',
  /** icon cells, keyed by SF Symbol name — `data-symbol` carries the same value */
  addExpenseIconCell: (symbol: string) => `add-expense-icon-${symbol}`,

  // ---- categories ----
  manageCategoriesSheet: 'manage-categories-sheet',
  newCategorySheet: 'new-category-sheet',
  newCategoryIconGrid: 'new-category-icon-grid',
  newCategoryColorSwatches: 'new-category-color-swatches',
  newCategoryPreview: 'new-category-preview',
  newCategoryPreviewIcon: 'new-category-preview-icon',
  newCategoryPreviewLabel: 'new-category-preview-label',
  newCategoryName: 'new-category-name',
  newCategoryIconCell: (symbol: string) => `new-category-icon-${symbol}`,
  newCategoryColorSwatch: (hex: string) => `new-category-color-${hex.replace('#', '').toLowerCase()}`,
  manageCategoryRow: (slug: string) => `category-row-${slug}`,
  manageCategoryDefaultPill: (slug: string) => `category-default-pill-${slug}`,
  manageCategoriesAdd: 'manage-categories-add',
  manageCategoriesDone: 'manage-categories-done',

  // ---- developer tools ----
  devToolsSheet: 'dev-tools-sheet',

  // ---- insights ----
  insightsScreen: 'screen-insights',

  // ---- settings ----
  settingsSheet: 'settings-sheet',
  /**
   * GROUND-TRUTH gap 7, resolved 2026-08-06: the account-row subtitle is NOT one string
   * with a double space — it is an HStack(spacing: Spacing.xs) of 2–3 independent Text
   * views, each with its own colour, every string single-spaced. The 8pt gap is layout.
   * So the DOM must be 2–3 sibling nodes, not one concatenated string.
   */
  settingsAccountRow: (slug: string) => `settings-account-row-${slug}`,
  settingsAccountSubtitlePart: 'settings-account-subtitle-part',
  settingsStrategyPriority: 'settings-strategy-priority',
  settingsStrategySplit: 'settings-strategy-split',
  /**
   * Split mode replaces the single savings-rate control with two INDEPENDENT per-account
   * blocks, each with its own Percentage|Fixed Amount segmented control, plus a
   * "Total Monthly" row. Defaults on first switch: both sides Fixed at 0 (total 0 RON);
   * switching a side to Percentage reveals Emergency 10% / Savings 15%.
   */
  settingsSplitTotalMonthly: 'settings-split-total-monthly',
  settingsSplitModePercentage: (side: string) => `settings-split-${side}-mode-percentage`,
  settingsSplitModeFixed: (side: string) => `settings-split-${side}-mode-fixed`,
  settingsSplitRate: (side: string) => `settings-split-${side}-rate`,
  settingsSplitAmount: (side: string) => `settings-split-${side}-amount`,
  /**
   * The RESOLVED per-side money amount in Percentage mode (distinct from the Fixed-mode
   * input field above). S24: these round independently of the total, so the rendered
   * parts visibly sum to 1,183 against a 1,182 total. That is correct behaviour.
   */
  settingsSplitResolvedAmount: (side: string) => `settings-split-${side}-resolved-amount`,

  // ---- new month flow ----
  newMonthSheet: 'new-month-sheet',
  nmStepLabel: 'nm-step-label',
  nmIncomeField: 'nm-income-field',
  nmBalanceField: (slug: string) => `nm-balance-${slug}`,
  nmPlanIncome: 'nm-plan-income',
  nmPlanExpenses: 'nm-plan-expenses',
  nmPlanAvailable: 'nm-plan-available',
  /**
   * ⚠️ Transfer-plan rows are keyed by ORDINAL POSITION, never by account.
   *
   * One account can legitimately appear TWICE: in Split mode with the emergency fund at
   * target, the plan renders two rows both named "Savings" — `+1,182 RON` (the redirected
   * emergency share) and `+3,548 RON` (`remaining money`). A client keying rows by account
   * id or name collapses them and silently loses 3,548 RON from the display, while showing
   * a single plausible-looking row.
   *
   * These ids were account-keyed until 2026-08-06; that shape had the collapsing bug baked
   * into the test contract itself, so the harness could never have caught it.
   */
  nmTransferRow: (index: number) => `nm-transfer-row-${index}`,
  nmTransferName: (index: number) => `nm-transfer-name-${index}`,
  nmTransferValue: (index: number) => `nm-transfer-value-${index}`,
  nmTransferSub: (index: number) => `nm-transfer-sub-${index}`,
  /** the whole ordered list, for counting rows */
  nmTransferList: 'nm-transfer-list',
  nmPrimaryValue: 'nm-primary-value',
  nmDoneButton: 'nm-done-button',
  nmNextButton: 'nm-next-button',
  nmBackButton: 'nm-back-button',
} as const;

/** Account slugs used in testids. */
export const ACCOUNT = {
  main: 'main',
  emergency: 'emergency',
  savings: 'savings',
} as const;

/** Seeded onboarding expense slugs. */
export const EXPENSE = {
  food: 'food',
  rent: 'rent',
  gas: 'gas',
  streaming: 'streaming',
} as const;
