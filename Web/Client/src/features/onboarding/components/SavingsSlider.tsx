/**
 * `SavingsSlider` — PARITY-SPEC §2.6.1, and the sharp end of DECISIONS.md **R13**.
 *
 * The two things this component renders — the big `25` and `"That's 1,182 RON/month"` —
 * are, on iOS, `Int(percentage * 100)` and `availableIncome × percentage`, recomputed on
 * every frame of the drag. Both are forbidden here (R2), and a request per frame is not an
 * option, so R13 rules that the server sends a **precomputed position table** and dragging
 * becomes an array-index lookup.
 *
 * `savingsSliderPositions` now ships on `POST /api/onboarding/preview` (46 rows, 0.05…0.50
 * at step 0.01), so the slider is live: `value` is the row index, and the percent label,
 * the amount caption and even the "Great savings rate!" predicate are all read out of the
 * selected row. Nothing here multiplies, divides or truncates.
 *
 * The `positions == null` branch is kept as the honest degradation for a server that has
 * not sent the table (older build, failed request): the slider renders inert rather than
 * inventing a label locally, which is exactly the failure R13 exists to prevent.
 */

import type { TFunction } from '../../../lib/i18n'
import { Symbol } from '../../../lib/icons'
import { Badge, Slider } from '../../../ui'
import type { SavingsSliderPosition } from '../types'

const PERCENT_SIGN = '%'

/** `"25%"` → `{ number: "25", sign: "%" }`; anything else passes through untouched. */
export function splitPercent(display: string | null | undefined): {
  number: string
  sign: string
} {
  if (!display) return { number: '', sign: '' }
  return display.endsWith(PERCENT_SIGN)
    ? { number: display.slice(0, -PERCENT_SIGN.length), sign: PERCENT_SIGN }
    : { number: display, sign: '' }
}

/**
 * iOS's slider is **continuous** and snaps to one of seven values when the drag lands
 * within `snapThreshold` of it (`SavingsSlider.swift:112-129`). Both the values and the
 * threshold are served on `reference.savingsConstants`, so the behaviour is reproduced
 * from server data rather than reinvented.
 *
 * A consequence worth stating, because it looks like a bug and is not: **some rates are
 * unreachable on iOS.** Any drag position within 0.02 of a snap value collapses onto it,
 * so 9 %, 11 %, 14 % and friends cannot be selected by dragging. We reproduce that.
 *
 * ⚠️ `stepped` exists because a native range input is not a finger. Arrow keys move one
 * 0.01 position, which lands *inside* the snap radius and is immediately pulled back — so
 * with unconditional snapping the thumb **cannot leave 10 %** and the control becomes
 * keyboard-inaccessible. iOS has no such trap: its keyboard/VoiceOver path is
 * `accessibilityAdjustableAction`, which steps by `accessibilityStep` (0.05) and does
 * **not** snap at all (§2.6.1). So single-step changes skip the snap, matching the iOS
 * accessibility path, while multi-step changes (drags) snap, matching the gesture.
 *
 * This is a *selection* rule over percentages, not a money computation: whatever it
 * returns is still looked up in the position table by exact equality, so every displayed
 * string remains server-formatted (R2 intact). All seven snap values are multiples of the
 * served 0.01 step, so a snapped value is always present in the table.
 */
export function snapPercentage(
  percentage: number,
  snapValues: readonly number[],
  snapThreshold: number,
  stepped = false,
): number {
  if (stepped) return percentage
  // ⚠️ STRICT `<`, matching `abs(newPercentage - snapValue) < snapThreshold`
  // (`SavingsSlider.swift:123`). At exactly `snapThreshold` away iOS does NOT snap, and the
  // first match in ascending order wins (Swift `break`s), which is what `.find` does.
  return snapValues.find((value) => Math.abs(value - percentage) < snapThreshold) ?? percentage
}

