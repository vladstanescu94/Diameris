/** Welcome — PARITY-SPEC §2.1. No progress indicator on this screen. */

import { Symbol } from '../../../lib/icons'
import { PillButton } from '../../../ui'
import { OnboardingScreen } from '../components/Chrome'
import type { StepProps } from './shared'

/** §2.1 step 3 — icon, colour and text, in order. */
const BULLETS: readonly { icon: string; color: string; text: string }[] = [
  { icon: 'target', color: 'var(--accent-secondary)', text: 'Set savings goals that fill automatically' },
  {
    icon: 'arrow.left.arrow.right',
    color: 'var(--accent-primary)',
    text: 'Know exactly where to transfer your money',
  },
  {
    icon: 'chart.line.uptrend.xyaxis',
    color: 'var(--accent-secondary)',
    text: 'Watch your progress grow',
  },
]

export function WelcomeScreen({ t, advance }: StepProps) {
  return (
    <OnboardingScreen
      step="welcome"
      indicatorLabel={undefined}
      centered
      footer={
        <PillButton fullWidth onClick={advance}>
          {t("Let's Go")}
        </PillButton>
      }
    >
      <div className="ob-hero" aria-hidden>
        <span className="ob-hero__glow" />
        <span className="ob-hero__circle">
          <Symbol name="sparkles" size="var(--icon-hero)" />
        </span>
      </div>

      <div className="ob-welcome__content">
        <h1 className="ob-welcome__title">{t('Take control of your money')}</h1>
        {/* Note the em dash — it is part of the key. */}
        <p className="ob-welcome__subtitle">
          {t(
            "In the next few minutes, we'll build your personalized transfer plan — so payday becomes effortless.",
          )}
        </p>
      </div>

      <ul className="ob-bullets">
        {BULLETS.map((bullet) => (
          <li key={bullet.icon} className="ob-bullet">
            <span className="ob-bullet__icon" style={{ color: bullet.color }} aria-hidden>
              <Symbol name={bullet.icon} size="var(--font-body-size)" />
            </span>
            {t(bullet.text)}
          </li>
        ))}
      </ul>
    </OnboardingScreen>
  )
}
