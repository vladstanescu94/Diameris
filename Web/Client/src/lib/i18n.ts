/**
 * i18n — EN + RO, keys matching the iOS String Catalogs (TEAM.md hard rule 5).
 *
 * ## Namespaces (DECISIONS.md R4)
 *
 * There are **five** `Localizable.xcstrings` catalogs, not one, and the same English
 * sentence can appear in several with different Romanian wording. So the locale JSON is
 * namespaced by source catalog and keys can never collide:
 *
 *   | namespace    | source catalog                                    |
 *   |--------------|---------------------------------------------------|
 *   | `app`        | `Diameris/Resources/`            (main target)     |
 *   | `domain`     | `Packages/Core/Domain/…`                           |
 *   | `onboarding` | `Packages/Features/Onboarding/…`                   |
 *   | `dashboard`  | `Packages/Features/Dashboard/…`                    |
 *   | `expenses`   | `Packages/Features/Expenses/…`                     |
 *
 * (R4 names four catalogs; `LOCALIZATION.md` also inventories the main app target, so
 * `app` is the fifth. It doubles as the shared fallback — see below.)
 *
 * ## Key and fallback semantics
 *
 * iOS uses **source-string-as-key** (`"...".localized`), so a key IS the English
 * sentence, and format arguments are positional: `%@`, `%lld`, `%d`, `%%` for a literal
 * percent — e.g. `"Nice to meet you, %@!"`, `"Step %lld of %lld"`.
 *
 * Lookup order: requested namespace → `app` → the key itself. English falling back to
 * the key is not a bug, it is the iOS behaviour: catalogs with no explicit `en` entry
 * resolve to the key, and the Expenses catalog has **zero** EN entries.
 *
 * ## Romanian is entirely the client's job
 *
 * Domain enum `displayName`s and the 8 category names come back **English only** from the
 * server (API-CONTRACT §2.3, §2.7): SwiftPM copies `Localizable.xcstrings` uncompiled on
 * macOS, so `.localized` resolves to the key. Translate them here, in the `domain`
 * namespace, keyed by the English string.
 */

import { createContext, createElement, useContext, useMemo, type ReactNode } from 'react'
import en from '../locales/en.json'
import ro from '../locales/ro.json'

export const LANGUAGES = ['en', 'ro'] as const
export type Language = (typeof LANGUAGES)[number]

export const DEFAULT_LANGUAGE: Language = 'en'

export const NAMESPACES = ['app', 'domain', 'onboarding', 'dashboard', 'expenses'] as const
export type Namespace = (typeof NAMESPACES)[number]

/** The namespace consulted when a key is absent from the requested one. */
export const FALLBACK_NAMESPACE: Namespace = 'app'

type Catalog = Readonly<Record<string, string>>
type LocaleFile = Readonly<Partial<Record<Namespace, Catalog>>>

const CATALOGS: Readonly<Record<Language, LocaleFile>> = {
  en: en as LocaleFile,
  ro: ro as LocaleFile,
}

/** Positional arguments, in the order the `%@` / `%lld` specifiers appear. */
export type TParams = ReadonlyArray<string | number>

const warned = new Set<string>()

function warnMissing(language: Language, namespace: Namespace, key: string): void {
  if (!import.meta.env.DEV) return
  const id = `${language}:${namespace}:${key}`
  if (warned.has(id)) return
  warned.add(id)
  console.warn(
    `[i18n] missing "${language}" translation in namespace "${namespace}" for key: ${JSON.stringify(key)}`,
  )
}

/**
 * Substitutes iOS-style format specifiers. `%%` yields a literal `%`.
 *
 * Handles BOTH forms, which is not optional: Xcode's extractor writes **explicitly
 * positional** specifiers (`%1$lld`, `%2$@`) whenever a string takes more than one
 * argument, and plain sequential ones (`%@`, `%lld`) when it takes one. `"Step %1$lld of
 * %2$lld"` is a real catalog entry — handling only the sequential form renders the
 * specifier verbatim on screen, which is exactly how this was found.
 */
export function interpolate(template: string, params: TParams): string {
  let sequential = 0
  return template.replace(/%%|%(\d+)\$(?:@|lld|llu|ld|lu|d|u)|%(?:@|lld|llu|ld|lu|d|u)/g,
    (match, positional?: string) => {
      if (match === '%%') return '%'
      // `%1$lld` is 1-based; a bare `%@` consumes the next unused argument.
      const index = positional === undefined ? sequential++ : Number(positional) - 1
      const value = params[index]
      return value === undefined ? match : String(value)
    })
}

