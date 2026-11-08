import { readFileSync, readdirSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'
import { describe, expect, it } from 'vitest'
import en from '../locales/en.json'
import ro from '../locales/ro.json'

/**
 * DECISIONS.md **R35** — every `t()` / `tDomain()` key must resolve in the namespace it is
 * bound to.
 *
 * A mistyped key does not throw. It **silently falls back to English**, so the screen looks
 * perfect to an English-reading reviewer and quietly loses Romanian. One character is
 * enough: `'Done – I made the transfers'` (U+2013 EN DASH) missed the catalog's
 * `'Done - I made the transfers'` (U+002D), which both changed the English glyph *and*
 * dropped `Gata - Am făcut transferurile`.
 *
 * `PARITY-SPEC.md §7.3` explicitly warned "plain hyphen-minus, not an en dash", and it
 * still slipped — **a note in a document is not a control.** This is the control. It
 * catches the whole class at once: mistyped keys, en/em dashes, smart quotes, `…` vs
 * `...`, non-breaking spaces.
 */

const SRC = join(import.meta.dirname, '..')

type Catalog = Record<string, Record<string, string>>
const EN = en as Catalog
const RO = ro as Catalog

/**
 * ⚠️ Keys that are **correctly** absent from Romanian. Each carries its reason AND its
 * evidence, because *an allowlist without reasons decays into a list of things someone
 * once suppressed* — a future reader must be able to re-derive every entry.
 *
 * This list is **load-bearing, not a convenience**. Without it the guard would flag New
 * Month's back button and the Monthly|Annual control as defects and push someone into
 * translating them — which is precisely the R26a violation (silently improving an iOS
 * defect) that the guard exists to help prevent. A guard can encode a wrong belief just as
 * a spec note can.
 */
const CORRECTLY_UNTRANSLATED: ReadonlyArray<{ key: string; why: string }> = [
  {
    key: 'Back',
    why: 'Absent from the dashboard catalog (NewMonthSheet.swift:49) — iOS renders English in both languages.',
  },
  {
    key: 'Developer Tools',
    why: 'No Romanian in ANY iOS catalog; the button is #if DEBUG anyway (R16).',
  },
  {
    key: '%lld percent complete',
    why: 'ProgressRing.swift:46 resolves against SharedUI, which ships NO catalog at all.',
  },
  /*
   * ⚠️ `Monthly` / `Annual` were allowlisted here and the guard proved that WRONG on its
   * first run: `Annual` resolves to "Anual" in the `expenses` namespace. Both facts are
   * true and they do not conflict —
   *   • rendered via `Frequency.displayName` (segmented control) iOS shows ENGLISH, and we
   *     render it RAW, so it never reaches `t()` and the guard never sees it;
   *   • rendered via `t('Annual')` (the "(Anual)" row caption, ExpenseItemRow.swift:60) it
   *     binds the Expenses bundle and IS Romanian.
   * So no allowlist entry is needed, and adding one would have masked a genuine miss on
   * the caption. Left as a comment because "why isn't this here?" is the question a future
   * reader will actually ask.
   */
  {
    key: 'Amount',
    why: 'SharedUI calls String(localized: "Amount") with NO bundle:, so it binds .main — and the app catalog has no "Amount". The `expenses` "Sumă" is an orphan that call site can never reach (LOCALIZATION.md:277). iOS renders English.',
  },
  {
    key: 'Options',
    why: 'The `…` menu label (PARITY-SPEC §5 Toolbar, Menu("Options", systemImage:)). SwiftUI auto-localizes the literal against the module bundle, but no catalog holds "Options" (absent from LOCALIZATION.md), so iOS falls back to the key and renders English in both languages.',
  },
  {
    key: 'Step %lld of %lld',
    why: 'The live %lld variant has no Romanian; the translated %d variant is an orphan the runtime can never reach. iOS shows "Step 1 of 3" under RO.',
  },
  {
    key: 'Romanian Leu (RON)',
    why: 'Currency.displayName is a bare Swift literal — Utilities/Currency.swift:19-25 has no .localized call at all.',
  },
  { key: 'Euro (EUR)', why: 'Currency.displayName — bare literal, no .localized.' },
  { key: 'US Dollar (USD)', why: 'Currency.displayName — bare literal, no .localized.' },
]

const ALLOWED = new Set(CORRECTLY_UNTRANSLATED.map((e) => e.key))

/** Comments discuss keys ("a blanket t('X') would be wrong") — they are not call sites. */
function stripComments(source: string): string {
  return source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/[^\n]*/g, '$1')
}

function sourceFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((entry) => {
    const full = join(dir, entry)
    if (statSync(full).isDirectory()) return sourceFiles(full)
    return /\.tsx?$/.test(entry) && !/\.(test|typetest)\.tsx?$/.test(entry) ? [full] : []
  })
}

