/**
 * Money — decimal strings, never JS numbers.
 *
 * ┌──────────────────────────────────────────────────────────────────────────────┐
 * │ DECISIONS.md R2 — THE CLIENT PERFORMS ZERO NUMERIC WORK.                      │
 * │                                                                              │
 * │ The server sends every monetary value as                                     │
 * │     { amount: "1182.5", display: "1,182 RON", editing: "1182.5" }            │
 * │ where `display` and `editing` are produced by the *same* Swift               │
 * │ `Utilities.AmountFormatter` the iOS app compiles (API-CONTRACT §0.1).        │
 * │                                                                              │
 * │ **Render `display` verbatim. Never re-format it.** Percentages arrive        │
 * │ pre-truncated (`percentDisplay: "10%"`), and `isBalanced` arrives as a       │
 * │ boolean. If a screen appears to need a number the API does not provide,      │
 * │ that is a missing server field — ask Backend. Never compute it here, not     │
 * │ even a trivial-looking sum.                                                  │
 * └──────────────────────────────────────────────────────────────────────────────┘
 *
 * What this module is therefore *for*:
 *   1. `Money` — the branded decimal-string type used for request payloads.
 *   2. `parseUserInput` — local input parsing, reproducing the iOS comma quirk.
 *      (`POST /api/parse-amount` is the exact-parity alternative; see below.)
 *   3. `formatForEditing` — prefilling an input from a bare `amount` when no
 *      server-side `editing` string is at hand.
 *   4. `formatNumber` / `formatForDisplay` — **SAFETY NET AND TEST ORACLE ONLY.**
 *      Not for production rendering. They exist so the money tests can assert the
 *      iOS rounding rule independently, and so a parity harness has a second
 *      opinion. Two formatters must never silently compete: if you are about to
 *      call `formatForDisplay` in a component, you want the server's `display`.
 *
 * TEAM.md hard rule 4: money never becomes a JS `number`. Nothing in this file is
 * passed through `Number` / `parseFloat` / arithmetic operators — every routine
 * below manipulates digit strings directly.
 *
 * iOS reference — `Packages/Core/Utilities/Sources/Utilities/AmountFormatter.swift`:
 *
 *   formatForDisplay: NumberFormatter, numberStyle .decimal, maximumFractionDigits 0,
 *                     groupingSeparator ",", then " \(currency)" appended.
 *   formatForEditing: NumberFormatter, .decimal, max 2 / min 0 fraction digits,
 *                     groupingSeparator "", and "" for amounts <= 0.
 *   parse:            replaces "," with "." then `Decimal(string:)`.
 *
 * NumberFormatter's default `roundingMode` is `.halfEven` (banker's rounding), which is
 * what produces the two ground-truth cases: 1182.5 -> "1,182" (2 is even) and
 * 3547.5 -> "3,548" (7 is odd, rounds up to the even 8). Note that `Intl.NumberFormat`,
 * `Math.round` and `toFixed` all round half-up and would emit "1,183" — which is exactly
 * why R2 moved this responsibility to the server.
 */

declare const moneyBrand: unique symbol
declare const displayBrand: unique symbol
declare const editingBrand: unique symbol

/** A canonical decimal string, e.g. `"1182.5"`, `"-4270"`, `"0"`. */
export type Money = string & { readonly [moneyBrand]: true }

/*
 * DECISIONS.md **R24** — the three forms of money are one identifier apart and all three
 * are `string`, so nothing but the type system can stop the wrong one being used.
 *
 * Feeding `display` to an input is a **1000× silent data loss**, because our own parser
 * (faithfully) reads grouped text as a decimal:
 *     parseUserInput("9,000 RON")  -> 9.000     nine thousand becomes nine
 *     parseUserInput("27,000 RON") -> 27.000
 *     parseUserInput("1182.5")     -> 1182.5    correct — this is `editing`
 * There is no exception and no validation error, and under this machine's Romanian
 * regional formats `"9.000"` *reads as* nine thousand to anyone reviewing the screen. It
 * surfaces only once persisted.
 *
 * A doc comment cannot hold that line across two implementers sharing `src/ui`. So the
 * forms are branded distinctly and `AmountField.value` takes `EditingString` — passing a
 * `DisplayString` is a **compile error**, not a review catch. `money.typetest.ts` asserts
 * the rejection actually happens.
 */

/** A rendered, human-facing amount — `"1,182 RON"`. Display only; never parse it. */
export type DisplayString = string & { readonly [displayBrand]: true }