function lookup(language: Language, namespace: Namespace, key: string): string | undefined {
  const file = CATALOGS[language]
  return file[namespace]?.[key] ?? file[FALLBACK_NAMESPACE]?.[key]
}

export function translate(
  language: Language,
  namespace: Namespace,
  key: string,
  params?: TParams,
): string {
  let value = lookup(language, namespace, key)

  if (value === undefined) {
    if (language !== DEFAULT_LANGUAGE) {
      warnMissing(language, namespace, key)
      value = lookup(DEFAULT_LANGUAGE, namespace, key)
    }
    // The key IS the English source string — the documented iOS fallback.
    value ??= key
  }

  return params && params.length > 0 ? interpolate(value, params) : value
}

/* ------------------------------------------------------------------ *
 * React binding
 * ------------------------------------------------------------------ */

/** A namespace-bound translate function: `t("Coming soon")`. */
export type TFunction = (key: string, params?: TParams) => string

export interface I18nContextValue {
  readonly language: Language
  readonly setLanguage: (language: Language) => void
  /** Namespace-explicit form, for shared components that translate across catalogs. */
  readonly translate: (namespace: Namespace, key: string, params?: TParams) => string
}

const I18nContext = createContext<I18nContextValue | null>(null)

export interface LanguageProviderProps {
  language: Language
  setLanguage: (language: Language) => void
  children: ReactNode
}

export function LanguageProvider({
  language,
  setLanguage,
  children,
}: LanguageProviderProps): ReactNode {
  const value = useMemo<I18nContextValue>(
    () => ({
      language,
      setLanguage,
      translate: (namespace, key, params) => translate(language, namespace, key, params),
    }),
    [language, setLanguage],
  )
  return createElement(I18nContext.Provider, { value }, children)
}

export function useI18n(): I18nContextValue {
  const value = useContext(I18nContext)
  if (value === null) throw new Error('useI18n must be used inside a <LanguageProvider>')
  return value
}

/** `const t = useT('onboarding')` then `t("Let's Go")`. */
export function useT(namespace: Namespace): TFunction {
  const { translate: translateWith } = useI18n()
  return useMemo<TFunction>(
    () => (key, params) => translateWith(namespace, key, params),
    [translateWith, namespace],
  )
}

/* ------------------------------------------------------------------ *
 * DECISIONS.md R28d — translating server enum `displayName`s
 * ------------------------------------------------------------------ */

/**
 * `const tDomain = useTDomain()` then `tDomain(account.accountTypeDisplayName)`.
 *
 * ## Why this is mandatory, and not merely nice
 *
 * SwiftPM **never compiles `.xcstrings`** — that is an Xcode-only build step — so the
 * Domain bundle ships the raw catalog with no `.lproj`, and `Bundle.module` lookups fall
 * back to the key. **The server therefore physically cannot serve Romanian.** Every
 * `*DisplayName` on the wire is an English *lookup key*, not display text: `/api/state`
 * returns `"Emergency"`, `"Priority"`, `"Primary Savings"`. Romanian has to come from the
 * client dictionary, keyed by that English string.
 *
 * ## ⚠️ It applies to FOUR of the six enums, not all of them
 *
 * | Enum | iOS under RO | Web |
 * |---|---|---|
 * | `AccountType`, `AllocationMode`, `SavingsInputMode`, `RemainingMoneyDestination` | Romanian | ✅ `tDomain` |
 * | **`Frequency`** | **English** | ⛔ render raw |
 * | **`Currency`** | **English** | ⛔ render raw |
 *
 * `Frequency.displayName` is Domain code binding `bundle: .module`, and `Monthly`/`Annual`
 * are **absent from the Domain catalog** — the `Monthly -> "Lunar"` entry lives in the
 * `expenses` catalog, which `displayName` never reads. So iOS shows English on the
 * segmented control. `Currency.displayName` has no `.localized` at all — bare literals.
 *
 * Translating those two would render Romanian where iOS renders English: a silent
 * improvement of an iOS defect, which R26a forbids. Render them raw.
 */
export function useTDomain(): TFunction {
  return useT('domain')
}
