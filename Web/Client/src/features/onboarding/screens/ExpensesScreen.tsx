/**
 * Expenses — PARITY-SPEC §2.5.
 *
 * The "After expenses" card is the first place a real number appears, and it is
 * `preview.availableIncome.display` — the server's figure, formatted by the same Swift
 * formatter iOS uses. The ground-truth run (9,000 − 4,270) must read **4,730 RON**.
 */

import { Symbol } from '../../../lib/icons'
import { PillButton } from '../../../ui'
import { Helper, OnboardingHeader, OnboardingScreen } from '../components/Chrome'
import { ExpenseRow } from '../components/ExpenseRow'
import { hasIncome, isPositive, skipExpenses, updateExpense } from '../draft'
import type { StepProps } from './shared'

export function ExpensesScreen({
  draft,
  update,
  preview,
  t,
  advance,
  indicatorLabel,
}: StepProps) {
  const available = preview?.availableIncome
  const positive = available ? isPositive(available.amount) : true

  return (
    <OnboardingScreen
      step="expenses"
      indicatorLabel={indicatorLabel}
      footer={
        <>
          <PillButton fullWidth onClick={advance}>
            {t('Continue')}
          </PillButton>
          {/* R23: skip ZEROES all four amounts — it does not skip the feature. */}
          <PillButton
            variant="glass"
            fullWidth
            onClick={() => {
              update(skipExpenses)
              advance()
            }}
          >
            {t('Skip for now')}
          </PillButton>
        </>
      }
    >
      <OnboardingHeader
        icon="creditcard.fill"
        title={t('Where does your money go?')}
        subtitle={t(
          "A quick look at your main expenses. Don't worry about being exact — estimates are fine.",
        )}
      />

      <div
        className="ob-stack-sm"
        role="group"
        aria-label={t('Expense categories')}
      >
        {draft.expenses.map((expense) => (
          <ExpenseRow
            key={expense.id}
            expense={expense}
            accounts={draft.accounts}
            currencyCode={draft.currencyCode}
            onChange={(changes) =>
              update((current) => updateExpense(current, expense.id, changes))
            }
            onChangeAccount={(linkedAccountId) =>
              update((current) =>
                updateExpense(current, expense.id, { linkedAccountId }),
              )
            }
            t={t}
          />
        ))}
      </div>

      {/* Shown only when an income has been entered (§2.5 step 3). */}
      {hasIncome(draft) && available && (
        <div className={positive ? 'ob-impact' : 'ob-impact ob-impact--warning'}>
          <div className="ob-impact__head">
            <span className="ob-impact__head-icon">
              <Symbol
                name={positive ? 'arrow.right.circle.fill' : 'exclamationmark.triangle.fill'}
                size="var(--icon-md)"
              />
            </span>
            {t('After expenses')}
          </div>
          <div className="ob-impact__amount-row">
            <span className="ob-impact__amount" data-testid="onb-after-expenses-value">
              {available.display}
            </span>
            <span className="ob-impact__caption">{t('available for your goals')}</span>
          </div>
        </div>
      )}

      <Helper text={t('By default, expenses are paid from your main account')} />
    </OnboardingScreen>
  )
}