export interface SavingsSliderProps {
  /** R13's table. `null` until the server serves it. */
  positions: readonly SavingsSliderPosition[] | null
  /** `reference.savingsConstants.snapValues` — the 7 values from `SavingsSlider.swift:119`. */
  snapValues: readonly number[]
  snapThreshold: number
  /** The draft's current rate — only ever compared, never scaled. */
  percentage: number
  /** Server-formatted, pre-truncated, e.g. `"25%"`. */
  percentDisplay: string | null
  /** Server-formatted savings amount for the current rate, e.g. `"1,182 RON"`. */
  savingsDisplay: string | null
  onChangePercentage: (percentage: number) => void
  t: TFunction
}

export function SavingsSlider({
  positions,
  snapValues,
  snapThreshold,
  percentage,
  percentDisplay,
  savingsDisplay,
  onChangePercentage,
  t,
}: SavingsSliderProps) {
  const index = positions?.findIndex((position) => position.percentage === percentage) ?? -1
  const current = index >= 0 ? positions?.[index] : undefined

  const label = current?.percentDisplay ?? percentDisplay
  const amount = current?.savings.display ?? savingsDisplay

  // The badge predicate (`0.20 <= percentage <= 0.30`, `SavingsSlider.swift:245`) is
  // decided server-side per row, so even this comparison is not made here.
  const showsBadge = current?.showsGreatRateBadge ?? false

  return (
    <div className="ob-stack-md">
      {/*
        iOS renders the number at 48pt rounded-bold accentPrimary and the `%` separately at
        `.title2` secondary (§2.6.1). The server sends one string ("25%"), so the sign is
        split off by suffix — string surgery, never arithmetic, and it degrades to printing
        the whole string unchanged if a locale ever formats percentages differently.
      */}
      <p className="ob-savings-percent">
        <span className="ob-savings-percent__value" data-testid="onb-savings-percent-value">
          {splitPercent(label).number}
        </span>
        {splitPercent(label).sign && (
          <span className="ob-savings-percent__sign">{splitPercent(label).sign}</span>
        )}
      </p>
      {amount !== null && amount !== undefined && (
        <p className="ob-savings-caption" data-testid="onb-savings-permonth-caption">
          {t("That's %@/month", [amount])}
        </p>
      )}

      {positions ? (
        <Slider
          value={index >= 0 ? index : 0}
          min={0}
          max={positions.length - 1}
          step={1}
          onChange={(nextIndex) => {
            const next = positions[nextIndex]
            if (!next) return
            // One position at a time == an arrow key; anything larger == a drag or a
            // track click. Only the latter snaps.
            const stepped = index >= 0 && Math.abs(nextIndex - index) === 1
            onChangePercentage(
              snapPercentage(next.percentage, snapValues, snapThreshold, stepped),
            )
          }}
          ariaLabel={t('Savings percentage')}
          ariaValueText={label ?? ''}
          // Required by the parity contract (`Verify/parity/testids.ts` -> savingsPercentSlider).
          // I asked Frontend for this prop, wired the modal ids when it landed, and never came
          // back for this one — the same miss as `onb-name-field`, which stalled a whole
          // screenshot sweep. A missing test id does not degrade a run, it fails it.
          testId="onb-savings-percent-slider"
          ticks={{
            // ⚠️ "5%" and "50%" are raw, unlocalized literals on iOS (§2.6.1).
            start: t('5%'),
            // ⚠️ `"25% recommended"` is ONE literal key in the Onboarding catalog, not an
            // interpolation — iOS hardcodes the figure. Composing it from the recommended
            // row's `percentDisplay` would miss the catalog entry and ship English in RO.
            center: t('25% recommended'),
            end: t('50%'),
          }}
        />
      ) : (
        <p className="ob-blocked">
          <Symbol name="exclamationmark.triangle" size="var(--icon-sm)" />
          {t(
            'Savings rate adjustment is unavailable until the server provides the slider positions.',
          )}
        </p>
      )}

      {showsBadge && (
        <div className="ob-savings-badge">
          <Badge tone="secondary" icon="checkmark.circle.fill">
            {t('Great savings rate!')}
          </Badge>
        </div>
      )}
    </div>
  )
}
