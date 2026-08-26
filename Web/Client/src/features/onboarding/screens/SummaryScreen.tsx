/**
 * First-month summary / Transfer Plan — PARITY-SPEC §2.7. No progress indicator.
 *
 * Order: header → income hero → transfer cards → remaining money → verification → tip →
 * Start Using Diameris.
 *
 * Every figure is a `MoneyValue.display` from `preview.transferPlan`, and `isBalanced`
 * arrives as a boolean (R2) — the "All accounted for!" banner is never decided here.
 */

import type { AccountTypeValue } from '../../../lib/api'
import { Symbol } from '../../../lib/icons'
import { AppColumn, GlassCard, PillButton, ProgressBar, Surface } from '../../../ui'
import { ACCOUNT_TYPE_COLOR } from '../components/AccountRow'
import { SectionTitle } from '../components/Chrome'
import { RemainingMoneyPicker } from '../components/RemainingMoneyPicker'
import { hasPrimarySavingsAccount, isPositive, trimmedName } from '../draft'
import type { StepProps } from './shared'

export interface SummaryScreenProps extends StepProps {
  /** POSTs `/onboarding/complete` and hands the new `AppState` to the shell. */
  readonly onComplete: () => void
  readonly completing: boolean
}

export function SummaryScreen({
  draft,
  update,
  preview,
  state,
  t,
  tDomain,
  onComplete,
  completing,
}: SummaryScreenProps) {
  const plan = preview?.transferPlan
  const hasPersonal = draft.accounts.some((account) => account.accountType === 'personal')

  return (
    <Surface>
      <AppColumn>
        <div className="ob-summary" data-testid="onb-summary">
          <header className="ob-summary__header">
            <span className="ob-summary__check" aria-hidden>
              <Symbol name="checkmark.circle.fill" size="var(--icon-hero)" />
            </span>
            <h1 className="ob-summary__title">{t('Your First Month')}</h1>
            <p className="ob-summary__subtitle">
              {t("Here's your personalized transfer plan, %@!", [trimmedName(draft)])}
            </p>
          </header>

          {plan && (
            <>
              <GlassCard radius="lg">
                <div className="ob-income-card">
                  <span className="ob-income-card__label">{t('Monthly Income')}</span>
                  <span className="ob-income-card__amount" data-testid="onb-summary-income-value">
                    {plan.income.display}
                  </span>
                </div>
              </GlassCard>

              <section className="ob-section">
                <SectionTitle>{t('Your Transfers')}</SectionTitle>

                {/*
                  ⚠️ DECISIONS.md **R25 row 8** — keyed by INDEX, not by `accountId`, and
                  rendered as an ordered list rather than a map. One account can legitimately
                  appear **twice**: when the emergency fund is full its share overflows to
                  savings, producing two rows both named "Savings" (`+1,182` and `+3,548`),
                  distinguished only by the second's subtitle. Keying on the account id
                  collapses them in React and silently drops 3,548 RON from the display.
                */}
                {plan.accountAllocations.map((allocation, index) => (
                  <GlassCard key={index} radius="lg">
                    <div className="ob-transfer-card">
                      <div className="ob-transfer-card__head">
                        <Symbol
                          name={allocation.icon}
                          size="var(--icon-md)"
                          color={ACCOUNT_TYPE_COLOR[allocation.accountType as AccountTypeValue]}
                        />
                        <span className="ob-transfer-card__name">{allocation.accountName}</span>
                        <span
                          className="ob-transfer-card__amount"
                          data-testid={
                            allocation.accountType === 'emergency'
                              ? 'onb-summary-transfer-emergency-value'
                              : undefined
                          }
                        >
                          {allocation.amount.display}
                        </span>
                      </div>

                      {allocation.progressChangeDisplay != null && (
                        <p
                          className={
                            allocation.isComplete
                              ? 'ob-transfer-card__change ob-transfer-card__change--complete'
                              : 'ob-transfer-card__change'
                          }
                        >
                          {/* R20: the label is the server's truncated "0% → 4%" string. */}
                          {allocation.progressChangeDisplay}
                          {allocation.isComplete && (
                            <>
                              <Symbol
                                name="checkmark.circle.fill"
                                size="var(--font-caption-size)"
                              />
                              {t('Target reached!')}
                            </>
                          )}
                        </p>
                      )}

                      {allocation.accountType === 'emergency' && allocation.targetAmount && (
                        <>
                          {/* R20: geometry is the full double `progressAfter`. */}
                          <ProgressBar
                            progress={allocation.progressAfter ?? 0}
                            variant="tint"
                            color={
                              allocation.isComplete
                                ? 'var(--color-green)'
                                : 'var(--color-orange)'
                            }
                            {...(allocation.progressChangeDisplay
                              ? { ariaValueText: allocation.progressChangeDisplay }
                              : {})}
                            fillTestId="onb-summary-transfer-emergency-progress"
                            ariaLabel={allocation.accountName}
                          />
                          <p className="ob-caption" data-testid="onb-summary-emergency-target">
                            {t('Target: %@', [allocation.targetAmount.display])}
                          </p>
                        </>
                      )}
                    </div>
                  </GlassCard>
                ))}

                {/* Same rule: an ordered list, never keyed by account (R25 row 8). */}
                {plan.accountExpenseTransfers.map((transfer, index) => (
                  <GlassCard key={index} radius="lg">
                    <div className="ob-transfer-card">
                      <div className="ob-transfer-card__head">
                        <Symbol
                          name="arrow.right.circle.fill"
                          size="var(--icon-md)"
                          color="var(--color-purple)"
                        />
                        <span className="ob-transfer-card__name">
                          {t('Transfer to %@', [transfer.accountName])}
                        </span>
                        <span className="ob-transfer-card__amount">
                          {transfer.amount.display}
                        </span>
                      </div>
                      <p className="ob-caption">
                        {t('for %@', [transfer.expenseNames.join(', ')])}
                      </p>
                    </div>
                  </GlassCard>
                ))}

                <GlassCard radius="lg">
                  <div className="ob-transfer-card">
                    <div className="ob-transfer-card__head">
                      <Symbol
                        name="building.columns.fill"
                        size="var(--icon-md)"
                        color="var(--accent-primary)"
                      />
                      <span className="ob-transfer-card__name">{t('Stays in Primary')}</span>
                      <span
                        className="ob-transfer-card__amount"
                        data-testid="onb-summary-stays-in-primary-value"
                      >
                        {plan.remainsInPrimary.display}
                      </span>
                    </div>
                    <p className="ob-caption">{t('For automatic bill payments')}</p>
                  </div>
                </GlassCard>
              </section>

              {/* Shown only when there is remaining money (§2.7 step 4). */}
              {isPositive(plan.remainingMoney.amount) && (
                <section className="ob-section">
                  <SectionTitle>{t('Remaining Money')}</SectionTitle>
                  <GlassCard radius="lg">
                    <div className="ob-transfer-card__head">
                      <Symbol
                        name="dollarsign.circle.fill"
                        size="var(--icon-md)"
                        color="var(--color-green)"
                      />
                      <span className="ob-transfer-card__name">
                        {t('Available after savings')}
                      </span>
                      <span
                        className="ob-transfer-card__amount ob-transfer-card__amount--positive"
                        data-testid="onb-summary-remaining-value"
                      >
                        {plan.remainingMoney.display}
                      </span>
                    </div>
                  </GlassCard>
                  <p className="ob-caption">{t('Where should this go?')}</p>
                  <RemainingMoneyPicker
                    destinations={state.reference.remainingMoneyDestinations}
                    hasPrimarySavings={hasPrimarySavingsAccount(draft)}
                    hasPersonal={hasPersonal}
                    value={draft.remainingMoneyDestination}
                    onChange={(remainingMoneyDestination) =>
                      update((current) => ({ ...current, remainingMoneyDestination }))
                    }
                    t={t}
                    tDomain={tDomain}
                  />
                </section>
              )}

              <div
                className={
                  plan.isBalanced ? 'ob-verification' : 'ob-verification ob-verification--unbalanced'
                }
              >
                <span className="ob-verification__icon">
                  <Symbol
                    name={
                      plan.isBalanced ? 'checkmark.circle.fill' : 'exclamationmark.triangle.fill'
                    }
                    size="var(--icon-md)"
                  />
                </span>
                <span className="ob-verification__total" data-testid="onb-summary-total">
                  {t('Total: %@', [plan.income.display])}
                </span>
                {plan.isBalanced && <span className="ob-caption">{t('All accounted for!')}</span>}
              </div>

              <p className="ob-tip">
                <span className="ob-tip__icon">
                  <Symbol name="lightbulb.fill" size="var(--icon-md)" />
                </span>
                {t('Tip: Do these transfers right after payday for best results!')}
              </p>
            </>
          )}

          <PillButton fullWidth disabled={completing} onClick={onComplete}>
            {t('Start Using Diameris')}
          </PillButton>
        </div>
      </AppColumn>
    </Surface>
  )
}