/**
 * The seed value for a numeric input — `"1182.5"`, or `"1182,5"` under a comma locale,
 * and `""` when the amount is <= 0. Never rendered as a final amount, never sent back as
 * one: submit the canonical `amount` instead.
 */
export type EditingString = string & { readonly [editingBrand]: true }

/**
 * The ONLY way to make an `EditingString` from raw text — i.e. from what a user typed.
 * Deliberately explicit and greppable: if you are reaching for this to launder a
 * `display` value into an input, stop, and use the `MoneyValue`'s `editing` field.
 */
export function editingString(text: string): EditingString {
  return text as EditingString
}

/** Escape hatch for tests and fixtures that need a display string from a literal. */
export function displayString(text: string): DisplayString {
  return text as DisplayString
}

/**
 * The rounding rule, isolated in one switchable place.
 * The Critic is confirming `halfEven` against `AmountFormatter`; if that verdict changes,
 * change `DEFAULT_ROUNDING_MODE` and nothing else.
 */
export type RoundingMode = 'halfEven' | 'halfUp' | 'down'

export const DEFAULT_ROUNDING_MODE: RoundingMode = 'halfEven'

/** Grouping separator is hardcoded to "," in AmountFormatter, independent of locale. */
const GROUPING_SEPARATOR = ','
const GROUPING_SIZE = 3

const DECIMAL_STRING_RE = /^[+-]?(\d+(\.\d*)?|\.\d+)$/

export class MoneyParseError extends Error {
  constructor(readonly input: string) {
    super(`Not a valid decimal money string: ${JSON.stringify(input)}`)
    this.name = 'MoneyParseError'
  }
}

/** Validates and brands a canonical decimal string (the wire format). Throws otherwise. */
export function money(value: string): Money {
  if (!DECIMAL_STRING_RE.test(value.trim())) throw new MoneyParseError(value)
  return value.trim() as Money
}

/** Non-throwing variant — returns null instead of throwing. */
export function tryMoney(value: string): Money | null {
  return DECIMAL_STRING_RE.test(value.trim()) ? (value.trim() as Money) : null
}

export const ZERO: Money = '0' as Money

export function isZero(value: Money): boolean {
  const { intDigits, fracDigits } = decompose(value)
  return !/[1-9]/.test(intDigits + fracDigits)
}

export function isNegative(value: Money): boolean {
  return decompose(value).negative && !isZero(value)
}

/* ------------------------------------------------------------------ *
 * Internals — string-only decimal decomposition
 * ------------------------------------------------------------------ */

interface Decomposed {
  negative: boolean
  intDigits: string
  fracDigits: string
}

function decompose(value: string): Decomposed {
  let s = value.trim()
  let negative = false
  const first = s.charAt(0)
  if (first === '-') {
    negative = true
    s = s.slice(1)
  } else if (first === '+') {
    s = s.slice(1)
  }
  const dot = s.indexOf('.')
  const intDigits = dot === -1 ? s : s.slice(0, dot)
  const fracDigits = dot === -1 ? '' : s.slice(dot + 1)
  return { negative, intDigits: stripLeadingZeros(intDigits), fracDigits }
}

function stripLeadingZeros(digits: string): string {
  const stripped = digits.replace(/^0+/, '')
  return stripped === '' ? '0' : stripped
}

/** Adds 1 to the last place of a pure digit string. "999" -> "1000". */
function incrementDigits(digits: string): string {
  const out = digits.split('')
  let i = out.length - 1
  while (i >= 0) {
    const d = out[i]!
    if (d === '9') {
      out[i] = '0'
      i -= 1
    } else {
      out[i] = String(Number(d) + 1)
      return out.join('')
    }
  }
  return '1' + out.join('')
}

/**
 * Rounds the magnitude to `fractionDigits` places under `mode`.
 * Operates purely on digit strings — no numeric conversion of the value itself.
 */
