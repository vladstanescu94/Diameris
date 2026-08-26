/**
 * Expenses tab — PARITY-SPEC §5.
 *
 * Order: summary header → frequency toggle → category list (or empty state).
 * Category rows expand **inline as an accordion**; they never push a screen.
 *
 * Three shipped quirks reproduced deliberately — each is easy to "fix" into a divergence:
 *
 *  1. **Search narrows the rows but NOT the header total** (§5.1). `displayTotal` reads the
 *     unfiltered expenses while the groups read the filtered ones, so typing shrinks the
 *     list while the big number above keeps showing the unfiltered total. Recomputing the
 *     total from visible rows would be both the wrong number and client-side maths.
 *  2. **`"Total Monthly Expenses"` is an interpolated localization key** that can never
 *     match a catalog entry, so it renders in English under RO too. Reproduced.
 *  3. **`expense.amount` is NEVER displayed.** Rows and totals use `monthlyAmount` /
 *     `annualAmount` per the selected segment; `amount` exists only to seed the edit
 *     field. All four seed expenses are monthly, so `amount == monthlyAmount` and getting
 *     this wrong passes every fixture we own while being 12× wrong for annual expenses.
 */

import { useMemo } from 'react'
import { useT } from '../../lib/i18n'
import { Symbol } from '../../lib/icons'
import type { AppState, Expense, ExpenseCategoryGroup, FrequencyValue } from '../../lib/api'
import { Divider, GlassCard, SegmentedControl, Toggle } from '../../ui'
import { slugify } from '../../lib/testid'
import './expenses.css'

export interface ExpensesScreenProps {
  state: AppState
  searchText: string
  frequency: FrequencyValue
  onFrequencyChange: (frequency: FrequencyValue) => void
  /** Owned by `MainShell` — the `…` toolbar menu drives Expand All / Collapse All. */
  expanded: ReadonlySet<string>
  onToggleCategory: (id: string) => void
  onToggleExpense: (expense: Expense, enabled: boolean) => void
  onEditExpense: (expense: Expense) => void
  onAddExpense: () => void
}

