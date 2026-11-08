/** The props every onboarding step receives from `OnboardingFlow`. */

import type { AppState } from '../../../lib/api'
import type { TFunction } from '../../../lib/i18n'
import type { OnboardingDraft, OnboardingPreviewExt } from '../types'

export interface StepProps {
  readonly draft: OnboardingDraft
  /** Applies a pure draft transform from `draft.ts`. */
  readonly update: (transform: (draft: OnboardingDraft) => OnboardingDraft) => void
  /** `null` until the first `/onboarding/preview` response lands. */
  readonly preview: OnboardingPreviewExt | null
  readonly state: AppState
  /** `onboarding` catalog. */
  readonly t: TFunction
  /** `domain` catalog — enum display names and descriptions resolve there (R4). */
  readonly tDomain: TFunction
  readonly advance: () => void
  /** `undefined` on welcome and summary. */
  readonly indicatorLabel: string | undefined
}
