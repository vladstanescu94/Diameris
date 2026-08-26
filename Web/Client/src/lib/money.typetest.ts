/**
 * Compile-time assertions for DECISIONS.md **R24**.
 *
 * This file contains no runtime tests. Every `@ts-expect-error` below fails
 * `npm run build` (`tsc --noEmit`) if the line it guards STOPS being an error — i.e. if
 * someone widens a branded type and quietly reopens the display→input hole. TypeScript
 * reports an unused `@ts-expect-error` as an error of its own, so this cuts both ways:
 * the protection cannot silently disappear.
 *
 * Why compile-time rather than a unit test: the bug is a *type* confusion between three
 * `string`s. A runtime test would have to guess which of them a caller passed, which is
 * exactly the thing that cannot be observed at runtime.
 */

import {
  displayString,
  editingString,
  formatForDisplay,
  formatForEditing,
  money,
  type DisplayString,
  type EditingString,
  type Money,
} from './money'

declare function acceptsEditing(value: EditingString): void
declare function acceptsDisplay(value: DisplayString): void
declare function acceptsMoney(value: Money): void

const display = displayString('9,000 RON')
const editing = editingString('9000')
const amount = money('9000')

/* --- The R24 bug itself: a display string must never reach an input. -------- */

// @ts-expect-error — `"9,000 RON"` in an AmountField parses to 9. This is THE bug.
acceptsEditing(display)

// @ts-expect-error — raw strings must go through `editingString()` so the cast is visible.
acceptsEditing('9000')

// @ts-expect-error — an `amount` is not an editing string; it ignores the locale separator.
acceptsEditing(amount)

/* --- ...and the reverse directions, so the brands are not one-way. ---------- */

// @ts-expect-error — never render an editing string as a final amount.
acceptsDisplay(editing)

// @ts-expect-error — `display` carries a currency code and grouping; it is not an amount.
acceptsMoney(display)

// @ts-expect-error — `editing` is locale-formatted; submit the canonical `amount`.
acceptsMoney(editing)

/* --- What SHOULD compile, so the brands are not merely blocking everything. -- */

acceptsEditing(editing)
acceptsDisplay(display)
acceptsMoney(amount)
acceptsEditing(editingString('1182,5'))
acceptsDisplay(formatForDisplay(amount, 'RON'))
acceptsEditing(formatForEditing(amount))

/* --- Branded strings stay usable as strings where that is genuinely fine. ---- */

const rendered: string = display
const length: number = editing.length
const interpolated = `${display}`

export type _Unused = [typeof rendered, typeof length, typeof interpolated]
