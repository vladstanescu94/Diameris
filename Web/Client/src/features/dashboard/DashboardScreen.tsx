/**
 * Dashboard tab — PARITY-SPEC §4.
 *
 * `DashboardView.swift`. **Entirely read-only**: no taps, no navigation, no edit
 * affordances anywhere in the content (§4 closing note). Four cards in this order:
 * Monthly Summary, Emergency Fund, Account Balances, Expense Breakdown.
 *
 * Every number here is rendered from a server `display` string or a server-truncated
 * integer. Nothing is computed (R2), and progress geometry uses the full double while the
 * label uses the truncated string (R20).
 */

import { useT } from '../../lib/i18n'
import { Symbol } from '../../lib/icons'
import type { Account, AppState, DashboardState } from '../../lib/api'
import { accountSlug, slugify } from '../../lib/testid'
import {
  Badge,
  Divider,
  GlassCard,
  ProgressRing,
  SectionHeader,
} from '../../ui'
import './dashboard.css'

export function DashboardScreen({ state }: { state: AppState }) {
  const t = useT('dashboard')
  const dashboard = state.dashboard

  // §4: the content only renders once onboarding is complete; otherwise the empty state.
  if (!state.onboardingCompleted) {
    return (
      <div className="dash-empty" data-testid="screen-dashboard">
        <Symbol name="chart.bar.doc.horizontal" size="var(--icon-xxl)" />
        <h2 className="dash-empty__title">{t('No data yet')}</h2>
        <p className="dash-empty__body">
          {t('Complete onboarding to start tracking your finances')}
        </p>
      </div>
    )
  }

  return (
    <div className="dash" data-testid="screen-dashboard">
      <SummaryCard dashboard={dashboard} />
      <EmergencyCard dashboard={dashboard} />
      <AccountBalances dashboard={dashboard} />
      <ExpenseBreakdown dashboard={dashboard} />
    </div>
  )
}

/* ------------------------------------------------------------------ *
 * §4.1 SummaryCard
 * ------------------------------------------------------------------ */

function SummaryCard({ dashboard }: { dashboard: DashboardState }) {
  const t = useT('dashboard')
  const { income, expenses, savings, personalSpending } = dashboard.summary

  return (
    <GlassCard>
      <div className="dash-card__header">
        <Symbol name="chart.pie.fill" />
        <h2 className="dash-card__title">{t('Monthly Summary')}</h2>
      </div>
      <Divider />
      <div className="dash-summary">
        <SummaryRow testId="dash-summary-income" label={t('Income')} value={income.display} />
        {/*
          §4.1 / DECISIONS.md R28a. `SummaryCard.swift:97` is
              let prefix = style == .negative && amount > 0 ? "-" : ""
          — a VIEW-LEVEL prefix gated on the amount, applied to an always-non-negative
          Decimal. So at zero expenses iOS renders "0 RON" and an unguarded "-" would
          render "-0 RON".

          Reachable on the very first dashboard a new user sees: "Skip for now" on the
          onboarding expenses screen persists zero Expense rows, so totalExpenses == 0.

          ⚠️ This is the OPPOSITE of R24, where `formatForDisplay(-0.4)` must render "-0"
          because iOS's NumberFormatter really does emit it. Same glyph, opposite rulings.
          They cannot be unified: this is a prefix on a non-negative value, that is
          formatter output for a negative one. Do not "simplify" either into the other.

          The guard is the server's `isZero` — computed from the Decimal. `display === "0
          RON"` would be wrong twice over (it also matches 0.4, and misses -0.004).
        */}
        <SummaryRow
          testId="dash-summary-expenses"
          label={t('Expenses')}
          value={expenses.isZero ? expenses.display : `-${expenses.display}`}
          tone="negative"
        />
        <SummaryRow testId="dash-summary-savings" label={t('Savings')} value={savings.display} tone="positive" />
        <Divider />
        <SummaryRow
          testId="dash-summary-personal-spending"
          label={t('Personal Spending')}
          value={personalSpending.display}
          total
        />
      </div>
    </GlassCard>
  )
}

function SummaryRow({
  label,
  value,
  tone = 'neutral',
  total = false,
  testId,
}: {
  label: string
  value: string
  tone?: 'neutral' | 'negative' | 'positive'
  total?: boolean
  testId: string
}) {
  return (
    <div className={total ? 'dash-row dash-row--total' : 'dash-row'}>
      <span className="dash-row__label">{label}</span>
      <span className={`dash-row__value dash-row__value--${tone}`} data-testid={testId}>
        {value}
      </span>
    </div>
  )
}

/* ------------------------------------------------------------------ *
 * §4.2 EmergencyProgressCard
 * ------------------------------------------------------------------ */

/**
 * §4.2 `progressColor`: `>= 1.0` -> positive; `>= 0.5` -> accentSecondary; else warning.
 *
 * ⚠️ `DiamerisColors.positive` **is** `accentSecondary`, so the first two branches are
 * visually identical and the 0.5 threshold has no visible effect. Reproduced as written
 * rather than "simplified" to two branches, so the shape still matches the source if the
 * colours ever diverge upstream.
 */
function progressColor(progress: number): string {
  if (progress >= 1) return 'var(--color-positive)'
  if (progress >= 0.5) return 'var(--accent-secondary)'
  return 'var(--color-warning)'
}