export function ExpensesScreen({
  state,
  searchText,
  frequency,
  onFrequencyChange,
  expanded,
  onToggleCategory,
  onToggleExpense,
  onEditExpense,
  onAddExpense,
}: ExpensesScreenProps) {
  const t = useT('expenses')

  const screen = state.expensesScreen
  const frequencies = state.reference.frequencies

  /*
   * §5.2 search: `localizedStandardContains` — case- AND diacritic-insensitive — over the
   * expense name, its resolved category name, and its notes. `localeCompare` with
   * sensitivity 'base' is the closest web equivalent; a plain `toLowerCase()` would miss
   * "Mancare" vs "Mâncare", which matters in Romanian.
   */
  const groups = useMemo(
    () => filterGroups(screen.categories, searchText),
    [screen.categories, searchText],
  )

  // §5.1 — reads the UNFILTERED totals on purpose. See quirk 1 above.
  const total = frequency === 'monthly' ? screen.totalMonthly : screen.totalAnnual
  /*
    ⚠️ Also raw, and the wrapper stays ENGLISH (R28d). iOS is
    `Text("Total \(displayName) Expenses".localized)`: the interpolation happens BEFORE
    `.localized`, so the runtime key is "Total Monthly Expenses" while Xcode's extractor
    wrote "Total %@ Expenses" into the catalog. Runtime key != catalog key, so the RO
    translation is dead and iOS renders the whole string in English.
    A blanket t('Total Monthly Expenses') would give fully-Romanian output — wrong in the
    direction R26a forbids.
  */
  const frequencyLabel =
    frequencies.find((f) => f.value === frequency)?.displayName ?? frequency

  return (
    <div className="exp" data-testid="screen-expenses">
      <GlassCard>
        <div className="exp-summary">
          {/*
            Quirk 2: iOS calls `"Total \(displayName) Expenses".localized`, i.e. it looks up
            an already-interpolated key, which never matches a catalog entry. So it renders
            as literal English in both languages. Reproduced by interpolating the same way.
          */}
          <span className="exp-summary__label">{`Total ${frequencyLabel} Expenses`}</span>
          <span className="exp-summary__total" data-testid="expenses-total">
            {total.display}
          </span>
        </div>
      </GlassCard>

      <SegmentedControl<FrequencyValue>
        ariaLabel={t('Frequency')}
        value={frequency}
        onChange={onFrequencyChange}
        segments={frequencies.map((f) => ({
          value: f.value,
          /*
            ⚠️ RAW on purpose (R28d). `Frequency.displayName` is Domain code binding
            `bundle: .module`, and "Monthly"/"Annual" are ABSENT from the Domain catalog —
            the `Monthly -> "Lunar"` entry lives in the `expenses` catalog, which
            `displayName` never reads. So iOS shows ENGLISH on this control even under RO.
            Wrapping it in tDomain() would render Romanian where iOS renders English: a
            silent improvement of an iOS defect, which R26a forbids.

            ⚠️ And note the deliberate inconsistency this creates: the "(Anual)" row
            caption below IS Romanian, because it binds the Expenses bundle
            (`ExpenseItemRow.swift:60`). iOS ships a screen reading "Annual" on the segment
            and "(Anual)" on a row. Reproduce it; do not harmonise it.
          */
          /*
           * ⚠️ NO ICON — and the Swift misleads here. `FrequencyPicker.swift:17` really is
           * `Label(displayName, systemImage: icon)`, so reading the source you would add
           * the glyph. But `.pickerStyle(.segmented)` renders the TITLE ONLY and drops the
           * image, and both `09-expenses.jpg` and `14-add-expense-sheet.jpg` show a bare
           * "Monthly | Annual". Screenshot beats source reading (GROUND-TRUTH's standing
           * rule), and `GROUND-TRUTH.md` itself lists the icons for this control — so the
           * doc reads as though they render. Do not re-add them.
           */
          label: f.displayName,
          testId: f.value === 'monthly' ? 'expenses-period-monthly' : 'expenses-period-annual',
        }))}
      />

      {groups.length === 0 ? (
        <EmptyState onAddExpense={onAddExpense} />
      ) : (
        groups.map((group) => {
          // v1.5: the server supplies a stable per-group id. Keying on
          // `category?.id ?? SENTINEL` collapsed every dangling-category group into one.
          const key = group.id
          return (
          <CategoryCard
            key={key}
            group={group}
            frequency={frequency}
            expanded={expanded.has(key)}
            onToggleExpanded={() => onToggleCategory(key)}
            onToggleExpense={onToggleExpense}
            onEditExpense={onEditExpense}
          />
          )
        })
      )}
    </div>
  )
}

/* ------------------------------------------------------------------ *
 * Search
 * ------------------------------------------------------------------ */

function matches(haystack: string | undefined, needle: string): boolean {
  if (!haystack) return false
  // Diacritic- and case-insensitive, mirroring `localizedStandardContains`.
  return haystack.toLocaleLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '')
    .includes(needle)
}

function filterGroups(
  groups: readonly ExpenseCategoryGroup[],
  searchText: string,
): readonly ExpenseCategoryGroup[] {
  const needle = searchText.trim().toLocaleLowerCase().normalize('NFD').replace(/\p{Diacritic}/gu, '')
  if (needle === '') return groups

  return groups
    .map((group) => ({
      ...group,
      expenses: group.expenses.filter(
        (expense) =>
          matches(expense.name, needle) ||
          matches(group.name, needle) ||
          matches(expense.notes, needle),
      ),
    }))
    .filter((group) => group.expenses.length > 0)
}

/* ------------------------------------------------------------------ *
 * §5.2 ExpenseCategoryCard
 * ------------------------------------------------------------------ */

