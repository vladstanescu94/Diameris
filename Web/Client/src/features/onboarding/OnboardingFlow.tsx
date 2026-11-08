/**
 * The onboarding container — PARITY-SPEC §2.0.
 *
 * Seven screens, a five-dot indicator, and **no back navigation**: `advance()` only ever
 * moves forward, exactly as `OnboardingViewModel.advance()` does. Neither `7` nor `5` is
 * written down here — the step list and the dot list both come from `state/viewState`.
 *
 * The draft lives here; every number on every screen comes from
 * `POST /api/onboarding/preview` (see `usePreview.ts`). The only mutating call in the
 * whole flow is `POST /api/onboarding/complete`, fired by the last button.
 */

import { useCallback, useMemo, useState } from 'react'
import { api, type AppState } from '../../lib/api'
import { useI18n, useT } from '../../lib/i18n'
import {
  ONBOARDING_STEPS,
  nextOnboardingStep,
  onboardingIndicator,
  type OnboardingStep,
} from '../../state/viewState'
import { createDraft, toPayload } from './draft'
import { useOnboardingPreview } from './usePreview'
import { AccountsScreen } from './screens/AccountsScreen'
import { ExpensesScreen } from './screens/ExpensesScreen'
import { IncomeScreen } from './screens/IncomeScreen'
import { NameScreen } from './screens/NameScreen'
import { SavingsScreen } from './screens/SavingsScreen'
import { SummaryScreen } from './screens/SummaryScreen'
import { WelcomeScreen } from './screens/WelcomeScreen'
import type { StepProps } from './screens/shared'
import type { OnboardingDraft } from './types'
import './onboarding.css'

export interface OnboardingFlowProps {
  /** The state fetched by the shell — supplies `reference`, `categories` and defaults. */
  state: AppState
  /** Called with the complete `AppState` the server returns from `/onboarding/complete`. */
  onComplete: (state: AppState) => void
  /** Overridable so a harness can deep-link a screen; defaults to `welcome`. */
  initialStep?: OnboardingStep
}

export function OnboardingFlow({ state, onComplete, initialStep = 'welcome' }: OnboardingFlowProps) {
  const t = useT('onboarding')
  const { translate } = useI18n()
  const tDomain = useT('domain')

  const [step, setStep] = useState<OnboardingStep>(initialStep)
  const [draft, setDraft] = useState<OnboardingDraft>(() =>
    createDraft({
      translateOnboarding: (key) => translate('onboarding', key),
      translateDomain: (key) => translate('domain', key),
      // The profile's currency if onboarding is being re-run, else the server's first.
      currencyCode: state.profile?.currencyCode ?? state.reference.currencies[0]?.value ?? 'RON',
      categories: state.categories,
    }),
  )
  const [completing, setCompleting] = useState(false)
  const [completionError, setCompletionError] = useState<string | null>(null)

  const { preview } = useOnboardingPreview(draft)

  const advance = useCallback(() => {
    setStep((current) => nextOnboardingStep(current) ?? current)
  }, [])

  const update = useCallback(
    (transform: (draft: OnboardingDraft) => OnboardingDraft) => setDraft(transform),
    [],
  )

  const indicator = onboardingIndicator(step)
  const indicatorLabel = indicator
    ? t('Step %lld of %lld', [indicator.position, indicator.total])
    : undefined

  const stepProps: StepProps = useMemo(
    () => ({ draft, update, preview, state, t, tDomain, advance, indicatorLabel }),
    [draft, update, preview, state, t, tDomain, advance, indicatorLabel],
  )

  const complete = useCallback(() => {
    setCompleting(true)
    // `persisting: true` drops the zero-amount expense rows, exactly as
    // `OnboardingViewModel.save` does (PARITY-SPEC §2.8 step 3).
    api
      .completeOnboarding(toPayload(draft, true))
      .then(onComplete)
      .catch((cause: unknown) => {
        setCompleting(false)
        setCompletionError(String(cause))
      })
  }, [draft, onComplete])

  switch (step) {
    case 'welcome':
      return <WelcomeScreen {...stepProps} />
    case 'name':
      return <NameScreen {...stepProps} />
    case 'income':
      return <IncomeScreen {...stepProps} />
    case 'accounts':
      return <AccountsScreen {...stepProps} />
    case 'expenses':
      return <ExpensesScreen {...stepProps} />
    case 'savings':
      return <SavingsScreen {...stepProps} />
    case 'summary':
      return (
        <>
          <SummaryScreen {...stepProps} onComplete={complete} completing={completing} />
          {completionError !== null && (
            <p className="ob-blocked" role="alert">
              {completionError}
            </p>
          )}
        </>
      )
  }
}

/** Re-exported so a harness can iterate the flow without importing the state module. */
export { ONBOARDING_STEPS }
