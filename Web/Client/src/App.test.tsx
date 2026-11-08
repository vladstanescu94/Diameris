import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import App from './App'
import { Symbol } from './lib/icons'
import { translate } from './lib/i18n'

describe('App shell', () => {
  it('renders the loading fallback before /api/state resolves', () => {
    // On the server render there is no fetch, so the app sits in its `loading` route.
    // PARITY-SPEC §0.3: iOS has NO loading state (SwiftData is synchronous). This route
    // is therefore a deliberate, enumerated deviation — deliberately plain, so we are not
    // inventing UI that has no iOS counterpart to be graded against.
    const html = renderToStaticMarkup(<App />)
    expect(html).toContain('Loading…')
  })
})

describe('Symbol', () => {
  it('renders an svg for a mapped SF Symbol', () => {
    expect(renderToStaticMarkup(<Symbol name="cart.fill" />)).toContain('<svg')
  })

  it('falls back to a help glyph for an unmapped name', () => {
    expect(renderToStaticMarkup(<Symbol name="not.a.real.symbol" />)).toContain('<svg')
  })

  it('is aria-hidden unless given a title', () => {
    expect(renderToStaticMarkup(<Symbol name="shield.fill" />)).toContain('aria-hidden="true"')
    expect(renderToStaticMarkup(<Symbol name="shield.fill" title="Emergency Fund" />)).toContain(
      'aria-label="Emergency Fund"',
    )
  })
})

describe('i18n', () => {
  it('falls back to the key when a catalog has no entry (iOS behaviour)', () => {
    // Deliberately a string that exists in NO catalog, so populating the bundles cannot
    // invalidate this. (It previously used "Let's Go", which was only key-fallback because
    // the `onboarding` namespace was an empty stub; it now correctly returns
    // "Hai să începem" from Localizable.xcstrings.)
    expect(translate('ro', 'onboarding', '__absent_from_every_catalog__')).toBe(
      '__absent_from_every_catalog__',
    )
  })

  it('resolves a real generated onboarding string', () => {
    expect(translate('en', 'onboarding', "Let's Go")).toBe("Let's Go")
    expect(translate('ro', 'onboarding', "Let's Go")).toBe('Hai să începem')
  })

  it('never lets the app-namespace fallback serve a dropped orphan (LOCALIZATION.md §3.2)', () => {
    // `Other` renders via AccountType.other.displayName, i.e. Domain's bundle -> "Altul".
    // The app catalog also holds "Altele", which iOS can never display; gen-locales.py drops
    // it so the `requested-ns -> app -> key` chain cannot substitute the losing translation.
    expect(translate('ro', 'domain', 'Other')).toBe('Altul')
    expect(translate('ro', 'expenses', 'Other')).toBe('Other') // key fallback, NOT "Altele"
    expect(translate('ro', 'dashboard', 'Other')).not.toBe('Altele')
  })

  it('translates Cancel explicitly — iOS gets it from the system, the web does not', () => {
    expect(translate('en', 'app', 'Cancel')).toBe('Cancel')
    expect(translate('ro', 'app', 'Cancel')).toBe('Anulează')
  })

  it('translates known keys in their namespace', () => {
    expect(translate('ro', 'app', 'Expenses')).toBe('Cheltuieli')
  })

  it('falls back from a feature namespace to the app catalog (R4)', () => {
    // "Expenses" lives in the app catalog; the expenses feature namespace is empty.
    expect(translate('ro', 'expenses', 'Expenses')).toBe('Cheltuieli')
  })

  it('substitutes EXPLICITLY POSITIONAL specifiers (%1$lld), not just sequential ones', () => {
    // Xcode's extractor emits `%1$lld` style whenever a string takes >1 argument.
    // "Step %1$lld of %2$lld" is a real catalog entry; handling only `%lld` rendered the
    // specifier verbatim on the New Month header. Found by driving the flow.
    expect(translate('en', 'dashboard', 'Step %1$lld of %2$lld', [2, 3])).toBe('Step 2 of 3')
    expect(translate('en', 'app', '%2$@ then %1$@', ['b', 'a'])).toBe('a then b')
    // A repeated index consumes the same argument twice.
    expect(translate('en', 'app', '%1$@ / %1$@', ['x'])).toBe('x / x')
    // Mixed literal percent still works.
    expect(translate('en', 'app', '%1$lld%% of %2$@', [25, 'income'])).toBe('25% of income')
  })

  it('substitutes iOS positional specifiers in order', () => {
    expect(translate('en', 'app', 'Step %lld of %lld', [2, 3])).toBe('Step 2 of 3')
    expect(translate('en', 'onboarding', 'Nice to meet you, %@!', ['Vlad'])).toBe(
      'Nice to meet you, Vlad!',
    )
    expect(translate('en', 'app', '%lld%%', [25])).toBe('25%')
    expect(
      translate('en', 'app', 'Target: %lld× monthly income (capped at %@)', [3, '27,000 RON']),
    ).toBe('Target: 3× monthly income (capped at 27,000 RON)')
  })
})
