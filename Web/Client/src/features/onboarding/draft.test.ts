import { describe, expect, it } from 'vitest'
import type { Category } from '../../lib/api'
import { editingString, money } from '../../lib/money'
import {
  ACCOUNT_FACTORY_NAMES,
  DEFAULT_SAVINGS,
  addAccount,
  changeAccountType,
  createDraft,
  deleteAccount,
  hasIncome,
  hasPrimarySavingsAccount,
  isNameValid,
  setPrimarySavings,
  skipExpenses,
  skipSavings,
  toPayload,
  updateAccount,
  updateExpense,
  updateSavings,
} from './draft'
import type { OnboardingDraft } from './types'
import { availableDestinations } from './components/RemainingMoneyPicker'
import { snapPercentage } from './components/SavingsSlider'
import type { RemainingMoneyDestinationRef } from '../../lib/api'

/**
 * `state.reference.remainingMoneyDestinations`, in the order the server sends them.
 *
 * ⚠️ Cast because `api.ts`'s `RemainingMoneyDestinationValue` is missing `'personal'` —
 * Domain has **three** cases (`RemainingMoneyPicker.swift:20-32`, PARITY-SPEC §2.7.1) and
 * the live server does send the third. Reported to Frontend; the cast goes when the union
 * is widened.
 */
const DESTINATIONS = [
  { value: 'primarySavings', displayName: 'Primary Savings', description: 'Add to your savings for future goals', icon: 'banknote.fill' },
  { value: 'personal', displayName: 'Personal Account', description: 'For flexible spending', icon: 'person.fill' },
  { value: 'primary', displayName: 'Keep in Primary', description: 'Leave in your main account', icon: 'building.columns.fill' },
] as unknown as readonly RemainingMoneyDestinationRef[]

const CATEGORIES: readonly Category[] = [
  { id: 'c1', name: 'Food/Groceries', icon: 'cart.fill', colorHex: '#22C55E', isDefault: true, sortOrder: 7 },
  { id: 'c2', name: 'Housing', icon: 'house.fill', colorHex: '#10B981', isDefault: true, sortOrder: 4 },
  { id: 'c3', name: 'Auto/Transport', icon: 'car.fill', colorHex: '#3B82F6', isDefault: true, sortOrder: 1 },
  { id: 'c4', name: 'Subscriptions', icon: 'arrow.triangle.2.circlepath', colorHex: '#8B5CF6', isDefault: true, sortOrder: 2 },
]

function draft(): OnboardingDraft {
  return createDraft({
    translateOnboarding: (key) => key,
    translateDomain: (key) => key,
    currencyCode: 'RON',
    categories: CATEGORIES,
  })
}

describe('seed', () => {
  it('starts with exactly one primary account, matching AccountEntry.defaults', () => {
    const initial = draft()
    expect(initial.accounts).toHaveLength(1)
    expect(initial.accounts[0]?.name).toBe(ACCOUNT_FACTORY_NAMES.primary)
    expect(initial.accounts[0]?.isPrimary).toBe(true)
  })

  it('seeds the four expense rows at zero, with server category ids', () => {
    const initial = draft()
    expect(initial.expenses.map((expense) => expense.name)).toEqual([
      'Food',
      'Rent',
      'Gas',
      'Streaming',
    ])
    expect(initial.expenses.map((expense) => expense.icon)).toEqual([
      'cart.fill',
      'house.fill',
      'fuelpump.fill',
      'tv.fill',
    ])
    expect(initial.expenses.map((expense) => expense.categoryId)).toEqual(['c1', 'c2', 'c3', 'c4'])
    expect(initial.expenses.every((expense) => expense.amount === '0')).toBe(true)
  })

  it('defaults BOTH split sides to fixedAmount 0 — not to the 10%/15% rates', () => {
    // The trap in GROUND-TRUTH: a client defaulting to percentage would show 473/710 RON
    // allocated where iOS shows nothing at all.
    expect(DEFAULT_SAVINGS.splitEmergencyInputMode).toBe('fixedAmount')
    expect(DEFAULT_SAVINGS.splitSavingsInputMode).toBe('fixedAmount')
    expect(DEFAULT_SAVINGS.splitEmergencyAmount).toBe('0')
    expect(DEFAULT_SAVINGS.splitSavingsAmount).toBe('0')
    // The rates exist, but only surface once a side is toggled to Percentage.
    expect(DEFAULT_SAVINGS.splitEmergencyPercentage).toBe(0.1)
    expect(DEFAULT_SAVINGS.splitSavingsPercentage).toBe(0.15)
  })

  it('defaults the remaining-money destination to primarySavings', () => {
    expect(draft().remainingMoneyDestination).toBe('primarySavings')
  })
})