function roundMagnitude(
  intDigits: string,
  fracDigits: string,
  fractionDigits: number,
  mode: RoundingMode,
): { intDigits: string; fracDigits: string } {
  if (fracDigits.length <= fractionDigits) {
    return { intDigits, fracDigits: fracDigits.padEnd(fractionDigits, '0') }
  }

  const keep = fracDigits.slice(0, fractionDigits)
  const rest = fracDigits.slice(fractionDigits)
  const firstRest = rest.charAt(0)
  const restHasNonZeroTail = /[1-9]/.test(rest.slice(1))

  let roundUp: boolean
  switch (mode) {
    case 'down':
      roundUp = false
      break
    case 'halfUp':
      roundUp = firstRest >= '5'
      break
    case 'halfEven': {
      if (firstRest > '5') {
        roundUp = true
      } else if (firstRest < '5') {
        roundUp = false
      } else if (restHasNonZeroTail) {
        roundUp = true // strictly more than half
      } else {
        // Exact tie: round to even.
        const combined = intDigits + keep
        const lastDigit = combined.charAt(combined.length - 1)
        roundUp = Number(lastDigit) % 2 === 1
      }
      break
    }
  }

  if (!roundUp) return { intDigits, fracDigits: keep }

  const combined = incrementDigits(intDigits + keep)
  // incrementDigits may have grown the string by one leading digit.
  const grew = combined.length > intDigits.length + keep.length
  const intLen = intDigits.length + (grew ? 1 : 0)
  return {
    intDigits: stripLeadingZeros(combined.slice(0, intLen)),
    fracDigits: combined.slice(intLen),
  }
}

function group(intDigits: string, separator: string): string {
  if (separator === '') return intDigits
  let out = ''
  let count = 0
  for (let i = intDigits.length - 1; i >= 0; i -= 1) {
    out = intDigits[i]! + out
    count += 1
    if (count % GROUPING_SIZE === 0 && i > 0) out = separator + out
  }
  return out
}

/* ------------------------------------------------------------------ *
 * Public formatting API
 * ------------------------------------------------------------------ */

export interface FormatOptions {
  /** Default 0, matching `AmountFormatter.formatForDisplay`. */
  fractionDigits?: number
  /** Default `DEFAULT_ROUNDING_MODE` ('halfEven'). */
  rounding?: RoundingMode
  /** Default ",". `AmountFormatter` hardcodes this, so it is locale-independent. */
  groupingSeparator?: string
  /** Default ".". Only reachable when `fractionDigits > 0`. */
  decimalSeparator?: string
}

/**
 * ⚠️ SAFETY NET / TEST ORACLE ONLY — see the header. Production rendering uses the
 * server's pre-formatted `display` string (API-CONTRACT §0.1, DECISIONS.md R2).
 *
 * Formats a magnitude+sign to a plain number string (no currency code).
 */
export function formatNumber(value: Money, options: FormatOptions = {}): string {
  const fractionDigits = options.fractionDigits ?? 0
  const rounding = options.rounding ?? DEFAULT_ROUNDING_MODE
  const groupingSeparator = options.groupingSeparator ?? GROUPING_SEPARATOR
  const decimalSeparator = options.decimalSeparator ?? '.'

  const { negative, intDigits, fracDigits } = decompose(value)
  const rounded = roundMagnitude(intDigits, fracDigits, fractionDigits, rounding)

  let out = group(rounded.intDigits, groupingSeparator)
  if (rounded.fracDigits.length > 0) out += decimalSeparator + rounded.fracDigits

  // iOS DOES render "-0". Verified against the shipped NumberFormatter config:
  //   formatForDisplay(-0.4) -> "-0",  (-0.5) -> "-0",  (-0.6) -> "-1".
  // So the sign follows the ORIGINAL value's sign, not the rounded magnitude. Only a
  // genuinely zero value drops it — Swift's `Decimal` has no negative zero, so a parsed
  // "-0.0" is just 0.
  const hasMagnitude = /[1-9]/.test(intDigits + fracDigits)
  return negative && hasMagnitude ? '-' + out : out
}

/**
 * ⚠️ SAFETY NET / TEST ORACLE ONLY. **Do not call this from a component.**
 * Every response field that needs displaying already carries a server-rendered
 * `display` string produced by the real Swift formatter.
 *
 * Mirrors iOS `AmountFormatter.formatForDisplay` — "1,182 RON": 0 fraction digits,
 * "," grouping, half-even rounding, currency code appended.
 */
export function formatForDisplay(
  value: Money,
  currency: string,
  options: FormatOptions = {},
): DisplayString {
  return `${formatNumber(value, options)} ${currency}` as DisplayString
}

