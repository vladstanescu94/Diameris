/**
 * Theme — `prefers-color-scheme` plus an explicit override.
 *
 * PARITY-SPEC §0.3.1: dark mode on iOS is **pure token substitution**; no screen branches
 * on appearance (verified by exhaustive grep for `colorScheme`). So there is nothing to
 * theme beyond writing `data-theme` on the root element and letting `tokens.css` swap
 * values. Never branch on theme in a component.
 */

import {
  createContext,
  createElement,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'

/** `system` follows `prefers-color-scheme`; the other two pin an appearance. */
export type ThemePreference = 'system' | 'light' | 'dark'

export const THEME_PREFERENCES: readonly ThemePreference[] = ['system', 'light', 'dark']

export interface ThemeContextValue {
  readonly preference: ThemePreference
  readonly setPreference: (preference: ThemePreference) => void
}

const ThemeContext = createContext<ThemeContextValue | null>(null)

export function ThemeProvider({ children }: { children: ReactNode }): ReactNode {
  const [preference, setPreference] = useState<ThemePreference>('system')

  useEffect(() => {
    const root = document.documentElement
    if (preference === 'system') root.removeAttribute('data-theme')
    else root.setAttribute('data-theme', preference)
  }, [preference])

  const value = useMemo<ThemeContextValue>(
    () => ({ preference, setPreference }),
    [preference],
  )
  return createElement(ThemeContext.Provider, { value }, children)
}

export function useTheme(): ThemeContextValue {
  const value = useContext(ThemeContext)
  if (value === null) throw new Error('useTheme must be used inside a <ThemeProvider>')
  return value
}

/** Cycles system → light → dark → system. Used by the gallery toolbar. */
export function useThemeToggle(): () => void {
  const { preference, setPreference } = useTheme()
  return useCallback(() => {
    const next: ThemePreference =
      preference === 'system' ? 'light' : preference === 'light' ? 'dark' : 'system'
    setPreference(next)
  }, [preference, setPreference])
}