describe('canAdvance', () => {
  it('name requires 1–50 trimmed characters', () => {
    expect(isNameValid({ ...draft(), name: '   ' })).toBe(false)
    expect(isNameValid({ ...draft(), name: ' Vlad ' })).toBe(true)
    expect(isNameValid({ ...draft(), name: 'x'.repeat(51) })).toBe(false)
  })

  it('income requires a positive amount', () => {
    expect(hasIncome(draft())).toBe(false)
    expect(hasIncome({ ...draft(), monthlyIncome: money('0') })).toBe(false)
    expect(hasIncome({ ...draft(), monthlyIncome: money('9000') })).toBe(true)
  })
})

describe('account mutations', () => {
  it('refuses a second emergency account', () => {
    const one = addAccount(draft(), 'Emergency Fund', 'emergency')
    const two = addAccount(one, 'Another', 'emergency')
    expect(two).toBe(one)
    expect(one.accounts[1]?.emergencyMultiplier).toBe(3)
  })

  it('makes the first savings account primary savings, but not the second', () => {
    const one = addAccount(draft(), 'Savings', 'savings')
    const two = addAccount(one, 'Travel', 'savings')
    expect(two.accounts[1]?.isPrimarySavings).toBe(true)
    expect(two.accounts[2]?.isPrimarySavings).toBe(false)
  })

  it('clears multiplier and hard cap when leaving the emergency type', () => {
    const withEmergency = addAccount(draft(), 'Emergency Fund', 'emergency')
    const id = withEmergency.accounts[1]!.id
    const capped = updateAccount(withEmergency, id, { emergencyHardCap: money('30000') })
    const changed = changeAccountType(capped, id, 'savings')
    expect(changed.accounts[1]).not.toHaveProperty('emergencyMultiplier')
    expect(changed.accounts[1]).not.toHaveProperty('emergencyHardCap')
    expect(changed.accounts[1]?.isPrimarySavings).toBe(true)
  })

  it('keeps the current primary-savings account primary when re-selecting savings', () => {
    // The ⚠️ in PARITY-SPEC §2.4: the guard reads the pre-mutation account list.
    const withSavings = addAccount(draft(), 'Savings', 'savings')
    const id = withSavings.accounts[1]!.id
    const again = changeAccountType(withSavings, id, 'savings')
    expect(again.accounts[1]?.isPrimarySavings).toBe(true)
  })

  it('setPrimarySavings is exclusive', () => {
    const two = addAccount(addAccount(draft(), 'Savings', 'savings'), 'Travel', 'savings')
    const moved = setPrimarySavings(two, two.accounts[2]!.id)
    expect(moved.accounts.map((account) => account.isPrimarySavings)).toEqual([false, false, true])
  })

  it('deletes by id', () => {
    const two = addAccount(draft(), 'Savings', 'savings')
    expect(deleteAccount(two, two.accounts[1]!.id).accounts).toHaveLength(1)
  })
})

describe('"Skip for now" — the two buttons do DIFFERENT things (R23)', () => {
  it('expenses skip zeroes all four amounts but keeps the rows', () => {
    let current = draft()
    for (const expense of current.expenses) {
      current = updateExpense(current, expense.id, {
        amount: money('1200'),
        amountText: editingString('1200'),
      })
    }
    const skipped = skipExpenses(current)
    expect(skipped.expenses).toHaveLength(4)
    expect(skipped.expenses.every((expense) => expense.amount === '0')).toBe(true)
    expect(skipped.expenses.map((expense) => expense.name)).toEqual([
      'Food',
      'Rent',
      'Gas',
      'Streaming',
    ])
    // …and none of them is persisted, so availableIncome == income.
    expect(toPayload(skipped, true).expenses).toHaveLength(0)
  })

  it('savings skip does NOT zero savings — it restores 25% prioritized/percentage', () => {
    const edited = updateSavings(draft(), {
      percentage: 0.5,
      allocationMode: 'split',
      savingsInputMode: 'fixedAmount',
      boostEnabled: true,
    })
    const skipped = skipSavings(edited)
    expect(skipped.savings.percentage).toBe(0.25)
    expect(skipped.savings.allocationMode).toBe('prioritized')
    expect(skipped.savings.savingsInputMode).toBe('percentage')
    expect(skipped.savings.boostEnabled).toBe(false)
  })
})

describe('payload', () => {
  it('keeps zero-amount rows for the preview and drops them when persisting', () => {
    const current = updateExpense(draft(), draft().expenses[0]!.id, { amount: money('1200') })
    expect(toPayload(current, false).expenses).toHaveLength(4)
    // Only rows with amount > 0 survive `OnboardingViewModel.save` (§2.8 step 3).
    const persisted = toPayload(
      updateExpense(current, current.expenses[0]!.id, { amount: money('1200') }),
      true,
    )
    expect(persisted.expenses).toHaveLength(1)
    expect(persisted.expenses[0]?.amount).toBe('1200')
  })

  it('sends account ids so preview results can be matched back to draft rows', () => {
    const current = addAccount(draft(), 'Emergency Fund', 'emergency')
    const payload = toPayload(current)
    expect(payload.accounts.map((account) => account.id)).toEqual(
      current.accounts.map((account) => account.id),
    )
    expect(payload.accounts[1]?.emergencyMultiplier).toBe(3)
  })

  it('trims the name and passes money as decimal strings', () => {
    const current = { ...draft(), name: '  Vlad  ', monthlyIncome: money('9000') }
    const payload = toPayload(current)
    expect(payload.name).toBe('Vlad')
    expect(payload.monthlyIncome).toBe('9000')
    expect(typeof payload.monthlyIncome).toBe('string')
  })
})

