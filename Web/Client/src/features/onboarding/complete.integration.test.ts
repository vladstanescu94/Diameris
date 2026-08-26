/**
 * The one path in onboarding that unit tests cannot reach: **`POST /api/onboarding/complete`**,
 * which writes the store.
 *
 * It stayed unverified for a long time for a good reason — completing against the shared
 * store on :8080 would have destroyed the month-2 ground-truth balances (EF 2,365 /
 * Savings 7,095) that the parity fixtures assert against. R29's `DIAMERIS_STORE` makes an
 * isolated instance possible, so this now runs for real against a disposable one.
 *
 * **Opt-in, never in the default run.** A test that silently passes when no server is
 * listening is worse than no test — it reports green for a path it never exercised. So it
 * refuses to run without an explicit URL and *fails loudly* if that URL is unreachable:
 *
 *     DIAMERIS_PORT=8082 DIAMERIS_STORE=/tmp/f2-store.json \
 *       Web/Server/.build/debug/DiamerisServer &
 *     DIAMERIS_TEST_URL=http://127.0.0.1:8082 npx vitest run complete.integration
 *
 * ⚠️ Never point it at :8080 (shared) or :8081 (Reviewer's) — it completes onboarding and
 * rewrites whatever store the server was started with.
 */

import { describe, expect, it } from 'vitest'
import type { AppState, Category } from '../../lib/api'
import { editingString, money } from '../../lib/money'
import { addAccount, createDraft, toPayload, updateExpense } from './draft'
import type { OnboardingDraft } from './types'

const BASE = process.env.DIAMERIS_TEST_URL

/** GROUND-TRUTH.md: Vlad / 9,000 / 1200+2500+450+120, 25% priority. */
const EXPENSE_AMOUNTS = ['1200', '2500', '450', '120']

async function getState(): Promise<AppState> {
  const response = await fetch(`${BASE}/api/state`)
  if (!response.ok) throw new Error(`GET /api/state -> ${response.status}`)
  return (await response.json()) as AppState
}

/** Builds the draft exactly as driving the seven screens does. */
function groundTruthDraft(categories: readonly Category[]): OnboardingDraft {
  let draft = createDraft({
    translateOnboarding: (key) => key,
    translateDomain: (key) => key,
    currencyCode: 'RON',
    categories,
  })
  draft = { ...draft, name: 'Vlad', monthlyIncome: money('9000'), incomeText: editingString('9000') }
  // The two Recommended prompts, in the order the screen offers them.
  draft = addAccount(draft, 'Emergency Fund', 'emergency')
  draft = addAccount(draft, 'Savings', 'savings')
  draft.expenses.forEach((expense, index) => {
    const amount = EXPENSE_AMOUNTS[index]
    if (amount) {
      draft = updateExpense(draft, expense.id, {
        amount: money(amount),
        amountText: editingString(amount),
      })
    }
  })
  return draft
}

describe.skipIf(!BASE)('POST /api/onboarding/complete — against an isolated store', () => {
  it('persists the ground-truth run with balances pre-applied (§2.8)', async () => {
    const before = await getState()
    expect(before.onboardingCompleted, 'store must be fresh — point at a disposable one').toBe(
      false,
    )

    const draft = groundTruthDraft(before.categories)
    const response = await fetch(`${BASE}/api/onboarding/complete`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      // `persisting: true` drops the zero-amount rows, as `OnboardingViewModel.save` does.
      body: JSON.stringify(toPayload(draft, true)),
    })
    // Read the body ONCE — `text()` then `json()` throws "Body has already been read".
    const bodyText = await response.text()
    expect(response.status, bodyText).toBe(200)
    const after = JSON.parse(bodyText) as AppState

    expect(after.onboardingCompleted).toBe(true)
    expect(after.profile?.name).toBe('Vlad')
    expect(after.profile?.currencyCode).toBe('RON')
    expect(after.settings.income.display).toBe('9,000 RON')

    // All four expenses persisted, none dropped, none duplicated.
    expect(after.expenses.map((expense) => expense.name).sort()).toEqual([
      'Food',
      'Gas',
      'Rent',
      'Streaming',
    ])
    expect(after.expensesScreen.totalMonthly.display).toBe('4,270 RON')

    /*
     * §2.8 step 4 — balances are written as if the user had made every transfer:
     *   primary  = remainsInPrimary  (ASSIGNED, not added)
     *   emergency += its allocation
     *   savings  += the remaining money, because the destination is `.primarySavings`
     * These are the numbers the dashboard shows on the first launch after onboarding.
     */
    const balance = (name: string) =>
      after.accounts.find((account) => account.name === name)?.currentBalance.display
    expect(balance('Main Account')).toBe('4,270 RON')
    expect(balance('Emergency Fund')).toBe('1,182 RON')
    expect(balance('Savings')).toBe('3,548 RON')

    // And the savings row really is persisted at the default 25 %.
    expect(after.settings.savings.percentageDisplay).toBe('25%')
    expect(after.settings.savings.allocationMode).toBe('prioritized')

    // The emergency account keeps its multiplier, so the target survives the write.
    const emergency = after.accounts.find((account) => account.accountType === 'emergency')
    expect(emergency?.emergencyMultiplier).toBe(3)
    expect(emergency?.emergencyTarget?.display).toBe('27,000 RON')
  })

  it('fails loudly rather than silently skipping when the server is unreachable', async () => {
    // The whole point of the opt-in: if DIAMERIS_TEST_URL is set, the run must be real.
    await expect(getState()).resolves.toBeTruthy()
  })
})
