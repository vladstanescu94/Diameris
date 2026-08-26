/**
 * The onboarding preview — the ONLY source of every number these seven screens show.
 *
 * DECISIONS.md R2: the client computes nothing. "After expenses 4,730 RON", "That's
 * 1,182 RON/month", the emergency target, the whole transfer plan and `isBalanced` all
 * come back from `POST /api/onboarding/preview`, which runs the same Swift `Domain` the
 * iOS app compiles. The draft goes up, formatted strings come down.
 *
 * The request is debounced because it fires on every keystroke of an amount field; it is
 * abortable because a stale response must never overwrite a newer one.
 */

import { useEffect, useRef, useState } from 'react'
import { ApiError, http } from '../../lib/api'
import { toPayload } from './draft'
import type { OnboardingDraft, OnboardingPreviewExt } from './types'

/** Long enough to coalesce typing, short enough that the caption feels live. */
const DEBOUNCE_MS = 120

export interface PreviewResult {
  /** `null` until the first response arrives. Screens render nothing numeric until then. */
  readonly preview: OnboardingPreviewExt | null
  readonly error: string | null
}

export function useOnboardingPreview(draft: OnboardingDraft): PreviewResult {
  const [preview, setPreview] = useState<OnboardingPreviewExt | null>(null)
  const [error, setError] = useState<string | null>(null)

  // Serialising the payload is what makes the effect fire on real changes only — the draft
  // object identity changes on every keystroke, including ones that do not affect the plan.
  const payload = JSON.stringify(toPayload(draft))
  const latest = useRef(0)

  useEffect(() => {
    const controller = new AbortController()
    const generation = latest.current + 1
    latest.current = generation

    const timer = setTimeout(() => {
      http
        .post<OnboardingPreviewExt>('/onboarding/preview', JSON.parse(payload), {
          signal: controller.signal,
        })
        .then((next) => {
          if (latest.current !== generation) return
          setPreview(next)
          setError(null)
        })
        .catch((cause: unknown) => {
          if (controller.signal.aborted) return
          setError(cause instanceof ApiError ? cause.reason : String(cause))
        })
    }, DEBOUNCE_MS)

    return () => {
      clearTimeout(timer)
      controller.abort()
    }
  }, [payload])

  return { preview, error }
}
