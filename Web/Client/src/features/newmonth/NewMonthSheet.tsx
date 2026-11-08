/**
 * New Month flow — PARITY-SPEC §7 (`NewMonthSheet.swift`). Three steps in one sheet.
 *
 * Five traps are handled here at authoring time, each cheap now and expensive later:
 *
 *  1. **The second `-0` site** (`TransferPlanStep.swift:106`). Same rule as the Dashboard:
 *     the minus is a view-level prefix gated on the AMOUNT, so gate on `Money.isZero`,
 *     never on `display === '0'`.
 *  2. **Transfer rows are keyed by INDEX.** `AccountAllocation` has no `id` — iOS mints a
 *     fresh `UUID()` on every computation — and one account can legitimately appear
 *     TWICE (in Split mode with the fund at target, two rows both named "Savings").
 *     Keying by account id or name collapses them and silently loses money from the
 *     display while showing a single plausible row.
 *  3. **The row loop is NEVER filtered.** The *section gate* is `contains { amount > 0 }`,
 *     but `TransferPlanStep.swift:129` then iterates `accountAllocations` unfiltered. In
 *     Prioritized mode (the default) a completed fund still appends an allocation at
 *     `amount = 0`, so iOS renders "Emergency Fund +0 RON" with "100% → 100%". Filtering
 *     the loop would drop a row iOS shows.
 *  4. **When `!isBalanced`, New Month renders NOTHING** — no banner, no warning, no red
 *     state. Onboarding shows an orange warning; New Month has no warning variant at all
 *     (`TransferPlanStep.swift:333-349` is `if isBalanced` only). Do not borrow it.
 *  5. **Step 2 prefills the account's plain stored `currentBalance`, NOT a projection.**
 *     `NewMonthSheet.swift:109` is literally `accountBalances[id] = account.currentBalance`.
 *     Implementing a projection here produces wrong numbers for the rest of the flow.
 */

import { useMemo, useState } from 'react'
import { useT } from '../../lib/i18n'
import { Symbol } from '../../lib/icons'
import { accountSlug } from '../../lib/testid'
import type {
  Account,
  AppState,
  MoneyValue,
  NewMonthPreview,
  TransferPlan,
} from '../../lib/api'
import { api } from '../../lib/api'
import type { EditingString, Money } from '../../lib/money'
import { parseUserInput } from '../../lib/money'
import { AmountField, Divider, GlassCard, PillButton, Sheet } from '../../ui'
import type { NewMonthStep } from '../../state/viewState'
import './newmonth.css'

export interface NewMonthSheetProps {
  state: AppState
  step: NewMonthStep
  onStepChange: (step: NewMonthStep) => void
  onClose: () => void
  onCompleted: (next: AppState) => void
}

