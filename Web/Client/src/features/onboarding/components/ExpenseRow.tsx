/**
 * The onboarding expense row — PARITY-SPEC §2.5.1.
 *
 * `From:` defaults to **"Main"** and `linkedAccountId == undefined` MEANS the primary
 * account (the iOS convention). The menu lists `Main`, then every **non-primary** account.
 */

import type { Account, Uuid } from '../../../lib/api'
import type { TFunction } from '../../../lib/i18n'
import { Symbol } from '../../../lib/icons'
import { editingString, parseUserInput } from '../../../lib/money'
import { GlassCard, Menu } from '../../../ui'
import type { DraftAccount, DraftExpense, ExpenseChanges } from '../types'

/** Sentinel for "no linked account" — never sent to the server. */
const MAIN = '__main__'

export interface ExpenseRowProps {
  expense: DraftExpense
  accounts: readonly DraftAccount[]
  currencyCode: string
  onChange: (changes: ExpenseChanges) => void
  onChangeAccount: (accountId: Uuid | undefined) => void
  t: TFunction
}

export function ExpenseRow({
  expense,
  accounts,
  currencyCode,
  onChange,
  onChangeAccount,
  t,
}: ExpenseRowProps) {
  const selectable = accounts.filter((account) => !account.isPrimary)
  const options = [
    { value: MAIN, label: t('Main') },
    ...selectable.map((account) => ({ value: account.id, label: account.name })),
  ]
  const selected = expense.linkedAccountId ?? MAIN

  return (
    <GlassCard radius="md">
      <div className="ob-expense-row">
        <div className="ob-expense-row__main">
          <span className="ob-expense-row__icon" aria-hidden>
            <Symbol name={expense.icon} size="var(--font-title3-size)" />
          </span>
          <span className="ob-expense-row__name">{expense.name}</span>
          <span className="ob-expense-row__amount">
            <span className="ob-expense-row__currency">{currencyCode}</span>
            <input
              className="ob-expense-row__input"
              data-testid={`onb-expense-amount-${expense.slug}`}
              inputMode="decimal"
              placeholder="0"
              value={expense.amountText}
              aria-label={t('%@ amount', [expense.name])}
              onChange={(event) =>
                onChange({
                  amountText: editingString(event.target.value),
                  amount: parseUserInput(event.target.value),
                })
              }
            />
          </span>
        </div>

        {accounts.length > 0 && (
          <div className="ob-expense-row__from">
            <span>{t('From:')}</span>
            <Menu
              options={options}
              value={selected}
              onChange={(value) => onChangeAccount(value === MAIN ? undefined : value)}
              ariaLabel={t('From:')}
              variant="glass"
            />
          </div>
        )}
      </div>
    </GlassCard>
  )
}

/**
 * The `Account` the server echoed back for a draft row, matched on the id we sent.
 *
 * ⚠️ Case-insensitively, and that is not defensive coding: `crypto.randomUUID()` emits
 * **lowercase**, Swift's `UUID.description` emits **UPPERCASE**, so the id that comes back
 * from `/onboarding/preview` never `===` the one we sent. An exact match silently returned
 * `undefined` for every account, which showed up as an empty `Target:` row on the accounts
 * screen with no error anywhere.
 */
export function serverAccountFor(
  serverAccounts: readonly Account[] | undefined,
  id: Uuid,
): Account | undefined {
  const wanted = id.toLowerCase()
  return serverAccounts?.find((account) => account.id.toLowerCase() === wanted)
}
