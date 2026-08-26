/**
 * Main shell — PARITY-SPEC §3 (`MainTabView.swift`).
 *
 * Three tabs plus a bottom accessory. Per screen there is a large navigation title and, on
 * the Dashboard, a trailing toolbar pair (Settings + Developer Tools).
 *
 * **Data-flow contract (API-CONTRACT §0.2):** every mutation returns the ENTIRE `AppState`
 * and we replace the store wholesale. That is the web equivalent of iOS's `DataObserver`,
 * which re-derives every view model on any `ModelContext.didSave`. Never patch a slice —
 * a partial update would leave derived values (totals, transfer plan, captions) stale.
 */

import { useCallback, useState } from 'react'
import { useT } from '../../lib/i18n'
import { Symbol } from '../../lib/icons'
import { api, type AppState, type Expense, type FrequencyValue } from '../../lib/api'
import { AppColumn, Surface, TabAccessory, TabBar } from '../../ui'
import { DashboardScreen } from '../dashboard/DashboardScreen'
import { ExpensesScreen } from '../expenses/ExpensesScreen'
import { InsightsScreen } from '../insights/InsightsScreen'
import { NewMonthSheet } from '../newmonth/NewMonthSheet'
import { SettingsSheet } from '../settings/SettingsSheet'
import { DevTools } from '../devtools/DevTools'
import { AddExpenseSheet, CategoryManagementView } from '../expenses/modals'
import {
  dismissTopModal,
  goToTab,
  presentModal,
  replaceTopModal,
  topModal,
  type NewMonthStep,
  type Tab,
  type ViewState,
} from '../../state/viewState'
import './main.css'

export interface MainShellProps {
  state: AppState
  view: ViewState
  setView: (update: (current: ViewState) => ViewState) => void
  onStateChange: (state: AppState) => void
}

