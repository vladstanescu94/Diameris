/**
 * `RemainingMoneyPicker` — PARITY-SPEC §2.7.1, DECISIONS.md R23.
 *
 * Destination order is `[primarySavings?, primary, personal?]` — "Keep in Primary" always
 * sits **between** the two optionals. The default is `.primarySavings` and, in the normal
 * path, it is inserted at index 0 and is therefore **already selected** on first paint.
 *
 * ⚠️ Upstream bug reproduced deliberately (R23, logged in `PARITY-GAPS.md`): with no
 * savings account, `.primarySavings` is not among the destinations yet remains the
 * selected value, so **no card renders selected** — and at save the remaining money is
 * credited to nothing. Showing a card selected here would hide a real defect.
 */

import type { RemainingMoneyDestinationRef, RemainingMoneyDestinationValue } from '../../../lib/api'
import type { TFunction } from '../../../lib/i18n'
import { Symbol } from '../../../lib/icons'

export interface RemainingMoneyPickerProps {
  /** `state.reference.remainingMoneyDestinations` — never a hardcoded list. */
  destinations: readonly RemainingMoneyDestinationRef[]
  hasPrimarySavings: boolean
  hasPersonal: boolean
  value: RemainingMoneyDestinationValue
  onChange: (value: RemainingMoneyDestinationValue) => void
  t: TFunction
  tDomain: TFunction
}

/** `RemainingMoneyPicker.swift:20-32` — assembled in this exact order. */
export function availableDestinations(
  destinations: readonly RemainingMoneyDestinationRef[],
  hasPrimarySavings: boolean,
  hasPersonal: boolean,
): readonly RemainingMoneyDestinationRef[] {
  const find = (value: string) => destinations.find((entry) => entry.value === value)
  const primary = find('primary')
  const savings = find('primarySavings')
  const personal = find('personal')
  const ordered: RemainingMoneyDestinationRef[] = []
  if (hasPrimarySavings && savings) ordered.push(savings)
  if (primary) ordered.push(primary)
  if (hasPersonal && personal) ordered.push(personal)
  return ordered
}

export function RemainingMoneyPicker({
  destinations,
  hasPrimarySavings,
  hasPersonal,
  value,
  onChange,
  t,
  tDomain,
}: RemainingMoneyPickerProps) {
  const available = availableDestinations(destinations, hasPrimarySavings, hasPersonal)

  return (
    <div className="ob-stack-sm" role="group" aria-label={t('Where should this go?')}>
      {available.map((destination) => {
        const selected = destination.value === value
        return (
          <button
            key={destination.value}
            type="button"
            className="ob-destination"
            data-testid={
              destination.value === 'primarySavings'
                ? 'onb-summary-remaining-choice-savings'
                : destination.value === 'primary'
                  ? 'onb-summary-remaining-choice-primary'
                  : undefined
            }
            aria-pressed={selected}
            onClick={() => onChange(destination.value)}
          >
            <span className="ob-destination__icon">
              <Symbol name={destination.icon} size="var(--icon-md)" />
            </span>
            <span className="ob-destination__text">
              <span className="ob-destination__title">{tDomain(destination.displayName)}</span>
              <span className="ob-destination__description">
                {tDomain(destination.description)}
              </span>
            </span>
            {selected && (
              <span className="ob-destination__check">
                <Symbol name="checkmark.circle.fill" size="var(--icon-md)" />
              </span>
            )}
          </button>
        )
      })}
    </div>
  )
}