function CategoryCard({
  group,
  frequency,
  expanded,
  onToggleExpanded,
  onToggleExpense,
  onEditExpense,
}: {
  group: ExpenseCategoryGroup
  frequency: FrequencyValue
  expanded: boolean
  onToggleExpanded: () => void
  onToggleExpense: (expense: Expense, enabled: boolean) => void
  onEditExpense: (expense: Expense) => void
}) {
  const t = useT('expenses')
  const category = group.category
  /*
   * §5.2: a group can legitimately have NO category — an unknown `categoryId`, or the
   * uncategorized bucket. Both render the grey `questionmark.circle.fill` and the title
   * "Uncategorized". `Color(hex:)` also falls back to `.gray` on an unparseable hex, which
   * is why the colour fallback is separate from the icon one.
   */
  const icon = category?.icon ?? 'questionmark.circle.fill'
  const color = category?.colorHex ?? 'var(--color-gray)'
  // v1.5: server-resolved, so "Uncategorized" has one source of wording, not two.
  const name = group.name
  const slug = slugify(name)
  const total = frequency === 'monthly' ? group.monthlyTotal : group.annualTotal

  return (
    <GlassCard padded={false}>
      <button
        type="button"
        className="exp-cat__header"
        aria-expanded={expanded}
        data-testid={`expenses-category-${slug}`}
        onClick={onToggleExpanded}
      >
        <span className="exp-cat__icon" style={{ color }}>
          <Symbol name={icon} />
        </span>
        <span className="exp-cat__text">
          <span className="exp-cat__name">{name}</span>
          {/* Server-assembled ("1/1 enabled") — global, NOT narrowed by search. */}
          <span className="exp-cat__count" data-testid={`expenses-category-count-${slug}`}>
            {group.enabledCaption}
          </span>
        </span>
        <span className="exp-cat__total" data-testid={`expenses-category-total-${slug}`}>
          {total.display}
        </span>
        <span className={expanded ? 'exp-cat__chevron exp-cat__chevron--open' : 'exp-cat__chevron'}>
          <Symbol name="chevron.right" />
        </span>
      </button>

      {expanded && (
        <>
          <div className="exp-cat__divider">
            <Divider />
          </div>
          <div className="exp-cat__rows">
            {group.expenses.map((expense, index) => (
              <div key={expense.id}>
                <ExpenseRow
                  expense={expense}
                  frequency={frequency}
                  annualLabel={t('Annual')}
                  onToggle={(enabled) => onToggleExpense(expense, enabled)}
                  onEdit={() => onEditExpense(expense)}
                />
                {/* Inset divider, omitted after the last row (§5.2). */}
                {index < group.expenses.length - 1 && (
                  <div className="exp-row__divider">
                    <Divider />
                  </div>
                )}
              </div>
            ))}
          </div>
        </>
      )}
    </GlassCard>
  )
}

function ExpenseRow({
  expense,
  frequency,
  annualLabel,
  onToggle,
  onEdit,
}: {
  expense: Expense
  frequency: FrequencyValue
  annualLabel: string
  onToggle: (enabled: boolean) => void
  onEdit: () => void
}) {
  /*
   * Quirk 3: NEVER `expense.amount`. The row shows the monthly- or annual-equivalent for
   * the selected segment.
   */
  const amount = frequency === 'monthly' ? expense.monthlyAmount : expense.annualAmount
  // §5.2: an annual expense viewed monthly gets an "(Annual)" caption underneath.
  const showAnnualCaption = expense.frequency === 'annual' && frequency === 'monthly'

  return (
    <div
      className={expense.isEnabled ? 'exp-row' : 'exp-row exp-row--disabled'}
      data-testid={`expense-row-${slugify(expense.name)}`}
    >
      <button type="button" className="exp-row__main" onClick={onEdit}>
        <span className="exp-row__icon">
          <Symbol name={expense.icon} />
        </span>
        <span className="exp-row__name">{expense.name}</span>
        <span className="exp-row__amounts">
          {/* R25a: monthlyAmount/annualAmount per segment — NEVER `amount`. */}
          <span className="exp-row__amount" data-testid={`expense-row-amount-${slugify(expense.name)}`}>
            {amount.display}
          </span>
          {showAnnualCaption && <span className="exp-row__caption">({annualLabel})</span>}
        </span>
      </button>
      <Toggle
        checked={expense.isEnabled}
        onChange={onToggle}
        ariaLabel={expense.name}
        testId={`expense-toggle-${slugify(expense.name)}`}
      />
    </div>
  )
}

/* ------------------------------------------------------------------ *
 * §5.2 empty state
 * ------------------------------------------------------------------ */

function EmptyState({ onAddExpense }: { onAddExpense: () => void }) {
  const t = useT('expenses')
  return (
    <div className="exp-empty">
      <Symbol name="list.bullet.rectangle" size="var(--icon-xxl)" />
      <h2 className="exp-empty__title">{t('No Expenses Yet')}</h2>
      <p className="exp-empty__body">{t('Add your first expense to start tracking your budget.')}</p>
      <button
        type="button"
        className="pill-button pill-button--prominent"
        data-testid="expenses-add-button"
        onClick={onAddExpense}
      >
        <Symbol name="plus" />
        {t('Add Expense')}
      </button>
    </div>
  )
}