/**
 * iOS `AmountFormatter.formatForEditing` — plain string for a text field.
 * Up to 2 fraction digits, trailing zeros dropped, no grouping,
 * and "" for anything <= 0 (that guard is in the iOS source).
 *
 * Prefer the server's `editing` field wherever a response carries one. This exists for
 * the case where you hold only a bare `amount` (e.g. a value the user just typed) and
 * need to normalise it back into the input.
 *
 * `decimalSeparator` is NOT pinned in the iOS code, so it follows the device locale:
 * "." under en, "," under ro. Callers must pass the active locale's separator.
 */
export function formatForEditing(value: Money, decimalSeparator = '.'): EditingString {
  const { negative, intDigits, fracDigits } = decompose(value)
  if (negative || !/[1-9]/.test(intDigits + fracDigits)) return '' as EditingString

  const rounded = roundMagnitude(intDigits, fracDigits, 2, DEFAULT_ROUNDING_MODE)
  const trimmedFrac = rounded.fracDigits.replace(/0+$/, '')
  return (
    trimmedFrac === '' ? rounded.intDigits : rounded.intDigits + decimalSeparator + trimmedFrac
  ) as EditingString
}

/** Shifts the decimal point by `exponent` places. Pure digit-string manipulation. */
function shiftDecimalPoint(
  intDigits: string,
  fracDigits: string,
  exponent: number,
): { intDigits: string; fracDigits: string } {
  if (exponent === 0) return { intDigits, fracDigits }
  if (exponent > 0) {
    const padded = fracDigits.padEnd(exponent, '0')
    return { intDigits: intDigits + padded.slice(0, exponent), fracDigits: padded.slice(exponent) }
  }
  const shift = -exponent
  const padded = intDigits.padStart(shift + 1, '0')
  const cut = padded.length - shift
  return { intDigits: padded.slice(0, cut), fracDigits: padded.slice(cut) + fracDigits }
}

/** Matches `Decimal.description`: no leading zeros, no trailing fractional zeros. */
function canonicalize(negative: boolean, intDigits: string, fracDigits: string): Money {
  const int = stripLeadingZeros(intDigits)
  const frac = fracDigits.replace(/0+$/, '')
  const magnitude = frac === '' ? int : `${int}.${frac}`
  // Swift's Decimal has no negative zero, so "-0.0" canonicalises to "0".
  const signed = negative && /[1-9]/.test(int + frac) ? `-${magnitude}` : magnitude
  return signed as Money
}

/**
 * iOS `AmountFormatter.parse` — user text to a canonical decimal string.
 *
 * Faithful to the iOS behaviour, **including its rough edges**: every "," becomes ".",
 * then Foundation's `Decimal(string:)` consumes the longest valid numeric prefix.
 * So `"1,234"` really does parse as `1.234`, and `"1,182.50"` as `1.182`. This is an
 * upstream iOS bug we reproduce deliberately for parity — logged in PARITY-GAPS.md.
 * Invalid input -> "0". Other verified behaviours: `"12abc"` -> 12, `"1.2.3"` -> 1.2,
 * `"5."` -> 5, and **`"1e3"` -> 1000** — `Decimal(string:)` accepts scientific notation.
 *
 * DECISIONS.md **R15**: parse locally while typing. This is string manipulation, not
 * arithmetic, so R2 is intact, and `POST /api/parse-amount` stays the test oracle rather
 * than a network hop in the keystroke path.
 */
export function parseUserInput(text: string): Money {
  const cleaned = text.replace(/,/g, '.').trim()
  const match = /^([+-]?)(\d+(?:\.\d*)?|\.\d+)(?:[eE]([+-]?\d+))?/.exec(cleaned)
  if (!match) return ZERO

  const negative = match[1] === '-'
  const digits = match[2] ?? ''
  const exponentText = match[3]

  const dot = digits.indexOf('.')
  const intDigits = dot === -1 ? digits : digits.slice(0, dot)
  const fracDigits = dot === -1 ? '' : digits.slice(dot + 1)

  // The exponent is a small place-shift count, never a monetary value, so reading it as a
  // JS integer cannot lose money precision. Clamped so a pasted "1e999999" cannot make us
  // allocate a gigabyte of zeros; Decimal's own range is far narrower than this bound.
  const EXPONENT_LIMIT = 1000
  let exponent = 0
  if (exponentText !== undefined) {
    const parsed = Number(exponentText)
    exponent = Math.max(-EXPONENT_LIMIT, Math.min(EXPONENT_LIMIT, parsed))
  }

  const shifted = shiftDecimalPoint(intDigits === '' ? '0' : intDigits, fracDigits, exponent)
  return canonicalize(negative, shifted.intDigits, shifted.fracDigits)
}