export function NewMonthSheet({
  state,
  step,
  onStepChange,
  onClose,
  onCompleted,
}: NewMonthSheetProps) {
  const t = useT('dashboard')
  const tApp = useT('app')

  const [income, setIncome] = useState<EditingString>(state.settings.income.editing)
  // Trap 5: seeded from the PLAIN stored balance, never a projection.
  const [balances, setBalances] = useState<Record<string, EditingString>>(() =>
    Object.fromEntries(state.accounts.map((a) => [a.id, a.currentBalance.editing])),
  )
  const [preview, setPreview] = useState<NewMonthPreview | null>(null)
  const [busy, setBusy] = useState(false)

  const reconcilable = useMemo(
    // §7.2: the server decides. Do NOT hardcode `emergency|savings|personal` — a
    // `personal` account is reconcilable too and was simply absent from the walkthrough.
    () => state.accounts.filter((a) => a.isReconcilable),
    [state.accounts],
  )

  const payload = () => ({
    income: parseUserInput(income),
    reconciledBalances: Object.fromEntries(
      reconcilable.map((a) => [a.id, parseUserInput(balances[a.id] ?? '')]),
    ) as Record<string, Money>,
  })

  const advance = () => {
    if (step === 3) return
    setBusy(true)
    void api
      .previewNewMonth(payload())
      .then((next) => {
        setPreview(next)
        onStepChange((step + 1) as NewMonthStep)
      })
      .finally(() => setBusy(false))
  }

  const complete = () => {
    setBusy(true)
    void api
      .applyNewMonth(payload())
      .then((next) => {
        onCompleted(next)
        onClose()
      })
      .finally(() => setBusy(false))
  }

  // §7: `.interactiveDismissDisabled(currentStep != .salaryEntry)` — steps 2 and 3 cannot
  // be dismissed by tapping outside.
  return (
    <Sheet
      title={t('Step %lld of %lld', [step, 3])}
      cancelLabel={step === 1 ? tApp('Cancel') : t('Back')}
      onCancel={step === 1 ? onClose : () => onStepChange((step - 1) as NewMonthStep)}
      dismissDisabled={step !== 1}
      header={
        <div className="nm-header">
          <PillButton
            variant="glass"
            size="small"
            {...(step === 1 ? {} : { icon: 'chevron.left' as const })}
            onClick={step === 1 ? onClose : () => onStepChange((step - 1) as NewMonthStep)}
            testId={step === 1 ? 'nm-cancel-button' : 'nm-back-button'}
          >
            {step === 1 ? tApp('Cancel') : t('Back')}
          </PillButton>
          <span className="nm-header__title" data-testid="nm-step-label">
            {t('Step %lld of %lld', [step, 3])}
          </span>
          <span />
        </div>
      }
    >
      <div className="nm" data-testid="new-month-sheet">
        {step === 1 && (
          <SalaryEntry
            income={income}
            onIncome={setIncome}
            currency={state.profile?.currencyCode ?? 'RON'}
            lastMonth={state.settings.income}
            busy={busy}
            onContinue={advance}
          />
        )}
        {step === 2 && (
          <Reconcile
            accounts={reconcilable}
            balances={balances}
            onBalance={(id, value) => setBalances((b) => ({ ...b, [id]: value }))}
            currency={state.profile?.currencyCode ?? 'RON'}
            busy={busy}
            onContinue={advance}
          />
        )}
        {step === 3 && preview && (
          <PlanStep plan={preview.transferPlan} busy={busy} onDone={complete} />
        )}
      </div>
    </Sheet>
  )
}

/* ------------------------------------------------------------------ *
 * §7.1 Step 1
 * ------------------------------------------------------------------ */

function SalaryEntry({
  income,
  onIncome,
  currency,
  lastMonth,
  busy,
  onContinue,
}: {
  income: EditingString
  onIncome: (value: EditingString) => void
  currency: string
  lastMonth: MoneyValue
  busy: boolean
  onContinue: () => void
}) {
  const t = useT('dashboard')
  return (
    <div className="nm-step">
      <div className="nm-step__header">
        <Symbol name="dollarsign.circle.fill" size="var(--icon-xl)" />
        <h2 className="nm-step__title">{t('How much did you receive?')}</h2>
      </div>
      <AmountField
        value={income}
        onChange={onIncome}
        currencyCode={currency}
        ariaLabel={t('How much did you receive?')}
        testId="nm-income-field"
      />
      {/* §7.1: shown only when last month's income was > 0. */}
      {!lastMonth.isZero && (
        <p className="nm-step__hint">{t('Last month: %@', [lastMonth.display])}</p>
      )}
      <PillButton
        fullWidth
        // §7.1: `.disabled(income <= 0)`.
        disabled={busy || income.trim() === ''}
        onClick={onContinue}
        testId="nm-next-button"
      >
        {t('Continue')}
      </PillButton>
    </div>
  )
}

/* ------------------------------------------------------------------ *
 * §7.2 Step 2
 * ------------------------------------------------------------------ */