/** `const t = useT('expenses')` / `useTDomain()` — which namespace is each binding on? */
function bindingsFor(source: string): Map<string, string> {
  const bindings = new Map<string, string>()
  for (const m of source.matchAll(/const\s+(\w+)\s*=\s*useT\(\s*'(\w+)'\s*\)/g)) {
    bindings.set(m[1]!, m[2]!)
  }
  for (const m of source.matchAll(/const\s+(\w+)\s*=\s*useTDomain\(\s*\)/g)) {
    bindings.set(m[1]!, 'domain')
  }
  return bindings
}

interface Call {
  file: string
  fn: string
  namespace: string
  key: string
}

/**
 * Only STRING-LITERAL keys are checkable. A dynamic key (`tDomain(m.displayName)`) is
 * skipped deliberately — and it must be, because resolving `displayName` by type name
 * would get **R36** wrong in the confident direction: Settings shadows Domain's label for
 * `.primary` only, so a guard that "knows" the enum's label would assert the wrong string.
 */
function callsIn(file: string, raw: string): Call[] {
  const source = stripComments(raw)
  const bindings = bindingsFor(source)
  const calls: Call[] = []
  for (const [name, namespace] of bindings) {
    const re = new RegExp(`\\b${name}\\(\\s*'((?:[^'\\\\]|\\\\.)*)'`, 'g')
    for (const m of source.matchAll(re)) {
      calls.push({ file, fn: name, namespace, key: m[1]!.replace(/\\'/g, "'") })
    }
  }
  return calls
}

function resolves(catalog: Catalog, namespace: string, key: string): boolean {
  // Same lookup order as `translate()`: requested namespace, then the shared `app` catalog.
  return catalog[namespace]?.[key] !== undefined || catalog['app']?.[key] !== undefined
}

const CALLS = sourceFiles(SRC).flatMap((file) =>
  callsIn(relative(SRC, file), readFileSync(file, 'utf8')),
)

describe('R35: every t() key resolves in its namespace', () => {
  it('finds call sites to check', () => {
    expect(CALLS.length).toBeGreaterThan(20)
  })

  it('every key exists in the EN catalog (a miss = silent key-fallback)', () => {
    const missing = CALLS.filter(
      (c) => !ALLOWED.has(c.key) && !resolves(EN, c.namespace, c.key),
    ).map((c) => `${c.file}: ${c.fn}('${c.key}') not in "${c.namespace}" or "app"`)
    expect(missing).toEqual([])
  })

  it('every key has Romanian, or is explicitly allowlisted with a reason', () => {
    const missing = CALLS.filter(
      (c) => !ALLOWED.has(c.key) && !resolves(RO, c.namespace, c.key),
    ).map((c) => `${c.file}: ${c.fn}('${c.key}') has no RO in "${c.namespace}" or "app"`)
    expect(missing).toEqual([])
  })

  it('the allowlist is documented — every entry carries a reason', () => {
    for (const entry of CORRECTLY_UNTRANSLATED) {
      expect(entry.why.length, `allowlist entry "${entry.key}" needs a reason`).toBeGreaterThan(30)
    }
  })

  it('allowlist entries stay justified — none has gained a Romanian translation', () => {
    // If iOS ever translates one of these, the entry becomes wrong and must be removed
    // rather than quietly masking a real gap.
    const nowTranslated = CORRECTLY_UNTRANSLATED.filter((e) =>
      Object.values(RO).some((ns) => ns[e.key] !== undefined),
    ).map((e) => e.key)
    expect(nowTranslated).toEqual([])
  })
})

/**
 * Non-vacuity: two planted defects testing DIFFERENT failure modes. A guard that has never
 * been seen to fail is an assumption, not a control.
 */
describe('R35 guard is non-vacuous', () => {
  it('catches a glyph substitution (en dash for hyphen) — the defect that motivated it', () => {
    const key = 'Done – I made the transfers' // U+2013
    expect(key).not.toBe('Done - I made the transfers')
    expect(resolves(EN, 'dashboard', key)).toBe(false) // would fail the build
    expect(resolves(EN, 'dashboard', 'Done - I made the transfers')).toBe(true) // correct key
  })

  it('catches KEY SELECTION, which glyph normalisation would not', () => {
    /*
     * The most conflatable pair in the catalogs: BOTH keys are live, BOTH have Romanian,
     * and they differ only by trailing dots.
     *   'New Category'    -> nav title   (CategoryManagementView.swift:212)
     *   'New Category...' -> menu label  (AddExpenseSheet.swift:78)
     * Picking the wrong one, or typing '…' for '...', loses Romanian while English looks
     * perfect. Normalising glyphs cannot catch this — only resolving the exact key can.
     */
    expect(resolves(RO, 'expenses', 'New Category')).toBe(true)
    expect(resolves(RO, 'expenses', 'New Category...')).toBe(true)
    expect(resolves(RO, 'expenses', 'New Category…')).toBe(false) // U+2026 — would fail
  })
})
