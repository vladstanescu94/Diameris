/** Name — PARITY-SPEC §2.2. Continue is disabled until 1…50 trimmed characters. */

import { PillButton, TextField } from '../../../ui'
import { OnboardingHeader, OnboardingScreen } from '../components/Chrome'
import { isNameValid } from '../draft'
import type { StepProps } from './shared'

export function NameScreen({ draft, update, t, advance, indicatorLabel }: StepProps) {
  const canAdvance = isNameValid(draft)

  return (
    // A form so Return submits — iOS gives the field `.submitLabel(.continue)` and advances
    // on submit when `canAdvance` (§2.2). Focus is deliberately NOT auto-set, matching iOS.
    <form
      onSubmit={(event) => {
        event.preventDefault()
        if (canAdvance) advance()
      }}
    >
      <OnboardingScreen
        step="name"
        indicatorLabel={indicatorLabel}
        centered
        footer={
          <PillButton fullWidth type="submit" disabled={!canAdvance}>
            {t('Continue')}
          </PillButton>
        }
      >
        <OnboardingHeader
          icon="person.circle.fill"
          title={t("First, let's get acquainted")}
          subtitle={t('What should we call you?')}
        />
        <TextField
          value={draft.name}
          onChange={(name) => update((current) => ({ ...current, name }))}
          placeholder={t('Your name')}
          ariaLabel={t('Your name')}
          // Required by the parity contract (`Verify/parity/testids.ts` → `nameField`).
          // Its absence stalled the entire visual sweep: `stepName()` fills by test id, so
          // every screenshot after this one — 17 screens × 2 themes × 2 viewports — never
          // captured, and the run failed as a 180s timeout on a *correctly* disabled
          // Continue button. A missing test id reads as a broken screen.
          testId="onb-name-field"
        />
      </OnboardingScreen>
    </form>
  )
}
