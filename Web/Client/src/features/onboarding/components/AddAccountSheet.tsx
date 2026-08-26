/**
 * `AddAccountSheet` — PARITY-SPEC §2.4.4. Presented from "Add Another Account".
 *
 * Initial type is **`.other`**. Three quick-suggestion chips set both name and type.
 *
 * ⚠️ Reproduced faithfully, both logged in `PARITY-GAPS.md`:
 *   - the chip labelled **"Emergency" creates a `savings` account** (`AddAccountSheet.swift:65`);
 *   - the three chip titles are **raw English literals with no `.localized`** on iOS, so they
 *     render English even in Romanian. They go through `t()` here so the key is at least
 *     translatable, and the RO catalog can decide to match iOS by leaving them English.
 */

import { useState } from 'react'
import type { AccountTypeRef, AccountTypeValue } from '../../../lib/api'
import type { TFunction } from '../../../lib/i18n'
import { Symbol } from '../../../lib/icons'
import { PillButton, Sheet, TextField } from '../../../ui'
import { ACCOUNT_TYPE_COLOR } from './AccountRow'

interface Suggestion {
  readonly title: string
  readonly accountType: AccountTypeValue
}

/** `AddAccountSheet.swift:61-72`. */
const SUGGESTIONS: readonly Suggestion[] = [
  { title: 'Joint', accountType: 'joint' },
  // ⚠️ Not a typo — the "Emergency" chip really does create a savings account.
  { title: 'Emergency', accountType: 'savings' },
  { title: 'Travel', accountType: 'savings' },
]

export interface AddAccountSheetProps {
  accountTypes: readonly AccountTypeRef[]
  /** Emergency is offered disabled when one already exists. */
  disableEmergency: boolean
  onAdd: (name: string, accountType: AccountTypeValue) => void
  onCancel: () => void
  t: TFunction
  tDomain: TFunction
}

export function AddAccountSheet({
  accountTypes,
  disableEmergency,
  onAdd,
  onCancel,
  t,
  tDomain,
}: AddAccountSheetProps) {
  const [name, setName] = useState('')
  const [accountType, setAccountType] = useState<AccountTypeValue>('other')
  const trimmed = name.trim()

  return (
    <Sheet
      title={t('Add Account')}
      cancelLabel={t('Cancel')}
      confirmLabel={t('Add')}
      confirmDisabled={trimmed.length === 0}
      onCancel={onCancel}
      onConfirm={() => onAdd(trimmed, accountType)}
      size="medium"
    >
      <div className="ob-stack-md">
        <TextField
          value={name}
          onChange={setName}
          label={t('Account Name')}
          placeholder={t('e.g., Joint Account')}
        />

        <div className="ob-stack-sm">
          <p className="ob-field-label">{t('Account type')}</p>
          <div className="ob-type-grid" role="group" aria-label={t('Account type')}>
            {accountTypes.map((entry) => {
              const disabled = entry.value === 'emergency' && disableEmergency
              const selected = entry.value === accountType
              return (
                <button
                  key={entry.value}
                  type="button"
                  className="ob-type-cell"
                  aria-pressed={selected}
                  disabled={disabled}
                  title={disabled ? t('Only one emergency account allowed') : undefined}
                  style={{ '--ob-account-color': ACCOUNT_TYPE_COLOR[entry.value] } as never}
                  onClick={() => setAccountType(entry.value)}
                >
                  <Symbol name={entry.icon} size="var(--font-title3-size)" />
                  <span className="ob-type-cell__name">{tDomain(entry.displayName)}</span>
                  <span className="ob-type-cell__description">{tDomain(entry.description)}</span>
                </button>
              )
            })}
          </div>
        </div>

        <div className="ob-stack-sm">
          <p className="ob-caption">{t('Quick suggestions')}</p>
          <div className="ob-row">
            {SUGGESTIONS.map((suggestion) => (
              <PillButton
                key={suggestion.title}
                variant="glass"
                size="small"
                onClick={() => {
                  setName(t(suggestion.title))
                  setAccountType(suggestion.accountType)
                }}
              >
                {t(suggestion.title)}
              </PillButton>
            ))}
          </div>
        </div>
      </div>
    </Sheet>
  )
}
