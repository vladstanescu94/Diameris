/**
 * Dev-only harness for the three Expenses modals.
 *
 * Exists because `TEAM.md` rule 7 requires driving a screen in a real browser, and these
 * three are presented from `ExpensesScreen` / `MainShell`, which are Frontend's files. This
 * gives them a **one-line** hook (`?dev=modals` → `<ModalsDevHarness state={state} />`)
 * instead of me waiting on their entry points to verify my own work.
 *
 * It is not parity surface: no iOS screen looks like this, it renders only behind an
 * explicit `?dev=` route, and it must never be reachable from the app's own navigation —
 * the same standing R16 takes on Dev Tools.
 */

import { useState } from 'react'
import type { AppState, Expense } from '../../../lib/api'
import { AppColumn, PillButton, Surface } from '../../../ui'
import { AddCategorySheet } from './AddCategorySheet'
import { AddExpenseSheet } from './AddExpenseSheet'
import { CategoryManagementView } from './CategoryManagementView'
import './modals.css'

type Which = 'none' | 'add' | 'edit' | 'categories' | 'newCategory'

export function ModalsDevHarness({
  state,
  onStateChange,
}: {
  state: AppState
  onStateChange: (state: AppState) => void
}) {
  const [which, setWhich] = useState<Which>('none')
  // Editing needs a real expense; the first one in the store is enough to drive the sheet.
  const editing: Expense | undefined = state.expenses[0]

  return (
    <Surface variant="grouped">
      <AppColumn>
        <div className="xm-form">
          <p className="xm-section__header">Expenses modals — dev harness</p>
          <div className="xm-card">
            <PillButton fullWidth testId="dev-open-add-expense" onClick={() => setWhich('add')}>
              Add Expense
            </PillButton>
            <PillButton
              fullWidth
              variant="glass"
              disabled={!editing}
              testId="dev-open-edit-expense"
              onClick={() => setWhich('edit')}
            >
              Edit Expense
            </PillButton>
            <PillButton
              fullWidth
              variant="glass"
              testId="dev-open-categories"
              onClick={() => setWhich('categories')}
            >
              Manage Categories
            </PillButton>
            <PillButton
              fullWidth
              variant="glass"
              testId="dev-open-new-category"
              onClick={() => setWhich('newCategory')}
            >
              New Category
            </PillButton>
          </div>
        </div>
      </AppColumn>

      {which === 'add' && (
        <AddExpenseSheet
          state={state}
          onClose={() => setWhich('none')}
          onSaved={onStateChange}
        />
      )}

      {which === 'edit' && editing && (
        <AddExpenseSheet
          state={state}
          expense={editing}
          onClose={() => setWhich('none')}
          onSaved={onStateChange}
        />
      )}

      {which === 'categories' && (
        <CategoryManagementView
          state={state}
          onClose={() => setWhich('none')}
          onChanged={onStateChange}
        />
      )}

      {which === 'newCategory' && (
        <AddCategorySheet
          state={state}
          onClose={() => setWhich('none')}
          onCreated={onStateChange}
        />
      )}
    </Surface>
  )
}
