import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'
import { describe, expect, it } from 'vitest'

/**
 * DECISIONS.md **R2** — the client performs zero numeric work.
 *
 * This is the rule that is easiest to break by accident: a "trivial" sum in a component,
 * a `toFixed(0)` to tidy a percentage, an `Intl.NumberFormat` because it looks like the
 * right tool. Every one of those silently diverges from iOS — `Intl.NumberFormat`,
 * `Math.round` and `toFixed` all round half-up, so `1182.5` would render as `1,183`
 * instead of `1,182`.
 *
 * So the rule is enforced mechanically rather than by review discipline. If you are here
 * because this test failed: the number you want almost certainly belongs in an API
 * response. Message Backend and add the field — do not add an exemption.
 */

const SRC = join(import.meta.dirname, '..')

/**
 * Narrow, justified exemptions. Each one weakens the guard for a whole FILE, so add only
 * where the file provably never touches money.
 *
 *  - `lib/money.ts` — owns the branded type, the parse quirk and the test-oracle formatter.
 *  - `lib/i18n.ts` — `Number()` there parses a FORMAT-SPECIFIER INDEX out of `%1$lld`
 *    (a 1-based argument position, never a value). i18n receives already-formatted strings
 *    as parameters and has no access to a `MoneyValue`, so there is nothing here for the
 *    rule to protect. The guard flagged this correctly on first run — the exemption is the
 *    considered answer, not a way to silence it.
 */
const EXEMPT = new Set(['lib/money.ts', 'lib/i18n.ts'])

const FORBIDDEN: Array<{ pattern: RegExp; why: string }> = [
  { pattern: /\bIntl\.NumberFormat\b/, why: 'rounds half-up; use the server’s `display`' },
  { pattern: /\.toFixed\s*\(/, why: 'rounds half-up; use the server’s `display`' },
  { pattern: /\bMath\.(round|floor|ceil|trunc)\s*\(/, why: 'use a pre-computed server value' },
  { pattern: /\btoLocaleString\s*\(/, why: 'locale-dependent; use the server’s `display`' },
  { pattern: /\bparseFloat\s*\(/, why: 'money must never become a JS number' },

  /*
   * R21 — the original list caught FORMATTERS but not ARITHMETIC, so `total.amount * 0.25`
   * and `Number(x)` sailed through. These close that: coercion to number, and the direct
   * breach — every money value arrives as `.amount`, so arithmetic on money almost always
   * reads `.amount <op>`.
   */
  { pattern: /\bNumber\s*\(/, why: 'money must never become a JS number' },
  { pattern: /\bparseInt\s*\(/, why: 'money must never become a JS number' },
  { pattern: /\.amount\s*[*/+-]/, why: 'arithmetic on money — the server owns every number' },
  {
    pattern: /\.reduce\s*\(/,
    why: 'summing client-side; if this is a non-numeric reduce, exempt the file explicitly',
  },
  /*
   * API-CONTRACT v1.1 §0.1 — `MoneyValue.editing` uses the HOST LOCALE's decimal
   * separator (`"1182,5"` on this machine). It seeds an input and nothing else. Parsing
   * it or sending it back as an amount is a precision bug that only shows up under some
   * locales, which is the worst kind. Send the canonical `amount` instead.
   */
  {
    pattern: /(?:parseUserInput|money|tryMoney|Number)\s*\([^)]*\.editing\b/,
    why: '`editing` is locale-formatted and display-only; send back `amount`',
  },
  {
    pattern: /\.editing\b\s*(?:as\s+\w+\s*)?[,)]\s*\/\/\s*amount/,
    why: '`editing` is not an amount',
  },

  /*
   * API-CONTRACT v1.1: null fields are OMITTED, so `=== null` is ALWAYS false and would,
   * for instance, treat a fresh install as onboarded. Compare with `!x` or `== null`.
   */
  {
    pattern: /\.(?:profile|emergencyFund|primaryAccount|category|emergencyTarget|targetAmount|progressChangeDisplay)\s*[!=]==\s*null/,
    why: 'omitted keys are undefined, not null — use `!x` or `== null`',
  },
]

/*
 * KNOWN RESIDUAL HOLES, stated rather than papered over. A unary `+x` coercion cannot be
 * matched reliably by regex without a parser, and `a.amount.amount + b.amount.amount`
 * escapes the `.amount <op>` pattern. Neither is silent, though: `+` on two decimal
 * STRINGS concatenates ("1182.53547.5"), which fails loudly rather than producing a
 * quietly-wrong number. Closing them properly needs an AST lint rule — worth doing if this
 * guard is ever seen to miss a real breach.
 */

/**
 * Strips comments before scanning. Documentation that *warns* about a forbidden pattern
 * must not itself trip the guard — otherwise the only way to document a footgun is to
 * avoid naming it, which defeats the point. `//` preceded by `:` is left alone so URLs
 * survive.
 */
function stripComments(source: string): string {
  return source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/[^\n]*/g, '$1')
}

function sourceFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((entry) => {
    const full = join(dir, entry)
    if (statSync(full).isDirectory()) return sourceFiles(full)
    return /\.tsx?$/.test(entry) && !/\.test\.tsx?$/.test(entry) ? [full] : []
  })
}

describe('R2: no client-side numeric work', () => {
  const files = sourceFiles(SRC)

  it('finds source files to scan', () => {
    expect(files.length).toBeGreaterThan(0)
  })

  for (const { pattern, why } of FORBIDDEN) {
    it(`no ${pattern.source} outside money.ts — ${why}`, () => {
      const offenders = files
        .filter((file) => !EXEMPT.has(relative(SRC, file)))
        .filter((file) => pattern.test(stripComments(readFileSync(file, 'utf8'))))
        .map((file) => relative(SRC, file))
      expect(offenders).toEqual([])
    })
  }
})
