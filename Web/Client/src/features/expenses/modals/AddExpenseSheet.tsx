/**
 * `AddExpenseSheet` — PARITY-SPEC §5.3, reference `14-add-expense-sheet.jpg`.
 *
 * Sections, in order: Details · Monthly Equivalent · Category · Account · Icon · Notes ·
 * Enabled · Delete (editing only).
 *
 * Four rules this screen is the sharp end of:
 *  - **R25 row 3** — `expense.amount` is NEVER displayed. Here it seeds the edit field and
 *    nothing else, which is the one sanctioned use.
 *  - **R24** — the amount field takes an `EditingString`, seeded from the server's
 *    `editing`. `parseUserInput("9,000 RON")` returns 9.
 *  - **R28d** — `Frequency.displayName` renders **RAW**. iOS shows "Monthly"/"Annual" in
 *    Romanian too, because `Frequency.displayName` binds Domain's bundle and those keys
 *    live only in the Expenses catalog. Translating them would be a silent improvement.
 *  - **R12** — the 37 icons come from `reference.expenseIcons`. Never hardcoded, and never
 *    shared with the 12-symbol category grid.
 */

import { useState } from 'react'
import {
  api,
  type AppState,
  type Expense,
  type ExpensePayload,
  type FrequencyValue,
  type Uuid,
} from '../../../lib/api'
import { useT } from '../../../lib/i18n'
import { Symbol } from '../../../lib/icons'
import { editingString, parseUserInput, type EditingString, type Money } from '../../../lib/money'
import { IconGrid, Menu, PillButton, Sheet, TextField, Toggle } from '../../../ui'
import { AddCategorySheet } from './AddCategorySheet'
import { useExpensePreview } from './useExpensePreview'
import { orderedCategories } from './categoryOrder'
import './modals.css'

/** `ExpenseInput` (`ExpensesViewModel.swift`) — the unsaved draft. */
interface ExpenseDraft {
  readonly name: string
  readonly amount: Money
  readonly amountText: EditingString
  readonly frequency: FrequencyValue
  readonly icon: string
  readonly categoryId?: Uuid
  readonly linkedAccountId?: Uuid
  readonly isEnabled: boolean
  readonly notes: string
}

/** Sentinels — `null` on the wire means "none" for a category and "primary" for an account. */
const NONE = '__none__'
const PRIMARY = '__primary__'

export interface AddExpenseSheetProps {
  state: AppState
  /** Absent = Add, present = Edit. */
  expense?: Expense
  onClose: () => void
  /** Every mutation returns the whole `AppState` (§0.2) — hand it straight to the shell. */
  onSaved: (state: AppState) => void
}

function seed(state: AppState, expense?: Expense): ExpenseDraft {
  if (!expense) {
    return {
      name: '',
      amount: '0' as Money,
      amountText: editingString(''),
      frequency: 'monthly',
      icon: state.reference.defaultExpenseIcon,
      isEnabled: true,
      notes: '',
    }
  }
  return {
    name: expense.name,
    amount: expense.amount.amount,
    // R24: `editing`, never `display` — the latter parses to 9 for "9,000 RON".
    amountText: expense.amount.editing,
    frequency: expense.frequency,
    icon: expense.icon,
    ...(expense.categoryId ? { categoryId: expense.categoryId } : {}),
    ...(expense.linkedAccountId ? { linkedAccountId: expense.linkedAccountId } : {}),
    isEnabled: expense.isEnabled,
    notes: expense.notes ?? '',
  }
}