function Reconcile({
  accounts,
  balances,
  onBalance,
  currency,
  busy,
  onContinue,
}: {
  accounts: readonly Account[]
  balances: Record<string, EditingString>
  onBalance: (id: string, value: EditingString) => void
  currency: string
  busy: boolean
  onContinue: () => void
}) {
  const t = useT('dashboard')
  return (
    <div className="nm-step">
      <div className="nm-step__header">
        <Symbol name="arrow.triangle.2.circlepath" size="var(--icon-lg)" />
        <h2 className="nm-step__title">{t('Update your account balances')}</h2>
        <p className="nm-step__subtitle">{t('Did you use any savings this month?')}</p>
      </div>

      {accounts.map((account) => (
        <GlassCard key={account.id}>
          <div className="nm-account">
            <div className="nm-account__top">
              <span className="nm-account__name">
                <Symbol name={account.icon} />
                {account.name}
              </span>
              <span className="nm-account__caption">{t('Current balance')}</span>
            </div>
            <AmountField
              value={balances[account.id] ?? ('' as EditingString)}
              onChange={(value) => onBalance(account.id, value)}
              currencyCode={currency}
              ariaLabel={account.name}
              testId={`nm-balance-${accountSlug(account)}`}
            />
            {/*
              ⚠️ The caption is misleading and iOS ships it that way: "was X last month"
              formats the account's CURRENT balance — the same value prefilling the field
              above it — so on first open the two always agree. Server-composed, rendered
              verbatim.
            */}
            <p className="nm-account__was">{account.wasLastMonthDisplay}</p>
          </div>
        </GlassCard>
      ))}

      {/* §7.2: this button is NEVER disabled. */}
      <PillButton fullWidth disabled={busy} onClick={onContinue} testId="nm-next-button">
        {t('Continue')}
      </PillButton>
    </div>
  )
}

/* ------------------------------------------------------------------ *
 * §7.3 Step 3
 * ------------------------------------------------------------------ */

function PlanStep({
  plan,
  busy,
  onDone,
}: {
  plan: TransferPlan
  busy: boolean
  onDone: () => void
}) {
  const t = useT('dashboard')

  /*
   * §7.3 GATE — and it must be `hasTransfers`, never `accountAllocations.length > 0`.
   * `hasAccountAllocations` is `contains { amount > 0 }`, so a lone ZERO-amount emergency
   * allocation (prioritized, fund at target, multiplier set) leaves it false while the card
   * should still appear if anything else is non-zero. Conversely a false gate with a
   * non-empty array is a real state, not a contradiction.
   *
   * ⚠️ N1 + N4: when `totalExpenses > income`, `availableIncome` clamps to 0, so this gate
   * is false AND `isBalanced` is false. Step 3 then renders the summary card and then
   * NOTHING — no transfers card, no banner, no warning. **That blank area is correct iOS
   * behaviour, not a missing state.** It is the single most inviting place in the flow to
   * add "Your expenses exceed your income!" — do not. Adding it is a behavioural
   * divergence that would look like an improvement (R26a).
   */
  const hasTransfers =
    plan.hasAccountAllocations ||
    plan.accountExpenseTransfers.length > 0 ||
    !plan.remainingMoney.isZero

  return (
    <div className="nm-step">
      <GlassCard>
        <div className="nm-card__header">
          <Symbol name="list.clipboard.fill" />
          <h2 className="nm-card__title">{t('Your Transfer Plan')}</h2>
        </div>
        <div className="nm-summary">
          <PlanRow label={t('Income')} value={plan.income.display} testId="nm-plan-income" />
          {/*
            Trap 1 — the second `-0` site. `TransferPlanStep.swift:106` is the same
            view-level prefix gated on the amount as `SummaryCard.swift:97`, so an
            unguarded "-" renders "-0 RON" at zero expenses. Gate on `isZero`, never on
            `display === '0'` (which also matches 0.4 and misses -0.004).
          */}
          <PlanRow
            label={t('Expenses')}
            value={
              plan.totalExpenses.isZero
                ? plan.totalExpenses.display
                : `-${plan.totalExpenses.display}`
            }
            tone="negative"
            testId="nm-plan-expenses"
          />
          <Divider />
          <PlanRow
            label={t('Available')}
            value={plan.availableIncome.display}
            bold
            testId="nm-plan-available"
          />
        </div>
      </GlassCard>

      {hasTransfers && (
        <GlassCard>
          <h3 className="nm-card__title">{t('Transfers to make')}</h3>
          <div className="nm-transfers" data-testid="nm-transfer-list">
            {/*
              Trap 2 + 3: keyed by INDEX (allocations carry a fresh UUID per computation and
              one account can appear twice), and NEVER filtered — Prioritized mode appends a
              completed fund at amount 0, which iOS renders as "+0 RON" / "100% → 100%".
            */}
            {plan.accountAllocations.map((allocation, index) => (
              <TransferRow
                key={index}
                index={index}
                icon={allocation.icon}
                title={allocation.accountName}
                // Server-composed (R30): "Completes fund to 100%!" when the emergency fund
                // completes, else the progress change. The two screens word this
                // differently, so it must not be assembled client-side.
                {...subtitleProp(allocation.newMonthNote ?? allocation.progressChangeDisplay)}
                amount={allocation.amount.display}
              />
            ))}
            {plan.accountExpenseTransfers.map((transfer, index) => (
              <TransferRow
                key={`expense-${index}`}
                index={plan.accountAllocations.length + index}
                icon="arrow.right.circle.fill"
                title={t('Transfer to %@', [transfer.accountName])}
                subtitle={t('for %@', [transfer.expenseNames.join(', ')])}
                amount={transfer.amount.display}
              />
            ))}
            {!plan.remainingMoney.isZero && (
              <TransferRow
                index={plan.accountAllocations.length + plan.accountExpenseTransfers.length}
                icon="banknote.fill"
                title={plan.remainingDestinationDisplayName}
                subtitle={t('remaining money')}
                amount={plan.remainingMoney.display}
              />
            )}
          </div>
        </GlassCard>
      )}

      <GlassCard>
        <div className="nm-primary">
          <Symbol name="building.columns.fill" />
          <span className="nm-primary__label">{t('stays for automatic payments')}</span>
          <span className="nm-primary__value" data-testid="nm-primary-value">
            {plan.remainsInPrimary.display}
          </span>
        </div>
      </GlassCard>

      {/*
        Trap 4: `if isBalanced` ONLY — there is no `else` in `TransferPlanStep.swift:333-349`.
        `isBalanced == false` ⟺ `totalExpenses > income` (mode- and account-set-independent:
        the only thing that can unbalance the total is the `max(0, …)` clamp on
        availableIncome). At 9,000 income / 9,001 expenses the banner simply disappears.

        **The absence IS the parity target.** Onboarding has an orange warning variant;
        New Month has none. Borrowing it would be a silent behavioural divergence.
      */}
      {plan.isBalanced && (
        <div className="nm-verify" data-testid="nm-verify-badge">
          <Symbol name="checkmark.circle.fill" />
          {t('All amounts add up correctly')}
        </div>
      )}

      <PillButton fullWidth icon="checkmark" disabled={busy} onClick={onDone} testId="nm-done-button">
        {t('Done - I made the transfers')}
      </PillButton>
    </div>
  )
}

