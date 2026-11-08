import { describe, expect, it } from 'vitest'
import {
  formatForDisplay,
  formatForEditing,
  formatNumber,
  isNegative,
  isZero,
  money,
  parseUserInput,
  tryMoney,
} from './money'

/*
 * NOTE (DECISIONS.md R2): production rendering uses the server's pre-formatted `display`
 * string. `formatNumber` / `formatForDisplay` are a SAFETY NET and TEST ORACLE only.
 * These tests pin the iOS rounding rule so a parity harness has an independent second
 * opinion, and so any future drift in the shared understanding of the rule is caught here
 * rather than on screen.
 */

describe('API-CONTRACT v1 worked examples (oracle cross-check)', () => {
  /*
   * ⚠️ The `editing` separator is DATA, not a constant. `AmountFormatter.formatForEditing`
   * builds a bare `NumberFormatter()` whose locale defaults to `Locale.current` and pins
   * only the GROUPING separator — so on this machine (`en_US@rg=rozzzz`) the server emits
   * "1182,5" where API-CONTRACT §2.4 documents "1182.5". Backend is pinning `en_US_POSIX`.
   * These tests therefore pass the separator explicitly rather than assuming ".", and no
   * test anywhere may hardcode a separator for a server-produced `editing` value.
   */
  const SEP = '.'

  it('agrees with every MoneyValue triple printed in the contract', () => {
    const cases: Array<[string, string, string]> = [
      // amount        display          editing
      ['9000', '9,000 RON', '9000'],
      ['4270', '4,270 RON', '4270'],
      ['4730', '4,730 RON', '4730'],
      ['1182.5', '1,182 RON', '1182.5'],
      ['3547.5', '3,548 RON', '3547.5'],
      ['27000', '27,000 RON', '27000'],
      ['2500', '2,500 RON', '2500'],
      ['30000', '30,000 RON', '30000'],
      ['51240', '51,240 RON', '51240'],
      ['2365', '2,365 RON', '2365'],
      ['0', '0 RON', ''], // `editing` is "" when the amount is <= 0
    ]
    for (const [amount, display, editing] of cases) {
      expect(formatForDisplay(money(amount), 'RON')).toBe(display)
      expect(formatForEditing(money(amount), SEP)).toBe(editing)
    }
  })

  it('produces the same editing value under a comma locale, differing only in separator', () => {
    expect(formatForEditing(money('1182.5'), ',')).toBe('1182,5')
    expect(formatForEditing(money('1182.5'), '.')).toBe('1182.5')
  })

  it('reproduces POST /api/parse-amount for {"text":"1,234"}', () => {
    // Contract: -> { amount: "1.234", display: "1 RON", editing: "1.23" }
    const parsed = parseUserInput('1,234')
    expect(parsed).toBe('1.234')
    expect(formatForDisplay(parsed, 'RON')).toBe('1 RON')
    expect(formatForEditing(parsed, SEP)).toBe('1.23')
  })
})

describe('GROUND-TRUTH.md verified numbers', () => {
  it('formats 1182.5 as "1,182 RON" (half-even: 2 is already even)', () => {
    expect(formatForDisplay(money('1182.5'), 'RON')).toBe('1,182 RON')
  })

  it('formats 3547.5 as "3,548 RON" (half-even: 7 is odd, so up to 8)', () => {
    expect(formatForDisplay(money('3547.5'), 'RON')).toBe('3,548 RON')
  })

  it('reproduces the rest of the ground-truth table', () => {
    expect(formatForDisplay(money('9000'), 'RON')).toBe('9,000 RON')
    expect(formatForDisplay(money('4270'), 'RON')).toBe('4,270 RON')
    expect(formatForDisplay(money('4730'), 'RON')).toBe('4,730 RON')
    expect(formatForDisplay(money('27000'), 'RON')).toBe('27,000 RON')
    expect(formatForDisplay(money('2365'), 'RON')).toBe('2,365 RON')
    expect(formatForDisplay(money('7095'), 'RON')).toBe('7,095 RON')
    expect(formatForDisplay(money('2500'), 'RON')).toBe('2,500 RON')
    expect(formatForDisplay(money('120'), 'RON')).toBe('120 RON')
  })
})

describe('rounding modes', () => {
  const cases: Array<[string, string, string, string]> = [
    // value        halfEven  halfUp  down
    ['1182.5', '1,182', '1,183', '1,182'],
    ['3547.5', '3,548', '3,548', '3,547'],
    ['0.5', '0', '1', '0'],
    ['1.5', '2', '2', '1'],
    ['2.5', '2', '3', '2'],
    ['2.50001', '3', '3', '2'],
    ['2.4999', '2', '2', '2'],
    ['-2.5', '-2', '-3', '-2'],
    ['-1.5', '-2', '-2', '-1'],
    ['9.5', '10', '10', '9'],
    ['99.5', '100', '100', '99'],
    // iOS really does render "-0" for a negative value whose magnitude rounds to zero —
    // verified against the shipped NumberFormatter, not inferred.
    ['-0.4', '-0', '-0', '-0'],
    ['-0.5', '-0', '-1', '-0'],
    ['-0.6', '-1', '-1', '-0'],
  ]

  for (const [value, halfEven, halfUp, down] of cases) {
    it(`${value}: halfEven=${halfEven} halfUp=${halfUp} down=${down}`, () => {
      expect(formatNumber(money(value), { rounding: 'halfEven' })).toBe(halfEven)
      expect(formatNumber(money(value), { rounding: 'halfUp' })).toBe(halfUp)
      expect(formatNumber(money(value), { rounding: 'down' })).toBe(down)
    })
  }

  it('defaults to half-even', () => {
    expect(formatNumber(money('2.5'))).toBe('2')
    expect(formatNumber(money('3.5'))).toBe('4')
  })
})