describe('mirrored upstream defects — these tests FAIL if anyone "fixes" them (R26a)', () => {
  it('remaining money has NO selected card when there is no savings account', () => {
    /*
     * R23's upstream bug, reproduced deliberately. `remainingMoneyDestination` defaults to
     * `.primarySavings` and stays there even when no such account exists, so the picker
     * renders `[Keep in Primary]` with nothing highlighted — and at save the money is
     * credited to no account and vanishes.
     *
     * The inverse assertion R26a requires: if a future change ever makes a card selected
     * here (e.g. by falling back to `.primary`), this fails loudly rather than silently
     * "improving" the app away from iOS.
     */
    const current = draft() // one primary account, no savings
    expect(hasPrimarySavingsAccount(current)).toBe(false)
    expect(current.remainingMoneyDestination).toBe('primarySavings')

    const shown = availableDestinations(DESTINATIONS, false, false)
    expect(shown.map((destination) => destination.value)).toEqual(['primary'])
    expect(shown.some((destination) => destination.value === current.remainingMoneyDestination)).toBe(
      false,
    )
  })

  it('destination order is [primarySavings?, primary, personal?] — primary sits BETWEEN', () => {
    expect(availableDestinations(DESTINATIONS, true, true).map((d) => d.value)).toEqual([
      'primarySavings',
      'primary',
      'personal',
    ])
  })
})

describe('savings slider snapping (SavingsSlider.swift:112-129)', () => {
  const SNAP = [0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4]

  it('snaps to a served snap value within the served threshold', () => {
    expect(snapPercentage(0.26, SNAP, 0.02)).toBe(0.25)
    expect(snapPercentage(0.24, SNAP, 0.02)).toBe(0.25)
  })

  it('leaves values outside the threshold alone — the slider is continuous', () => {
    expect(snapPercentage(0.27, SNAP, 0.02)).toBe(0.27)
    expect(snapPercentage(0.47, SNAP, 0.02)).toBe(0.47)
  })

  it('pins the float boundary: nominal-0.02 neighbours DO snap', () => {
    /*
     * `SavingsSlider.swift:123` is `abs(newPercentage - snapValue) < snapThreshold` —
     * strict. At a nominal distance of exactly `snapThreshold` the answer is decided by
     * IEEE-754 noise, and for every table value it lands just *under*:
     *   |0.30 - 0.28| = 0.019999999999999962  ->  snaps
     *   |0.20 - 0.22| = 0.019999999999999990  ->  snaps
     * so the strict comparator behaves like `<=` at precisely these positions. Swift
     * `Double` and JS `number` are the same IEEE-754 doubles, so reproducing the
     * expression verbatim — rather than tidying it with an epsilon or a `<=` — is what
     * guarantees the same thumb behaviour on both platforms.
     *
     * (An earlier version of this test asserted an asymmetry that does not exist. It was
     * a plausible story about float noise; the numbers above are the measured answer.)
     */
    expect(snapPercentage(0.28, SNAP, 0.02)).toBe(0.3)
    expect(snapPercentage(0.22, SNAP, 0.02)).toBe(0.2)
    // Genuinely outside: 0.03 away from the nearest snap value.
    expect(snapPercentage(0.27, SNAP, 0.02)).toBe(0.27)
    expect(snapPercentage(0.18, SNAP, 0.02)).toBe(0.18)
  })

  it('does NOT snap a single-step change — otherwise the thumb cannot leave 10%', () => {
    // Arrow keys move one 0.01 position, straight into the snap radius. Snapping those
    // would pull the value back every time and make the slider keyboard-inaccessible,
    // which iOS is not: its AX path steps by 0.05 and never snaps (§2.6.1).
    expect(snapPercentage(0.11, SNAP, 0.02, true)).toBe(0.11)
    expect(snapPercentage(0.09, SNAP, 0.02, true)).toBe(0.09)
    // …but a drag onto the same position still snaps.
    expect(snapPercentage(0.11, SNAP, 0.02, false)).toBe(0.1)
  })

  it('uses snapValues, NOT savingsConstants.presets', () => {
    // `presets` stops at 0.30; the slider snaps at 0.35 and 0.40 too. Backend confirmed
    // `presets` is dead code referenced by no view.
    expect(snapPercentage(0.355, SNAP, 0.02)).toBe(0.35)
    expect(snapPercentage(0.39, SNAP, 0.02)).toBe(0.4)
  })
})