/** `exactOptionalPropertyTypes` forbids passing an explicit `undefined` to an optional. */
function subtitleProp(subtitle: string | undefined): { subtitle?: string } {
  return subtitle === undefined ? {} : { subtitle }
}

function PlanRow({
  label,
  value,
  tone = 'neutral',
  bold = false,
  testId,
}: {
  label: string
  value: string
  tone?: 'neutral' | 'negative'
  bold?: boolean
  testId: string
}) {
  return (
    <div className={bold ? 'nm-row nm-row--bold' : 'nm-row'}>
      <span className="nm-row__label">{label}</span>
      <span className={`nm-row__value nm-row__value--${tone}`} data-testid={testId}>
        {value}
      </span>
    </div>
  )
}

function TransferRow({
  index,
  icon,
  title,
  subtitle,
  amount,
}: {
  index: number
  icon: string
  title: string
  subtitle?: string
  amount: string
}) {
  return (
    <div className="nm-transfer" data-testid={`nm-transfer-row-${index}`}>
      <span className="nm-transfer__icon">
        <Symbol name={icon} />
      </span>
      <span className="nm-transfer__text">
        <span className="nm-transfer__title" data-testid={`nm-transfer-name-${index}`}>
          {title}
        </span>
        {subtitle && (
          <span className="nm-transfer__sub" data-testid={`nm-transfer-sub-${index}`}>
            {subtitle}
          </span>
        )}
      </span>
      {/* §7.3: every transfer amount carries a literal "+" prefix. */}
      <span className="nm-transfer__amount" data-testid={`nm-transfer-value-${index}`}>
        +{amount}
      </span>
    </div>
  )
}
