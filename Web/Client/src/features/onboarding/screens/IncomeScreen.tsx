/**
 * Income — PARITY-SPEC §2.3.
 *
 * The only screen in onboarding where the currency can be changed
 * (`CurrencyAmountField(showCurrencyPicker: true)`), so the field is composed here from a
 * currency `Menu` plus the amount input, mirroring the iOS `HStack`.
 */

import { editingString, parseUserInput } from '../../../lib/money'
import { Menu, PillButton } from '../../../ui'
import { OnboardingHeader, OnboardingScreen } from '../components/Chrome'
import { hasIncome, trimmedName } from '../draft'
import type { StepProps } from './shared'

export function IncomeScreen({
  draft,
  update,
  state,
  t,
  advance,
  indicatorLabel,
}: StepProps) {
  const canAdvance = hasIncome(draft)
  const currencies = state.reference.currencies

  return (
    <OnboardingScreen
      step="income"
      indicatorLabel={indicatorLabel}
      centered
      footer={
        <PillButton fullWidth disabled={!canAdvance} onClick={advance}>
          {t('Continue')}
        </PillButton>
      }
    >
      <OnboardingHeader
        icon="banknote.fill"
        iconColor="var(--accent-secondary)"
        title={t('Nice to meet you, %@!', [trimmedName(draft)])}
        subtitle={t('How much lands in your account each month after taxes?')}
      />

      <div className="ob-stack-sm">
        <p className="ob-field-label">{t('Monthly net income')}</p>
        <div className="ob-currency-field">
          <Menu
            options={currencies.map((currency) => ({
              value: currency.value,
              label: currency.value,
            }))}
            value={draft.currencyCode}
            onChange={(currencyCode) => update((current) => ({ ...current, currencyCode }))}
            /*
              R28d matrix: `Currency.displayName` is the ONE enum with no `.localized` at
              all (`Utilities/Currency.swift:19-25` — bare literals), so it is English by
              construction on iOS too. Rendered RAW; running it through `tDomain` would be
              the forbidden improvement of R26a.
            */
            ariaLabel={t('Currency: %@', [
              currencies.find((currency) => currency.value === draft.currencyCode)
                ?.displayName ?? draft.currencyCode,
            ])}
            variant="glass"
          />
          <input
            className="ob-currency-field__input"
            data-testid="onb-income-field"
            inputMode="decimal"
            placeholder="0"
            value={draft.incomeText}
            aria-label={t('Monthly income amount')}
            onChange={(event) =>
              update((current) => ({
                ...current,
                incomeText: editingString(event.target.value),
                monthlyIncome: parseUserInput(event.target.value),
              }))
            }
          />
        </div>
      </div>

      <p className="ob-footnote">
        {t(
          "This is your starting point — we'll help you decide where every unit goes.",
        )}
      </p>
    </OnboardingScreen>
  )
}
