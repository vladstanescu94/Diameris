/**
 * The catalogue of screens under visual review, and their iOS reference images.
 * Shared by screens.spec.ts (capture) and report.ts (REPORT.md generation),
 * so the two can never drift.
 */
/**
 * DECISIONS.md R9 (corrected 2026-08-06): the parity column is **402×874**, the iPhone 17 Pro
 * logical size — NOT 390×844. Settled from the reference aspect ratio: the reference JPGs are
 * 368×800, and 402/874 → 367.96 → 368, whereas 390/844 → 370. Grading at 390 with a ±2px
 * tolerance would have mis-graded every screen by 12px — the acceptance criterion itself
 * would have been the bug.
 */
export const VIEWPORTS = [
  { label: '402x874', width: 402, height: 874 },
  { label: '1280x900', width: 1280, height: 900 },
] as const;

/** Only this width carries the ±2px acceptance criterion. */
export const GRADED_VIEWPORT = '402x874';

export const THEMES = ['light', 'dark'] as const;

export type Theme = (typeof THEMES)[number];

const REF_DIR = '../Docs/reference-screens';

/**
 * screen slug -> light reference (null = no iOS reference captured for this screen).
 *
 * Still missing (main is deferring these until the client runs and the vectors are locked,
 * because capturing them needs an onboarding reset that would disturb pinned state):
 * onboarding-name, onboarding-income, onboarding-expenses. Grade those on prose only.
 */
export const LIGHT_REFERENCES: Record<string, string | null> = {
  'onboarding-welcome': `${REF_DIR}/01-onboarding-welcome.jpg`,
  'onboarding-name': null,
  'onboarding-income': null,
  'onboarding-accounts': `${REF_DIR}/04-onboarding-accounts.jpg`,
  'onboarding-expenses': null,
  'onboarding-savings': `${REF_DIR}/06-onboarding-savings.jpg`,
  'onboarding-summary': `${REF_DIR}/07-onboarding-summary.jpg`,
  dashboard: `${REF_DIR}/08-dashboard.jpg`,
  expenses: `${REF_DIR}/09-expenses.jpg`,
  'expenses-category-expanded': `${REF_DIR}/10-expenses-category-expanded.jpg`,
  'add-expense-sheet': `${REF_DIR}/14-add-expense-sheet.jpg`,
  'manage-categories': `${REF_DIR}/15-manage-categories.jpg`,
  'new-category-sheet': `${REF_DIR}/16-new-category-sheet.jpg`,
  insights: `${REF_DIR}/22-insights.jpg`,
  settings: `${REF_DIR}/11-settings.jpg`,
  'settings-split-fixed': `${REF_DIR}/18-settings-split-fixed.jpg`,
  'settings-split-percentage': `${REF_DIR}/19-settings-split-percentage.jpg`,
  'settings-split-at-target-plan': `${REF_DIR}/24-split-at-target-transferplan.jpg`,
  'account-editor': `${REF_DIR}/23-account-editor.jpg`,
  'newmonth-step1': `${REF_DIR}/20-newmonth-step1.jpg`,
  'newmonth-step2': `${REF_DIR}/21-newmonth-step2.jpg`,
  'newmonth-step3': `${REF_DIR}/12-newmonth-step3.jpg`,
};

/** screen slug -> dark reference, where one was captured on device. */
export const DARK_REFERENCES: Record<string, string | null> = {
  dashboard: `${REF_DIR}/13-dashboard-dark.jpg`,
};

/**
 * Screens whose reference image is LOCALE-DEPENDENT and cannot be graded naively.
 *
 * `account-editor` renders two incompatible number formats at once: Target Amount uses
 * AmountFormatter (`27,000 RON`, comma) while Current Balance uses
 * `TextField(format: .number)` (`2.365`, period) — the device locale, per
 * SettingsSheet.swift:55. The stored value is 2365 either way. On a US-formats machine the
 * same field renders `2,365`, so the reference and a capture can differ for reasons that
 * have nothing to do with the port. Pin the locale before grading, or exclude that field.
 */
export const LOCALE_SENSITIVE_SCREENS = new Set(['account-editor']);

/**
 * `dev-tools` is deliberately NOT in the catalogue: `#if DEBUG` on iOS, gated out of the
 * production web build, therefore not shipped parity surface (R16). Reference image
 * 17-dev-tools.jpg is retained for context but is not graded.
 */
export const SCREENS = Object.keys(LIGHT_REFERENCES);

export function referenceFor(screen: string, theme: Theme): string | null {
  if (theme === 'dark') return DARK_REFERENCES[screen] ?? null;
  return LIGHT_REFERENCES[screen] ?? null;
}

export function captureName(screen: string, theme: Theme, viewportLabel: string): string {
  return `${screen}-${theme}-${viewportLabel}.png`;
}
