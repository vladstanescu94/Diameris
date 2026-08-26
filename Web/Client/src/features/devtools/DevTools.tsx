/**
 * Dev Tools — **not shipped parity surface** (R16).
 *
 * Both the iOS view and its entry point are `#if DEBUG`, so a shipping user cannot reach
 * it. We therefore do NOT port the screen: this is tooling, gated on `import.meta.env.DEV`,
 * exposing only the two actions the verification harness needs deterministically —
 * **reset** and **seed**.
 *
 * Seeding posts the canonical GROUND-TRUTH scenario, so any run can put the store into a
 * known state rather than depending on whatever the last agent left behind. That is the
 * concrete fix for the shared-store races that made browser results provisional.
 */

import { useState } from 'react'
import { api, type AppState } from '../../lib/api'
import { PillButton } from '../../ui'

/** The GROUND-TRUTH fixture, ids fixed so runs are reproducible. */
export const GROUND_TRUTH_ONBOARDING = {
  name: 'Vlad',
  currencyCode: 'RON',
  monthlyIncome: '9000',
  accounts: [
    { id: 'AAAA0000-0000-0000-0000-000000000001', name: 'Main Account', accountType: 'primary', isPrimary: true, isPrimarySavings: false, currentBalance: '0' },
    { id: 'BBBB0000-0000-0000-0000-000000000002', name: 'Emergency Fund', accountType: 'emergency', isPrimary: false, isPrimarySavings: false, emergencyMultiplier: 3, currentBalance: '0' },
    { id: 'CCCC0000-0000-0000-0000-000000000003', name: 'Savings', accountType: 'savings', isPrimary: false, isPrimarySavings: true, currentBalance: '0' },
  ],
  expenses: [
    { id: 'E1000000-0000-0000-0000-000000000001', name: 'Food', amount: '1200', frequency: 'monthly', icon: 'cart.fill', categoryId: 'D1A00007-0000-0000-0000-000000000007', isEnabled: true },
    { id: 'E2000000-0000-0000-0000-000000000002', name: 'Rent', amount: '2500', frequency: 'monthly', icon: 'house.fill', categoryId: 'D1A00004-0000-0000-0000-000000000004', isEnabled: true },
    { id: 'E3000000-0000-0000-0000-000000000003', name: 'Gas', amount: '450', frequency: 'monthly', icon: 'fuelpump.fill', categoryId: 'D1A00001-0000-0000-0000-000000000001', isEnabled: true },
    { id: 'E4000000-0000-0000-0000-000000000004', name: 'Streaming', amount: '120', frequency: 'monthly', icon: 'tv.fill', categoryId: 'D1A00002-0000-0000-0000-000000000002', isEnabled: true },
  ],
  savings: { percentage: 0.25, allocationMode: 'prioritized', savingsInputMode: 'percentage' },
  remainingMoneyDestination: 'primarySavings',
} as const

export function DevTools({
  onStateChange,
  onClose,
}: {
  onStateChange: (next: AppState) => void
  onClose: () => void
}) {
  const [busy, setBusy] = useState(false)
  const run = (work: () => Promise<AppState>) => {
    setBusy(true)
    void work()
      .then(onStateChange)
      .finally(() => setBusy(false))
  }

  // Belt and braces: the caller also gates on DEV, but a component that must never ship
  // should refuse to render on its own account too.
  if (!import.meta.env.DEV) return null

  return (
    <div className="devtools" data-testid="dev-tools-sheet">
      <PillButton variant="glass" disabled={busy} testId="dev-reset" onClick={() => run(() => api.reset())}>
        Reset store
      </PillButton>
      <PillButton
        variant="glass"
        disabled={busy}
        testId="dev-seed"
        onClick={() =>
          run(() => api.reset().then(() => api.completeOnboarding(GROUND_TRUTH_ONBOARDING as never)))
        }
      >
        Seed ground truth
      </PillButton>
      <PillButton variant="plain" onClick={onClose} testId="dev-close">
        Close
      </PillButton>
    </div>
  )
}
