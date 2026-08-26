/**
 * Accounts — PARITY-SPEC §2.4.
 *
 * Order: header → Your Accounts → Recommended → helper → Continue.
 * The two "Recommended" prompt cards disappear once satisfied, and Continue is enabled as
 * long as a primary account exists (which it always does — the primary cannot be deleted).
 */

import { useState } from 'react'
import type { AccountTypeValue, Uuid } from '../../../lib/api'
import { Symbol } from '../../../lib/icons'
import { GlassCard, PillButton } from '../../../ui'
import { AccountRow } from '../components/AccountRow'
import { AddAccountSheet } from '../components/AddAccountSheet'
import { Helper, OnboardingHeader, OnboardingScreen, SectionTitle } from '../components/Chrome'
import { serverAccountFor } from '../components/ExpenseRow'
import {
  ACCOUNT_FACTORY_NAMES,
  addAccount,
  changeAccountType,
  deleteAccount,
  hasEmergencyAccount,
  hasPrimaryAccount,
  hasPrimarySavingsAccount,
  setPrimarySavings,
  updateAccount,
} from '../draft'
import type { StepProps } from './shared'
import type { ReferenceExt } from '../types'

export function AccountsScreen({
  draft,
  update,
  preview,
  state,
  t,
  tDomain,
  advance,
  indicatorLabel,
}: StepProps) {
  const [expanded, setExpanded] = useState<Uuid | null>(null)
  const [addingAccount, setAddingAccount] = useState(false)

  // R18 item 3 — served on `reference`; `null` on a server that predates it.
  const multiplierOptions =
    (state.reference as ReferenceExt).emergencyMultiplierOptions ?? null
  const hasEmergency = hasEmergencyAccount(draft)
  const hasSavings = hasPrimarySavingsAccount(draft)
  const showsRecommended = !hasEmergency || !hasSavings

  const add = (name: string, accountType: AccountTypeValue) => {
    update((current) => addAccount(current, name, accountType))
  }

  return (
    <OnboardingScreen
      step="accounts"
      indicatorLabel={indicatorLabel}
      footer={
        <PillButton fullWidth disabled={!hasPrimaryAccount(draft)} onClick={advance}>
          {t('Continue')}
        </PillButton>
      }
    >
      <OnboardingHeader
        icon="building.columns.fill"
        iconColor="var(--accent-secondary)"
        title={t('Where does your money live?')}
        subtitle={t('Set up your accounts. We recommend an emergency fund and savings account.')}
      />

      <section className="ob-section">
        <SectionTitle>{t('Your Accounts')}</SectionTitle>
        {draft.accounts.map((account) => (
          <AccountRow
            key={account.id}
            account={account}
            serverAccount={serverAccountFor(preview?.accounts, account.id)}
            accountTypes={state.reference.accountTypes}
            multiplierOptions={multiplierOptions}
            currencyCode={draft.currencyCode}
            disableEmergency={hasEmergency && account.accountType !== 'emergency'}
            expanded={expanded === account.id}
            onToggleExpanded={() =>
              setExpanded((current) => (current === account.id ? null : account.id))
            }
            onChange={(changes) => update((current) => updateAccount(current, account.id, changes))}
            onChangeType={(accountType) =>
              update((current) => changeAccountType(current, account.id, accountType))
            }
            {...(account.isPrimary
              ? {}
              : { onDelete: () => update((current) => deleteAccount(current, account.id)) })}
            onSetPrimarySavings={() =>
              update((current) => setPrimarySavings(current, account.id))
            }
            t={t}
            tDomain={tDomain}
          />
        ))}

        <PillButton
          variant="glass"
          size="small"
          icon="plus.circle.fill"
          testId="onb-add-another-account"
          onClick={() => setAddingAccount(true)}
        >
          {t('Add Another Account')}
        </PillButton>
      </section>

      {showsRecommended && (
        <section className="ob-section">
          <SectionTitle secondary>{t('Recommended')}</SectionTitle>

          {!hasEmergency && (
            <GlassCard radius="lg">
              <div className="ob-prompt__head">
                <Symbol
                  name="shield.fill"
                  color="var(--accent-secondary)"
                  size="var(--icon-md)"
                />
                <span className="ob-prompt__title">{t('Emergency Fund')}</span>
                <span className="ob-prompt__spacer" />
                <PillButton
                  size="small"
                  testId="onb-add-account-emergency"
                  onClick={() => add(tDomain(ACCOUNT_FACTORY_NAMES.emergency), 'emergency')}
                >
                  {t('Add')}
                </PillButton>
              </div>
              <p className="ob-prompt__body">
                {t('Protects you from unexpected expenses. Recommended: 3-6 months of income.')}
              </p>
            </GlassCard>
          )}

          {!hasSavings && (
            <GlassCard radius="lg">
              <div className="ob-prompt__head">
                <Symbol
                  name="banknote.fill"
                  color="var(--accent-secondary)"
                  size="var(--icon-md)"
                />
                <span className="ob-prompt__title">{t('Savings Account')}</span>
                <span className="ob-prompt__spacer" />
                <PillButton
                  size="small"
                  testId="onb-add-account-savings"
                  onClick={() => add(tDomain(ACCOUNT_FACTORY_NAMES.savings), 'savings')}
                >
                  {t('Add')}
                </PillButton>
              </div>
              <p className="ob-prompt__body">
                {t('Build wealth over time. After emergency fund is full, savings go here.')}
              </p>
            </GlassCard>
          )}
        </section>
      )}

      <Helper text={t('Your primary account is where your salary lands')} />

      {addingAccount && (
        <AddAccountSheet
          accountTypes={state.reference.accountTypes}
          disableEmergency={hasEmergency}
          onAdd={(name, accountType) => {
            add(name, accountType)
            setAddingAccount(false)
          }}
          onCancel={() => setAddingAccount(false)}
          t={t}
          tDomain={tDomain}
        />
      )}
    </OnboardingScreen>
  )
}
