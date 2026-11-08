/**
 * View state — the spine of the client.
 *
 * DECISIONS.md D3 rules out a router: the app is a tab shell plus modals, and every
 * "screen" is either an onboarding step, one of three tabs, or something presented on
 * top. A discriminated union models exactly the states that can exist, so impossible
 * combinations (a New Month step while onboarding, say) are unrepresentable.
 *
 * Modals are a **stack**, not a single slot, because the iOS app genuinely nests them:
 *   • Settings → tap an account row → account editor
 *   • Add Expense sheet → "New Category…" → Add Category sheet
 *   • Expenses overflow → Manage Categories → Add Category
 */

/* ------------------------------------------------------------------ *
 * Onboarding
 * ------------------------------------------------------------------ */

/**
 * Onboarding is **7 screens with a 5-dot indicator** — both numbers are real and mean
 * different things, which is what made `GROUND-TRUTH.md` look self-contradictory:
 *   • 7 screens: welcome → name → income → accounts → expenses → savings → summary
 *   • 5 dots: name → income → accounts → expenses → savings.
 *     Welcome and summary show **no** indicator at all.
 * Verified from the reference screens: accounts is dot 3 of 5
 * (`04-onboarding-accounts.jpg`), savings is dot 5 of 5 (`06-onboarding-savings.jpg`).
 *
 * Neither 7 nor 5 is written down as a literal anywhere — both derive from the arrays
 * below, so adding or removing a screen cannot leave the indicator lying.
 */
export type OnboardingStep =
  | 'welcome'
  | 'name'
  | 'income'
  | 'accounts'
  | 'expenses'
  | 'savings'
  | 'summary'

/** Presentation order. The progress indicator derives its dot count from this. */
export const ONBOARDING_STEPS: readonly OnboardingStep[] = [
  'welcome',
  'name',
  'income',
  'accounts',
  'expenses',
  'savings',
  'summary',
]

export function onboardingStepIndex(step: OnboardingStep): number {
  return ONBOARDING_STEPS.indexOf(step)
}

export function nextOnboardingStep(step: OnboardingStep): OnboardingStep | null {
  return ONBOARDING_STEPS[onboardingStepIndex(step) + 1] ?? null
}

export function previousOnboardingStep(step: OnboardingStep): OnboardingStep | null {
  const index = onboardingStepIndex(step)
  return index > 0 ? (ONBOARDING_STEPS[index - 1] ?? null) : null
}

/** Steps carrying a progress dot. Welcome and summary are deliberately excluded. */
export const ONBOARDING_INDICATOR_STEPS: readonly OnboardingStep[] = ONBOARDING_STEPS.filter(
  (step) => step !== 'welcome' && step !== 'summary',
)

export interface OnboardingIndicator {
  /** 1-based dot position. */
  readonly position: number
  /** Total dots — derived, never the literal 5. */
  readonly total: number
}

/** `null` on welcome and summary, which render no indicator. */
export function onboardingIndicator(step: OnboardingStep): OnboardingIndicator | null {
  const index = ONBOARDING_INDICATOR_STEPS.indexOf(step)
  if (index === -1) return null
  return { position: index + 1, total: ONBOARDING_INDICATOR_STEPS.length }
}

/* ------------------------------------------------------------------ *
 * Main app
 * ------------------------------------------------------------------ */

/** GROUND-TRUTH: 3 tabs — Dashboard, Expenses, Insights. */
export type Tab = 'dashboard' | 'expenses' | 'insights'

export const TABS: readonly Tab[] = ['dashboard', 'expenses', 'insights']

/** Expenses screen segmented control, and the same control inside the expense sheet. */
export type Frequency = 'monthly' | 'annual'

/* ------------------------------------------------------------------ *
 * Modals
 * ------------------------------------------------------------------ */

/** New Month is a 3-step modal with a "Step n of 3" header and a back chevron. */
export type NewMonthStep = 1 | 2 | 3

export type Modal =
  /** Settings sheet — Cancel / Settings / Save. */
  | { readonly kind: 'settings' }
  /** Account detail pushed from within Settings, or from onboarding's account rows. */
  | { readonly kind: 'accountEditor'; readonly accountId: string }
  /** "Add Another Account" / the Recommended prompt cards. */
  | { readonly kind: 'addAccount' }
  /** New Month flow. */
  | { readonly kind: 'newMonth'; readonly step: NewMonthStep }
  /** Add/Edit Expense sheet — `expenseId` absent means Add. */
  | { readonly kind: 'expenseSheet'; readonly expenseId?: string }
  /** Expenses overflow → Manage Categories. */
  | { readonly kind: 'categoryManagement' }
  /** "New Category…" from the expense sheet, or "+" in category management. */
  | { readonly kind: 'addCategory' }
  /** Dashboard toolbar hammer — DEBUG only on iOS. */
  | { readonly kind: 'devTools' }

export type ModalKind = Modal['kind']

/* ------------------------------------------------------------------ *
 * Route + ViewState
 * ------------------------------------------------------------------ */

export type Route =
  /** Before GET /api/state resolves we do not know which shell to show. */
  | { readonly kind: 'loading' }
  | { readonly kind: 'error'; readonly message: string }
  | { readonly kind: 'onboarding'; readonly step: OnboardingStep }
  | { readonly kind: 'main'; readonly tab: Tab }

export interface ViewState {
  readonly route: Route
  /** Top of the stack is the frontmost sheet. Empty means nothing is presented. */
  readonly modals: readonly Modal[]
}

export const INITIAL_VIEW_STATE: ViewState = {
  route: { kind: 'loading' },
  modals: [],
}

/* ------------------------------------------------------------------ *
 * Transitions — pure, exhaustively typed
 * ------------------------------------------------------------------ */

export function goToOnboarding(_state: ViewState, step: OnboardingStep): ViewState {
  return { route: { kind: 'onboarding', step }, modals: [] }
}

export function goToTab(state: ViewState, tab: Tab): ViewState {
  return { ...state, route: { kind: 'main', tab } }
}

export function presentModal(state: ViewState, modal: Modal): ViewState {
  return { ...state, modals: [...state.modals, modal] }
}

export function dismissTopModal(state: ViewState): ViewState {
  return { ...state, modals: state.modals.slice(0, -1) }
}

export function dismissAllModals(state: ViewState): ViewState {
  return { ...state, modals: [] }
}

export function topModal(state: ViewState): Modal | null {
  return state.modals[state.modals.length - 1] ?? null
}

/** Replaces the frontmost modal — used to step the New Month flow in place. */
export function replaceTopModal(state: ViewState, modal: Modal): ViewState {
  if (state.modals.length === 0) return presentModal(state, modal)
  return { ...state, modals: [...state.modals.slice(0, -1), modal] }
}