function EmergencyCard({ dashboard }: { dashboard: DashboardState }) {
  const t = useT('dashboard')
  const fund = dashboard.emergencyFund
  // §4.2: rendered only when the account, its progress and its target all exist.
  if (!fund) return null

  const color = progressColor(fund.progress)

  return (
    <GlassCard>
      <div className="dash-emergency">
        <ProgressRing
          // R20: geometry from the full double, label from the truncated string.
          progress={fund.progress}
          label={fund.progressDisplay}
          // §4.2 `accessibilityLabel(String(localized: "\(Int(progress*100)) percent
          // complete"))` (ProgressRing.swift:46) — the key is therefore
          // "%lld percent complete", carrying the TRUNCATED integer. It resolves against
          // SharedUI's bundle, which has no catalog, so iOS falls back to the key and
          // speaks English even under RO. Our English fallback matches; do NOT add a
          // Romanian entry, that would diverge.
          ariaLabel={t('%lld percent complete', [fund.progressPercent])}
          color={color}
          strokeWidth={10}
          labelTestId="dash-ef-percent"
          arcTestId="dash-ef-ring-arc"
        />
        <div className="dash-emergency__info">
          <div className="dash-card__header" style={{ color }}>
            <Symbol name="shield.fill" />
            <h2 className="dash-card__title">{t('Emergency Fund')}</h2>
          </div>
          {/* Literal " / " separator (§4.2). */}
          <p className="dash-emergency__balance" data-testid="dash-ef-amounts">
            {fund.balance.display} / {fund.target.display}
          </p>
          <p className="dash-emergency__target" data-testid="dash-ef-target-caption">
            {fund.targetCaption}
          </p>
        </div>
      </div>
    </GlassCard>
  )
}

/* ------------------------------------------------------------------ *
 * §4.3 AccountBalancesSection
 * ------------------------------------------------------------------ */

function AccountBalances({ dashboard }: { dashboard: DashboardState }) {
  const t = useT('dashboard')
  const primary = dashboard.primaryAccount

  /*
   * §4.3: the grid shows `!isPrimary && accountType != .emergency` — the emergency
   * account is excluded because it has its own card above. `dashboard.otherAccounts` is
   * only filtered on `isPrimary`, so the emergency filter happens here.
   *
   * ⚠️ Consequence worth knowing, and faithful to iOS: an emergency account with no
   * multiplier renders NO emergency card (§4.2 needs a target) and is still excluded
   * here — so it vanishes from the Dashboard entirely.
   */
  const others = dashboard.otherAccounts.filter((account) => account.accountType !== 'emergency')

  return (
    <section className="dash-balances">
      <SectionHeader title={t('Account Balances')} icon="building.columns.fill" />
      {primary && <PrimaryAccountCard account={primary} />}
      {others.length > 0 && (
        <div className="dash-balances__grid">
          {others.map((account) => (
            <SecondaryAccountCard key={account.id} account={account} />
          ))}
        </div>
      )}
    </section>
  )
}

function PrimaryAccountCard({ account }: { account: Account }) {
  const t = useT('app')
  return (
    <GlassCard>
      <div className="dash-primary">
        <div className="dash-primary__text">
          <span className="dash-primary__name">
            <Symbol name={account.icon} />
            {account.name}
          </span>
          <span
            className="dash-primary__balance"
            data-testid={`dash-account-balance-${accountSlug(account)}`}
          >
            {account.currentBalance.display}
          </span>
        </div>
        <Badge>{t('Primary')}</Badge>
      </div>
    </GlassCard>
  )
}

function SecondaryAccountCard({ account }: { account: Account }) {
  return (
    <GlassCard>
      <div className="dash-secondary">
        <span className="dash-secondary__name">
          <Symbol name={account.icon} />
          {account.name}
        </span>
        <span
          className="dash-secondary__balance"
          data-testid={`dash-account-balance-${accountSlug(account)}`}
        >
          {account.currentBalance.display}
        </span>
      </div>
    </GlassCard>
  )
}

/* ------------------------------------------------------------------ *
 * §4.4 ExpenseBreakdownCard
 * ------------------------------------------------------------------ */

function ExpenseBreakdown({ dashboard }: { dashboard: DashboardState }) {
  const t = useT('dashboard')
  const rows = dashboard.expenseBreakdown

  return (
    <GlassCard>
      <div className="dash-card__header dash-card__header--secondary">
        <Symbol name="chart.pie.fill" />
        <h2 className="dash-card__title">{t('Expense Breakdown')}</h2>
      </div>
      {rows.length === 0 ? (
        <p className="dash-breakdown__empty">{t('No expenses set')}</p>
      ) : (
        <div className="dash-breakdown">
          {/* Already top-5 and amount-descending, server-side (§2.4). Do not re-sort. */}
          {rows.map((row) => (
            <div className="dash-breakdown__row" key={row.id}>
              <span className="dash-breakdown__icon">
                <Symbol name={row.icon} />
              </span>
              <span className="dash-breakdown__name">{row.name}</span>
              <span
                className="dash-breakdown__amount"
                data-testid={`dash-breakdown-amount-${slugify(row.name)}`}
              >
                {row.amount.display}
              </span>
              {/* Server-truncated percentage — never re-derived (R2). */}
              <span
                className="dash-breakdown__percent"
                data-testid={`dash-breakdown-percent-${slugify(row.name)}`}
              >
                {row.percentDisplay}
              </span>
            </div>
          ))}
        </div>
      )}
    </GlassCard>
  )
}