describe('grouping', () => {
  it('groups every three digits with ","', () => {
    expect(formatNumber(money('1'))).toBe('1')
    expect(formatNumber(money('999'))).toBe('999')
    expect(formatNumber(money('1000'))).toBe('1,000')
    expect(formatNumber(money('1234567'))).toBe('1,234,567')
    expect(formatNumber(money('-1234567.5'))).toBe('-1,234,568')
  })

  it('is not lossy for values beyond Number.MAX_SAFE_INTEGER', () => {
    expect(formatNumber(money('9007199254740993'))).toBe('9,007,199,254,740,993')
    expect(formatNumber(money('123456789012345678901234567890'))).toBe(
      '123,456,789,012,345,678,901,234,567,890',
    )
  })

  it('supports fraction digits when explicitly requested', () => {
    expect(formatNumber(money('1182.5'), { fractionDigits: 2 })).toBe('1,182.50')
    expect(formatNumber(money('1182.567'), { fractionDigits: 2 })).toBe('1,182.57')
    expect(formatNumber(money('1182.5'), { fractionDigits: 1, decimalSeparator: ',' })).toBe(
      '1,182,5',
    )
  })
})

describe('formatForEditing (iOS AmountFormatter.formatForEditing)', () => {
  it('drops grouping and trailing zeros', () => {
    expect(formatForEditing(money('1182.5'))).toBe('1182.5')
    expect(formatForEditing(money('3547.5'))).toBe('3547.5')
    expect(formatForEditing(money('9000'))).toBe('9000')
    expect(formatForEditing(money('1182.50'))).toBe('1182.5')
    expect(formatForEditing(money('1182.567'))).toBe('1182.57')
  })

  it('uses the supplied decimal separator (ro locale renders "1182,5")', () => {
    expect(formatForEditing(money('1182.5'), ',')).toBe('1182,5')
  })

  it('returns "" for zero and negatives, matching the iOS guard', () => {
    expect(formatForEditing(money('0'))).toBe('')
    expect(formatForEditing(money('0.00'))).toBe('')
    expect(formatForEditing(money('-5'))).toBe('')
  })
})

describe('parseUserInput (iOS AmountFormatter.parse)', () => {
  it('parses plain and comma-decimal input', () => {
    expect(parseUserInput('1182.5')).toBe('1182.5')
    expect(parseUserInput('1182,5')).toBe('1182.5')
    expect(parseUserInput(' 9000 ')).toBe('9000')
    expect(parseUserInput('')).toBe('0')
    expect(parseUserInput('abc')).toBe('0')
  })

  it('reproduces the iOS grouped-input quirk: "1,182.50" parses as 1.182', () => {
    expect(parseUserInput('1,182.50')).toBe('1.182')
  })

  it('accepts scientific notation, as Decimal(string:) does', () => {
    expect(parseUserInput('1e3')).toBe('1000')
    expect(parseUserInput('1E3')).toBe('1000')
    expect(parseUserInput('1.5e1')).toBe('15')
    expect(parseUserInput('1e-2')).toBe('0.01')
    expect(parseUserInput('1182.5e0')).toBe('1182.5')
    expect(parseUserInput('-2.5e2')).toBe('-250')
  })

  it('matches the other verified iOS parse behaviours', () => {
    expect(parseUserInput('12abc')).toBe('12')
    expect(parseUserInput('1.2.3')).toBe('1.2')
    expect(parseUserInput('5.')).toBe('5')
    expect(parseUserInput('.5')).toBe('0.5')
    expect(parseUserInput('+9000')).toBe('9000')
  })

  it('canonicalises like Decimal.description — no leading or trailing zeros', () => {
    expect(parseUserInput('1.50')).toBe('1.5')
    expect(parseUserInput('007')).toBe('7')
    expect(parseUserInput('0.00')).toBe('0')
    expect(parseUserInput('-0.0')).toBe('0') // Decimal has no negative zero
    expect(parseUserInput('100')).toBe('100') // integer trailing zeros are significant
  })

  it('round-trips the wire format without loss', () => {
    for (const v of ['1182.5', '3547.5', '4730', '27000', '0.01']) {
      expect(parseUserInput(v)).toBe(v)
    }
  })
})

describe('validation and predicates', () => {
  it('rejects non-decimal strings', () => {
    expect(() => money('1,182')).toThrow()
    expect(() => money('12px')).toThrow()
    expect(() => money('')).toThrow()
    expect(tryMoney('1e5')).toBeNull()
    expect(tryMoney('-4270')).toBe('-4270')
  })

  it('detects zero and negative', () => {
    expect(isZero(money('0'))).toBe(true)
    expect(isZero(money('0.000'))).toBe(true)
    expect(isZero(money('-0.00'))).toBe(true)
    expect(isZero(money('0.01'))).toBe(false)
    expect(isNegative(money('-4270'))).toBe(true)
    expect(isNegative(money('-0.0'))).toBe(false)
    expect(isNegative(money('4270'))).toBe(false)
  })
})