export function MainShell({ state, view, setView, onStateChange }: MainShellProps) {
  const t = useT('app')
  // `Search expenses` lives in the EXPENSES catalog (RO: "Caută cheltuieli"), not the app
  // one. Using the wrong namespace silently key-falls-back to English — invisible in EN,
  // caught only by driving the app under `?lang=ro`.
  const tExpenses = useT('expenses')
  const [searchText, setSearchText] = useState('')
  const [frequency, setFrequency] = useState<FrequencyValue>('monthly')
  const [optionsOpen, setOptionsOpen] = useState(false)
  /*
   * The accordion's expanded set lives HERE, not in `ExpensesScreen`, because the `…`
   * toolbar menu drives Expand All / Collapse All. Keeping it in the screen made those two
   * shipped actions unreachable from the toolbar that owns them.
   */
  const [expanded, setExpanded] = useState<ReadonlySet<string>>(new Set())
  const expandAll = () =>
    setExpanded(new Set(state.expensesScreen.categories.map((g) => g.id)))
  const collapseAll = () => setExpanded(new Set())
  const toggleCategory = (id: string) =>
    setExpanded((current) => {
      const next = new Set(current)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })

  const tab: Tab = view.route.kind === 'main' ? view.route.tab : 'dashboard'
  const modal = topModal(view)

  const toggleExpense = useCallback(
    (expense: Expense, enabled: boolean) => {
      // Partial PUT: `{isEnabled}` alone flips the toggle (API-CONTRACT §3).
      // The response is the whole state, so totals and captions re-derive server-side.
      void api
        .updateExpense(expense.id, { isEnabled: enabled })
        .then(onStateChange)
        .catch(() => {
          /* iOS swallows save failures silently (PARITY-SPEC §0.3) — so do we. */
        })
    },
    [onStateChange],
  )

  const openExpenseSheet = useCallback(
    (expense?: Expense) => {
      setView((current) =>
        presentModal(
          current,
          expense ? { kind: 'expenseSheet', expenseId: expense.id } : { kind: 'expenseSheet' },
        ),
      )
    },
    [setView],
  )

  return (
    <Surface>
      <div className="shell">
        <AppColumn>
          <header className="shell__bar">
            <h1 className="shell__title" data-testid="dashboard-title">
              {titleFor(tab, state, t)}
            </h1>
            {tab === 'dashboard' && (
              <div className="shell__toolbar">
                <button
                  type="button"
                  className="shell__toolbar-button"
                  aria-label={t('Settings')}
                  data-testid="toolbar-settings"
                  onClick={() => setView((current) => presentModal(current, { kind: 'settings' }))}
                >
                  <Symbol name="gearshape" />
                </button>
                {/*
                  DECISIONS.md R28c / R16: BOTH the Dev Tools view and its entry point are
                  `#if DEBUG` on iOS, so a shipping user cannot reach it — it is not
                  shipped parity surface. Rendering it unconditionally was not a deviation
                  to enumerate, it was one to remove. Gated on the dev build, matching the
                  `?dev=` pattern used for the gallery.
                */}
                {import.meta.env.DEV && (
                  <button
                    type="button"
                    className="shell__toolbar-button"
                    /* Not in ANY iOS catalog, so iOS renders the key — i.e. English — even
                       under RO. The English fallback here is CORRECT parity: adding a
                       Romanian translation would make the web diverge from the app. */
                    aria-label={t('Developer Tools')}
                    data-testid="toolbar-devtools"
                    onClick={() => setView((current) => presentModal(current, { kind: 'devTools' }))}
                  >
                    <Symbol name="hammer.fill" />
                  </button>
                )}
              </div>
            )}
          </header>

          {tab === 'expenses' && (
            <div className="shell__toolbar shell__toolbar--expenses">
              <button
                type="button"
                className="shell__toolbar-button"
                aria-label={tExpenses('Add Expense')}
                data-testid="expenses-add-button"
                onClick={() => openExpenseSheet()}
              >
                <Symbol name="plus" />
              </button>
              {/*
                PARITY-SPEC §5 Toolbar: `Menu("Options", systemImage: "ellipsis.circle")`
                with THREE items — Expand All, Collapse All, a divider, then Manage
                Categories. It was a single button straight to Manage Categories, which
                left two shipped actions unreachable. The label is "Options", not the
                destination.
              */}
              <div className="shell__menu">
                <button
                  type="button"
                  className="shell__toolbar-button"
                  aria-label={tExpenses('Options')}
                  aria-haspopup="menu"
                  aria-expanded={optionsOpen}
                  data-testid="expenses-overflow-menu"
                  onClick={() => setOptionsOpen((open) => !open)}
                >
                  <Symbol name="ellipsis.circle" />
                </button>
                {optionsOpen && (
                  <div className="shell__menu-items" role="menu">
                    <button
                      type="button"
                      role="menuitem"
                      className="shell__menu-item"
                      data-testid="expenses-expand-all"
                      onClick={() => {
                        expandAll()
                        setOptionsOpen(false)
                      }}
                    >
                      <Symbol name="rectangle.expand.vertical" />
                      {tExpenses('Expand All')}
                    </button>
                    <button
                      type="button"
                      role="menuitem"
                      className="shell__menu-item"
                      data-testid="expenses-collapse-all"
                      onClick={() => {
                        collapseAll()
                        setOptionsOpen(false)
                      }}
                    >
                      <Symbol name="rectangle.compress.vertical" />
                      {tExpenses('Collapse All')}
                    </button>
                    <hr className="list-divider" />
                    <button
                      type="button"
                      role="menuitem"
                      className="shell__menu-item"
                      data-testid="expenses-manage-categories"
                      onClick={() => {
                        setOptionsOpen(false)
                        setView((current) =>
                          presentModal(current, { kind: 'categoryManagement' }),
                        )
                      }}
                    >
                      <Symbol name="folder.badge.gearshape" />
                      {tExpenses('Manage Categories')}
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}

          {tab === 'expenses' && (
            <div className="shell__search">
              <Symbol name="magnifyingglass" />
              <input
                type="search"
                className="shell__search-input"
                placeholder={tExpenses('Search expenses')}
                value={searchText}
                onChange={(event) => setSearchText(event.target.value)}
              />
            </div>
          )}

          <main className="shell__content">
            {tab === 'dashboard' && <DashboardScreen state={state} />}
            {tab === 'expenses' && (
              <ExpensesScreen
                state={state}
                searchText={searchText}
                frequency={frequency}
                onFrequencyChange={setFrequency}
                expanded={expanded}
                onToggleCategory={toggleCategory}
                onToggleExpense={toggleExpense}
                onEditExpense={openExpenseSheet}
                onAddExpense={() => openExpenseSheet()}
              />
            )}
            {tab === 'insights' && <InsightsScreen />}
          </main>
        </AppColumn>

        <div className="shell__dock">
          <AppColumn>
            <TabBar<Tab>
              ariaLabel={t('Dashboard')}
              value={tab}
              onChange={(next) => setView((current) => goToTab(current, next))}
              accessory={
                <TabAccessory
                  label={t('New Month')}
                  onClick={() =>
                    setView((current) => presentModal(current, { kind: 'newMonth', step: 1 }))
                  }
                  // §3: `.disabled(!hasCompletedOnboarding)`.
                  disabled={!state.onboardingCompleted}
                  testId="new-month-button"
                />
              }
              tabs={[
                { value: 'dashboard', label: t('Dashboard'), icon: 'chart.pie.fill', testId: 'tab-dashboard' },
                { value: 'expenses', label: t('Expenses'), icon: 'list.bullet.rectangle', testId: 'tab-expenses' },
                { value: 'insights', label: t('Insights'), icon: 'lightbulb.max', testId: 'tab-insights' },
              ]}
            />
          </AppColumn>
        </div>
      </div>

      {/*
        New Month steps IN PLACE via `replaceTopModal` rather than stacking three modals —
        it is one sheet whose header reads "Step n of 3", not three presentations.
      */}
      {/* R16: dev-only tooling, never shipped parity surface. */}
      {modal?.kind === 'devTools' && import.meta.env.DEV && (
        <DevTools onStateChange={onStateChange} onClose={() => setView((c) => dismissTopModal(c))} />
      )}

      {modal?.kind === 'expenseSheet' && (
        <AddExpenseSheet
          state={state}
          {...(() => {
            const found = modal.expenseId
              ? state.expenses.find((e) => e.id === modal.expenseId)
              : undefined
            return found ? { expense: found } : {}
          })()}
          onClose={() => setView((c) => dismissTopModal(c))}
          onSaved={onStateChange}
        />
      )}

      {modal?.kind === 'categoryManagement' && (
        <CategoryManagementView
          state={state}
          onClose={() => setView((c) => dismissTopModal(c))}
          onChanged={onStateChange}
        />
      )}

      {modal?.kind === 'settings' && (
        <SettingsSheet
          state={state}
          onClose={() => setView((current) => dismissTopModal(current))}
          onSaved={onStateChange}
        />
      )}

      {modal?.kind === 'newMonth' && (
        <NewMonthSheet
          state={state}
          step={modal.step}
          onStepChange={(step: NewMonthStep) =>
            setView((current) => replaceTopModal(current, { kind: 'newMonth', step }))
          }
          onClose={() => setView((current) => dismissTopModal(current))}
          onCompleted={onStateChange}
        />
      )}
    </Surface>
  )
}

/**
 * §4: the Dashboard's title is the server's `currentMonthDisplay` ("August 2026"),
 * formatted server-side so it cannot drift from iOS's `DateFormatters.monthYear`.
 * The other two are plain localized titles.
 */
function titleFor(tab: Tab, state: AppState, t: (key: string) => string): string {
  if (tab === 'dashboard') return state.dashboard.currentMonthDisplay
  return tab === 'expenses' ? t('Expenses') : t('Insights')
}
