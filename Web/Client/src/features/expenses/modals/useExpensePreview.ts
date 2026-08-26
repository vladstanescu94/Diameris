/**
 * The "Monthly Equivalent" row's value, from `POST /api/expenses/preview`.
 *
 * ## Why this is a round trip and not a division
 *
 * iOS renders `amount × Frequency.annual.monthlyMultiplier` (`AddExpenseSheet.swift:32-35`)
 * — a **÷ 12**, not the `× 12` that DECISIONS.md R18 records. R18 grants a narrow exception
 * allowing that one multiply client-side, and taking it would have been wrong twice over:
 *
 *  1. **Direction.** Implementing R18 literally is 144× off.
 *  2. **Value, not just rounding.** The multiplier is `Decimal(1)/12` at 28 significant
 *     digits, so `1266 × multiplier = 105.4999…` and iOS renders **105**. JS `1266 / 12` is
 *     exactly `105.5` and any correct half-even rounding gives **106**. The disagreement is
 *     in the *operand*, so no amount of careful rounding in `money.ts` recovers it.
 *     (Found by Backend while writing the test for this endpoint; gap B11.)
 *
 * `showsMonthlyEquivalent` carries iOS's render gate (annual **and** amount > 0) so even
 * the condition is not reimplemented here.
 */

import { useEffect, useRef, useState } from 'react'
import { http, type FrequencyValue, type MoneyValue } from '../../../lib/api'
import type { Money } from '../../../lib/money'

/** Long enough to coalesce typing, short enough that the row feels live. */
const DEBOUNCE_MS = 120

export interface ExpensePreview {
  readonly amount: MoneyValue
  readonly monthlyAmount: MoneyValue
  readonly annualAmount: MoneyValue
  readonly monthlyEquivalent: MoneyValue
  /** iOS's gate: `frequency == .annual && amount > 0`. Render the row iff this is true. */
  readonly showsMonthlyEquivalent: boolean
}

export function useExpensePreview(
  amount: Money,
  frequency: FrequencyValue,
): ExpensePreview | null {
  const [preview, setPreview] = useState<ExpensePreview | null>(null)
  const latest = useRef(0)

  useEffect(() => {
    const controller = new AbortController()
    const generation = latest.current + 1
    latest.current = generation

    const timer = setTimeout(() => {
      http
        .post<ExpensePreview>(
          '/expenses/preview',
          { amount, frequency },
          { signal: controller.signal },
        )
        .then((next) => {
          // A stale response must never overwrite a newer one.
          if (latest.current === generation) setPreview(next)
        })
        .catch(() => {
          // The row simply does not render if the server cannot supply it — never a
          // locally-computed fallback, which is the whole point of the round trip.
          if (latest.current === generation) setPreview(null)
        })
    }, DEBOUNCE_MS)

    return () => {
      clearTimeout(timer)
      controller.abort()
    }
  }, [amount, frequency])

  return preview
}