export function AddExpenseSheet({ state, expense, onClose, onSaved }: AddExpenseSheetProps) {
  const t = useT('expenses')
  const [draft, setDraft] = useState<ExpenseDraft>(() => seed(state, expense))
  const [addingCategory, setAddingCategory] = useState(false)
  const [confirmingDelete, setConfirmingDelete] = useState(false)
  const [busy, setBusy] = useState(false)
  const isEditing = expense !== undefined
  // Debounced; supplies the Monthly Equivalent row and its render gate.
  const preview = useExpensePreview(draft.amount, draft.frequency)

  const update = (changes: Partial<ExpenseDraft>) =>
    setDraft((current) => ({ ...current, ...changes }))

  // `ExpenseInput.isValid` — `!name.trimmed.isEmpty && amount > 0`. That is the ONLY rule:
  // no length cap, no maximum. ⚠️ Note amount 0 is REJECTED, though `Docs/MVP/03` wants it
  // allowed for a suspended expense; the code wins.
  const isValid = draft.name.trim() !== '' && isPositiveAmount(draft.amount)

  const categories = orderedCategories(state.categories)
  const nonPrimaryAccounts = state.accounts.filter((account) => !account.isPrimary)

  const payload = (): ExpensePayload => ({
    name: draft.name.trim(),
    amount: draft.amount,
    frequency: draft.frequency,
    icon: draft.icon,
    categoryId: draft.categoryId ?? null,
    linkedAccountId: draft.linkedAccountId ?? null,
    isEnabled: draft.isEnabled,
    notes: draft.notes === '' ? null : draft.notes,
  })

  const save = () => {
    setBusy(true)
    const request = expense
      ? api.updateExpense(expense.id, payload())
      : api.createExpense(payload())
    request
      .then((next) => {
        onSaved(next)
        onClose()
      })
      .finally(() => setBusy(false))
  }

  const remove = () => {
    if (!expense) return
    setBusy(true)
    api
      .deleteExpense(expense.id)
      .then((next) => {
        onSaved(next)
        onClose()
      })
      .finally(() => setBusy(false))
  }

  return (
    <>
      <Sheet
        title={isEditing ? t('Edit Expense') : t('Add Expense')}
        cancelLabel={t('Cancel')}
        confirmLabel={t('Save')}
        confirmDisabled={!isValid || busy}
        onCancel={onClose}
        onConfirm={save}
      >
        <div className="xm-form" data-testid="add-expense-sheet">
          {/* ---- Details ------------------------------------------------ */}
          <section className="xm-section">
            <h3 className="xm-section__header">{t('Details')}</h3>
            <div className="xm-card">
              <TextField
                value={draft.name}
                onChange={(name) => update({ name })}
                placeholder={t('Name')}
                ariaLabel={t('Name')}
                testId="add-expense-name"
              />
              <div className="xm-amount-row">
                <span className="xm-currency">{state.profile?.currencyCode ?? ''}</span>
                <input
                  className="xm-amount-input"
                  data-testid="add-expense-amount"
                  inputMode="decimal"
                  placeholder="0"
                  value={draft.amountText}
                  aria-label={t('Amount')}
                  onChange={(event) =>
                    update({
                      amountText: editingString(event.target.value),
                      amount: parseUserInput(event.target.value),
                    })
                  }
                />
              </div>
              {/*
                Two things here, both verified against the reference screenshots:

                1. `frequency.displayName` renders RAW — R28d. iOS shows "Monthly"/"Annual"
                   in Romanian too, while the row caption under a saved annual expense DOES
                   say "(Anual)". That inconsistency ships; reproduce it.
                2. **NO icons.** `FrequencyPicker.swift:17` builds `Label(displayName,
                   systemImage: icon)`, so the source *looks* like it has them — but
                   `.pickerStyle(.segmented)` renders the title only, and both
                   `09-expenses.jpg` and `14-add-expense-sheet.jpg` show bare text. The
                   screenshot wins over the source reading (GROUND-TRUTH's standing rule);
                   `entry.icon` is deliberately unused.
              */}
              <div className="xm-segmented-row">
                {state.reference.frequencies.map((entry) => (
                  <button
                    key={entry.value}
                    type="button"
                    className="xm-segment"
                    role="tab"
                    aria-selected={entry.value === draft.frequency}
                    data-testid={`add-expense-period-${entry.value}`}
                    onClick={() => update({ frequency: entry.value })}
                  >
                    {entry.displayName}
                  </button>
                ))}
              </div>
            </div>
          </section>

          {/*
            ---- Monthly Equivalent (§5.3 item 2) ------------------------
            `amount × Frequency.annual.monthlyMultiplier` — a **÷ 12**, NOT the × 12 that
            DECISIONS.md R18 records (following R18 literally is 144× wrong). Served by
            `POST /api/expenses/preview`, gate included: dividing locally disagrees with iOS
            on the *value* at boundaries like 1266 (105 vs 106), not merely on rounding.
            See `useExpensePreview.ts`.
          */}
          {preview?.showsMonthlyEquivalent && (
            <section className="xm-section">
              <div className="xm-card">
                <div className="xm-row">
                  <span className="xm-row__label">{t('Monthly Equivalent')}</span>
                  <span className="xm-row__value" data-testid="add-expense-monthly-equivalent">
                    {preview.monthlyEquivalent.display}
                  </span>
                </div>
              </div>
            </section>
          )}

          {/* ---- Category ----------------------------------------------- */}
          <section className="xm-section">
            <h3 className="xm-section__header">{t('Category')}</h3>
            <div className="xm-card">
              <div className="xm-row">
                <span className="xm-row__label">{t('Category')}</span>
                <Menu
                  options={[
                    { value: NONE, label: t('None') },
                    // ⚠️ Category names are RAW literals in Domain (`Category.swift:63-133`,
                    // no `.localized`), so they are English on iOS too — a third
                    // render-raw case alongside Frequency and Currency.
                    ...categories.map((category) => ({
                      value: category.id,
                      label: category.name,
                    })),
                  ]}
                  value={draft.categoryId ?? NONE}
                  onChange={(value) =>
                    setDraft((current) => {
                      const next = { ...current }
                      if (value === NONE) delete (next as { categoryId?: Uuid }).categoryId
                      else return { ...current, categoryId: value }
                      return next
                    })
                  }
                  ariaLabel={t('Category')}
                  testId="add-expense-category-menu"
                />
              </div>
              <button
                type="button"
                className="xm-action-row"
                data-testid="add-expense-new-category-row"
                onClick={() => setAddingCategory(true)}
              >
                <Symbol name="plus.circle" size="var(--icon-md)" />
                {/* Three literal dots, not an ellipsis character. */}
                {t('New Category...')}
              </button>
            </div>
          </section>

          {/* ---- Account (only when accounts exist) --------------------- */}
          {state.accounts.length > 0 && (
            <section className="xm-section">
              <h3 className="xm-section__header">{t('Account')}</h3>
              <div className="xm-card">
                <div className="xm-row">
                  <span className="xm-row__label">{t('Pay From')}</span>
                  <Menu
                    options={[
                      { value: PRIMARY, label: t('Primary') },
                      ...nonPrimaryAccounts.map((account) => ({
                        value: account.id,
                        label: account.name,
                      })),
                    ]}
                    value={draft.linkedAccountId ?? PRIMARY}
                    onChange={(value) =>
                      setDraft((current) => {
                        const next = { ...current }
                        if (value === PRIMARY) delete (next as { linkedAccountId?: Uuid }).linkedAccountId
                        else return { ...current, linkedAccountId: value }
                        return next
                      })
                    }
                    ariaLabel={t('Pay From')}
                    testId="add-expense-pay-from-menu"
                  />
                </div>
              </div>
              <p className="xm-section__footer">
                {t('Choose which account this expense is paid from.')}
              </p>
            </section>
          )}

          {/* ---- Icon: 37 symbols, server-served (R12) ------------------ */}
          <section className="xm-section">
            <h3 className="xm-section__header">{t('Icon')}</h3>
            <div className="xm-card" data-testid="add-expense-icon-grid">
              {/*
                Per-cell ids so the parity suite can assert the grid's *identity*, not just
                its size. A count assertion is close to worthless here: 37 and 12 are exactly
                the numbers that get "corrected" to a wrong constant — the 18-vs-37 miscount
                lived in two docs and the server for a day, and every count-shaped check
                agreed with it.
              */}
              <IconGrid
                symbols={state.reference.expenseIcons}
                value={draft.icon}
                onChange={(icon) => update({ icon })}
                ariaLabel={t('Icon')}
                cellTestId={(symbol) => `add-expense-icon-${symbol}`}
              />
            </div>
          </section>

          {/* ---- Notes -------------------------------------------------- */}
          <section className="xm-section">
            <h3 className="xm-section__header">{t('Notes')}</h3>
            <div className="xm-card">
              <textarea
                className="xm-textarea"
                data-testid="add-expense-notes"
                rows={3}
                value={draft.notes}
                placeholder={t('Notes')}
                aria-label={t('Notes')}
                onChange={(event) => update({ notes: event.target.value })}
              />
            </div>
          </section>

          {/* ---- Enabled ------------------------------------------------ */}
          <section className="xm-section">
            <div className="xm-card">
              <div className="xm-row">
                <span className="xm-row__label">{t('Enabled')}</span>
                <Toggle
                  checked={draft.isEnabled}
                  onChange={(isEnabled) => update({ isEnabled })}
                  ariaLabel={t('Enabled')}
                  testId="add-expense-enabled-toggle"
                />
              </div>
            </div>
            <p className="xm-section__footer">
              {t("Disabled expenses won't be included in your budget calculations.")}
            </p>
          </section>

          {/* ---- Delete (editing only) ---------------------------------- */}
          {isEditing && (
            <section className="xm-section">
              <div className="xm-card">
                <button
                  type="button"
                  className="xm-destructive"
                  data-testid="add-expense-delete"
                  onClick={() => setConfirmingDelete(true)}
                >
                  {t('Delete Expense')}
                </button>
              </div>
            </section>
          )}
        </div>
      </Sheet>

      {/* The sheet's delete DOES confirm — unlike the row context menu, which does not. */}
      {confirmingDelete && (
        <div className="xm-confirm" role="alertdialog" aria-label={t('Delete Expense')}>
          <div className="xm-confirm__box">
            <p className="xm-confirm__title">{t('Delete Expense')}</p>
            <p className="xm-confirm__message">
              {t('Are you sure you want to delete this expense? This action cannot be undone.')}
            </p>
            <PillButton fullWidth testId="add-expense-delete-confirm" onClick={remove}>
              {t('Delete')}
            </PillButton>
            <PillButton variant="glass" fullWidth onClick={() => setConfirmingDelete(false)}>
              {t('Cancel')}
            </PillButton>
          </div>
        </div>
      )}

      {/* iOS presents this FROM the expense sheet and assigns the new id on creation. */}
      {addingCategory && (
        <AddCategorySheet
          state={state}
          onClose={() => setAddingCategory(false)}
          onCreated={(next, categoryId) => {
            onSaved(next)
            update({ categoryId })
            setAddingCategory(false)
          }}
        />
      )}
    </>
  )
}

/** `amount > 0` as a string inspection — no numeric coercion (R2). */
function isPositiveAmount(amount: Money): boolean {
  return /[1-9]/.test(amount) && !amount.startsWith('-')
}
