/**
 * Shared onboarding chrome — the progress indicator, the header, and the screen scaffold
 * every step is poured into (PARITY-SPEC §2.0, §2.0.1, §2.0.2).
 */

import type { CSSProperties, ReactNode } from 'react'
import { Symbol } from '../../../lib/icons'
import { AppColumn, Surface } from '../../../ui'
import {
  ONBOARDING_INDICATOR_STEPS,
  onboardingIndicator,
  type OnboardingStep,
} from '../../../state/viewState'

/* ================================================================== *
 * Progress indicator — 5 dots over a 280x4 gradient track
 * ================================================================== */

export interface ProgressIndicatorProps {
  step: OnboardingStep
  /** Localized "Step %lld of %lld" for assistive tech; the visual has no text (§2.0.1). */
  ariaLabel: string
}

/**
 * ⚠️ The one place onboarding does arithmetic, and it is explicitly **not** an R2
 * violation: DECISIONS.md R18 "Explicitly NOT R2 violations" names
 * `OnboardingProgressIndicator.swift:19` as client-owned *navigation* state, not business
 * data. Reading R2 wider would force an API round-trip per onboarding step.
 *
 * Neither `7` nor `5` appears here — the dots come from `ONBOARDING_INDICATOR_STEPS`.
 */
export function ProgressIndicator({ step, ariaLabel }: ProgressIndicatorProps) {
  const indicator = onboardingIndicator(step)
  if (!indicator) return null

  const dotIndex = indicator.position - 1
  const lastIndex = indicator.total - 1
  // `progress + 0.05` — the sliver that keeps step 1 visible (§2.0.1).
  const fill = lastIndex === 0 ? 1 : dotIndex / lastIndex + 0.05

  return (
    <div
      className="ob-progress"
      role="progressbar"
      aria-label={ariaLabel}
      aria-valuenow={indicator.position}
      aria-valuemin={1}
      aria-valuemax={indicator.total}
      style={{ '--ob-progress-fill': fill } as CSSProperties}
    >
      <div className="ob-progress__track" />
      <div className="ob-progress__fill" />
      {/* Reviewer's testid contract: the dot count is asserted from this list, and the
          active dot is identified by `data-active`, never by class name. */}
      <div className="ob-progress__dots" data-testid="onb-progress-dots" aria-hidden>
        {ONBOARDING_INDICATOR_STEPS.map((indicatorStep, index) => (
          <span
            key={indicatorStep}
            data-testid="onb-progress-dot"
            data-active={index === dotIndex ? 'true' : 'false'}
            className={[
              'ob-progress__dot',
              index <= dotIndex ? 'ob-progress__dot--completed' : '',
              index === dotIndex ? 'ob-progress__dot--current' : '',
            ]
              .filter(Boolean)
              .join(' ')}
          />
        ))}
      </div>
    </div>
  )
}

/* ================================================================== *
 * Header
 * ================================================================== */

export interface OnboardingHeaderProps {
  icon: string
  iconColor?: string
  title: string
  subtitle?: string
  /** `useHeroIcon` — 80pt glyph and a `.largeTitle`. */
  hero?: boolean
}

export function OnboardingHeader({
  icon,
  iconColor = 'var(--accent-primary)',
  title,
  subtitle,
  hero = false,
}: OnboardingHeaderProps) {
  return (
    <header className="ob-header">
      <span className="ob-header__icon" style={{ color: iconColor }}>
        <Symbol name={icon} size={hero ? 'var(--icon-hero)' : 'var(--icon-xxl)'} />
      </span>
      <h1 className={hero ? 'ob-header__title ob-header__title--hero' : 'ob-header__title'}>
        {title}
      </h1>
      {subtitle && <p className="ob-header__subtitle">{subtitle}</p>}
    </header>
  )
}

/* ================================================================== *
 * Screen scaffold
 * ================================================================== */

export interface OnboardingScreenProps {
  step: OnboardingStep
  /**
   * Localized indicator label, or `undefined` on welcome/summary — the two screens that
   * hide the indicator entirely. Always passed (never omitted) so
   * `exactOptionalPropertyTypes` stays satisfied at every call site.
   */
  indicatorLabel: string | undefined
  /** `Spacer → content → Spacer → CTA` screens (welcome, name, income). */
  centered?: boolean
  children: ReactNode
  /** The CTA stack — `Continue` and, on two screens, `Skip for now`. */
  footer?: ReactNode
}

export function OnboardingScreen({
  step,
  indicatorLabel,
  centered = false,
  children,
  footer,
}: OnboardingScreenProps) {
  return (
    <Surface>
      <AppColumn>
        <div
          className={centered ? 'ob-screen ob-screen--centered' : 'ob-screen'}
          data-testid={`onb-${step}`}
        >
          {indicatorLabel !== undefined && (
            <ProgressIndicator step={step} ariaLabel={indicatorLabel} />
          )}
          <div className="ob-screen__body">{children}</div>
          {footer && <div className="ob-screen__footer">{footer}</div>}
        </div>
      </AppColumn>
    </Surface>
  )
}

/* ================================================================== *
 * Small shared bits
 * ================================================================== */

/** `info.circle` + caption, the footnote pattern on accounts/expenses (§2.4, §2.5). */
export function Helper({ text }: { text: string }) {
  return (
    <p className="ob-helper">
      <span className="ob-helper__icon">
        <Symbol name="info.circle" size="var(--font-caption-size)" />
      </span>
      {text}
    </p>
  )
}

export function SectionTitle({
  children,
  secondary = false,
}: {
  children: ReactNode
  secondary?: boolean
}) {
  return (
    <h2 className={secondary ? 'ob-section__title ob-section__title--secondary' : 'ob-section__title'}>
      {children}
    </h2>
  )
}
