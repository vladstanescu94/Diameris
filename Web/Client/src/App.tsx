import { useCallback, useEffect, useState } from 'react'
import { LanguageProvider, type Language } from './lib/i18n'
import { api, ApiError, type AppState } from './lib/api'
import { ThemeProvider } from './ui'
import { Gallery } from './ui/Gallery'
import { ModalsDevHarness } from './features/expenses/modals'
import { MainShell } from './features/main/MainShell'
import { OnboardingFlow } from './features/onboarding'
import {
  INITIAL_VIEW_STATE,
  goToOnboarding,
  goToTab,
  type ViewState,
} from './state/viewState'

/**
 * App shell.
 *
 * There is no router (DECISIONS.md D3) — the whole app is `ViewState`, plus two dev
 * routes read once from the query string:
 *   `?dev=gallery`   — the primitive gallery, no server needed.
 *   `?dev=onboarding` — the onboarding flow against live state WITHOUT completing it,
 *                       so it can be driven in a browser without POSTing
 *                       `/api/onboarding/complete` and clobbering the shared store
 *                       (which holds the month-2 ground truth the Verify suite asserts).
 *
 * PARITY-SPEC §0.3: iOS has **no loading state and no error state** anywhere — SwiftData
 * is synchronous and every `try? context.save()` failure is silent. We cannot match that
 * over HTTP, so the loading and error routes are a deliberate, enumerated deviation
 * rather than an accident. They are the only two routes with no iOS counterpart.
 */

type DevRoute = 'gallery' | 'onboarding' | 'modals' | null

function devRoute(): DevRoute {
  if (typeof window === 'undefined') return null
  const value = new URLSearchParams(window.location.search).get('dev')
  return value === 'gallery' || value === 'onboarding' || value === 'modals' ? value : null
}

/**
 * `?lang=ro` — dev-only initial language. There is no in-app language picker (iOS takes
 * the language from the device), so without this the Romanian catalogue could not be
 * driven or screenshotted at all, and the missing-key warnings — which only fire for
 * non-default languages — would never be seen.
 */
function initialLanguage(): Language {
  if (typeof window === 'undefined') return 'en'
  return new URLSearchParams(window.location.search).get('lang') === 'ro' ? 'ro' : 'en'
}

function useAppState() {
  const [state, setState] = useState<AppState | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    api
      .getState()
      .then((next) => {
        if (!cancelled) setState(next)
      })
      .catch((cause: unknown) => {
        if (cancelled) return
        // A 502 from the Vite proxy (API server down) has an EMPTY body, so `reason` is
        // "". Falling back to `cause.message` matters: an empty string is falsy, and the
        // error route was being skipped, leaving the app on "Loading…" forever with the
        // real failure only visible in the console. Found by running it against a stopped
        // server — the build and the tests were both perfectly happy.
        const message = cause instanceof ApiError ? cause.reason || cause.message : String(cause)
        setError(message === '' ? 'Request failed' : message)
      })
    return () => {
      cancelled = true
    }
  }, [])

  return { state, error, setState }
}

export default function App() {
  const [language, setLanguage] = useState<Language>(initialLanguage)
  const [view, setView] = useState<ViewState>(INITIAL_VIEW_STATE)
  const changeLanguage = useCallback((next: Language) => setLanguage(next), [])
  const dev = devRoute()
  const { state, error, setState } = useAppState()

  // The route follows the server's `onboardingCompleted`, so a reset or a completed
  // onboarding moves the shell without any client-side bookkeeping.
  useEffect(() => {
    if (!state) return
    setView((current) =>
      state.onboardingCompleted
        ? current.route.kind === 'main'
          ? current
          : goToTab(current, 'dashboard')
        : current.route.kind === 'onboarding'
          ? current
          : goToOnboarding(current, 'welcome'),
    )
  }, [state])

  const body = (() => {
    if (dev === 'gallery') return <Gallery />
    // `!== null`, not truthiness — an empty reason is still an error (see the catch above).
    if (error !== null) return <Fallback message={error} />
    if (!state) return <Fallback message="Loading…" />
    if (dev === 'onboarding') return <OnboardingFlow state={state} onComplete={setState} />
    // Dev-only, like the gallery: never reachable from app navigation (R16).
    if (dev === 'modals') return <ModalsDevHarness state={state} onStateChange={setState} />
    if (!state.onboardingCompleted) {
      return <OnboardingFlow state={state} onComplete={setState} />
    }
    return <MainShell state={state} view={view} setView={setView} onStateChange={setState} />
  })()

  return (
    <ThemeProvider>
      <LanguageProvider language={language} setLanguage={changeLanguage}>
        {body}
      </LanguageProvider>
    </ThemeProvider>
  )
}

/**
 * Loading / error. Deliberately plain: iOS shows neither, so anything elaborate here
 * would be inventing UI that has no counterpart to be graded against.
 */
function Fallback({ message }: { message: string }) {
  return (
    <div
      style={{
        display: 'grid',
        placeItems: 'center',
        minHeight: '100vh',
        color: 'var(--label-secondary)',
        fontSize: 'var(--font-subheadline-size)',
        background: 'var(--bg-canvas)',
      }}
    >
      {message}
    </div>
  )
}
