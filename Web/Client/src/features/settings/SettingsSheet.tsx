/**
 * Settings — PARITY-SPEC §8 (`SettingsSheet.swift`). A `Form`, so a GROUPED surface.
 *
 * Cancel/Save semantics: edits are local until Save, which PUTs and replaces the whole
 * store; Cancel discards. Three sections — Profile, Savings, Accounts.
 *
 * The traps here read **account properties** and never touch the `TransferPlan`, so unlike
 * New Month they have no mode axis at all — do not over-condition them:
 *  - **N5** no `emergencyMultiplier` → no "3× income" subtitle part
 *  - **N6** not primary savings → no "Primary" part
 *  - **N7** neither emergency nor savings account → the whole Accounts section is absent
 * All three fall out of the server's `subtitleParts` and the account list, so none is
 * implemented as a client-side rule.
 *
 * Two more, both easy to "fix" into a divergence:
 *  - the "Total exceeds available income" footer is **split-only** — prioritized cannot
 *    over-allocate, so a universal footer would show where iOS never does.
 *  - the savings slider is an **index lookup** into `savingsSliderPositions` (R13). Every
 *    caption comes from the row; nothing is computed per frame.
 */

import { useState } from 'react'
import { useT, useTDomain } from '../../lib/i18n'
import { Symbol } from '../../lib/icons'
import { accountSlug } from '../../lib/testid'
import {
  api,
  type Account,
  type AccountSubtitlePart,
  type AllocationModeValue,
  type AppState,
  type RemainingMoneyDestinationValue,
  type SavingsInputModeValue,
  type SavingsSliderPosition,
} from '../../lib/api'
import { editingString, type EditingString } from '../../lib/money'
import {
  Divider,
  GlassCard,
  Menu,
  SectionHeader,
  SegmentedControl,
  Sheet,
  Slider,
  TextField,
  Toggle,
} from '../../ui'
import './settings.css'

export interface SettingsSheetProps {
  state: AppState
  onClose: () => void
  onSaved: (next: AppState) => void
}

export function SettingsSheet({ state, onClose, onSaved }: SettingsSheetProps) {
  const t = useT('app')
  const tDomain = useTDomain()
  const savings = state.settings.savings

  const [name, setName] = useState(state.profile?.name ?? '')
  const [currency, setCurrency] = useState(state.profile?.currencyCode ?? 'RON')
  const [mode, setMode] = useState<AllocationModeValue>(savings.allocationMode)
  const [inputMode, setInputMode] = useState<SavingsInputModeValue>(savings.savingsInputMode)
  const [boost, setBoost] = useState(savings.boostEnabled)
  const [destination, setDestination] = useState<RemainingMoneyDestinationValue>(
    state.profile?.remainingMoneyDestination ?? 'primarySavings',
  )
  const [busy, setBusy] = useState(false)

  /*
   * R13: the slider's value is an INDEX into the server's table, not a percentage. Every
   * label below reads off the selected row, so no percentage or amount is ever derived
   * here — a float accumulating across drags cannot desynchronise from what is displayed.
   */
  const positions = savings.savingsSliderPositions
  const [index, setIndex] = useState(() => {
    /*
     * Match on the table's own `percentage`, NOT on a derived percent. My first attempt was
     * `p.percent === Math.round(savings.percentage * 100)` — the R2 guard caught it, and
     * correctly: that is client-side arithmetic on a rate, and `Math.round` is half-up
     * where iOS truncates. The table already carries the exact value the server holds, so
     * an equality check needs no maths at all.
     */
    const found = positions.findIndex((p) => p.percentage === savings.percentage)
    return found === -1 ? positions.findIndex((p) => p.isRecommended) : found
  })
  const position: SavingsSliderPosition | undefined = positions[index]

  const save = () => {
    setBusy(true)
    void api
      .updateSettings({
        name,
        currencyCode: currency,
        remainingMoneyDestination: destination,
        savings: {
          percentage: position?.percentage ?? savings.percentage,
          allocationMode: mode,
          savingsInputMode: inputMode,
          boostEnabled: boost,
        },
      })
      .then((next) => {
        onSaved(next)
        onClose()
      })
      .finally(() => setBusy(false))
  }

  // N7: the section exists only when there is an emergency or savings account. Derived
  // from the account set, never from the transfer plan.
  //
  // The `isPrimarySavings` disjunct is load-bearing and easy to drop — iOS is
  // `accountType == .savings || isPrimarySavings` (SettingsSheet.swift:61-63), NOT just the
  // account type. An account flagged isPrimarySavings while typed `.personal` still makes iOS
  // render the whole savings-distribution section. Omitting it hid the section where iOS shows
  // it. iOS additionally normalises on save (`:605`, isPrimarySavings = accountType == .savings
  // ? … : false), so the state is only reachable via the API — which is why the server now
  // enforces the same normalisation.
  const showAccounts = state.accounts.some(
    (a) => a.accountType === 'emergency' || a.accountType === 'savings' || a.isPrimarySavings,
  )

  return (
    <Sheet
      title={t('Settings')}
      cancelLabel={t('Cancel')}
      confirmLabel={t('Save')}
      onCancel={onClose}
      onConfirm={save}
      confirmDisabled={busy}
    >
      <div className="set" data-testid="settings-sheet">
        <section className="set-section">
          <SectionHeader title={t('Profile')} variant="grouped" />
          <GlassCard>
            <TextField
              value={name}
              onChange={setName}
              label={t('Name')}
              testId="settings-name-field"
            />
            <Divider />
            <div className="set-row">
              <span className="set-row__label">{t('Currency')}</span>
              <Menu
                value={currency}
                onChange={setCurrency}
                ariaLabel={t('Currency')}
                testId="settings-currency-menu"
                // ⛔ `Currency.displayName` has no `.localized` at all — bare English
                // literals. Rendering it RAW is correct (R28d); tDomain would diverge.
                options={state.reference.currencies.map((c) => ({
                  value: c.value,
                  label: c.displayName,
                }))}
              />
            </div>
          </GlassCard>
        </section>

        <section className="set-section">
          <SectionHeader title={t('Savings')} variant="grouped" />
          <GlassCard>
            <SegmentedControl<AllocationModeValue>
              ariaLabel={t('Allocation Mode')}
              value={mode}
              onChange={setMode}
              segments={state.reference.allocationModes.map((m) => ({
                value: m.value,
                // ✅ tDomain — AllocationMode IS translated on iOS (R28d matrix).
                label: tDomain(m.displayName),
                testId: `settings-strategy-${m.value === 'prioritized' ? 'priority' : 'split'}`,
              }))}
            />
            <p className="set-caption">
              {tDomain(
                state.reference.allocationModes.find((m) => m.value === mode)?.description ?? '',
              )}
            </p>

            <Divider />

            <SegmentedControl<SavingsInputModeValue>
              ariaLabel={t('Savings Type')}
              value={inputMode}
              onChange={setInputMode}
              segments={state.reference.savingsInputModes.map((m) => ({
                value: m.value,
                // ✅ tDomain — SavingsInputMode IS translated.
                label: tDomain(m.displayName),
                testId: `settings-mode-${m.value === 'percentage' ? 'percentage' : 'fixed'}`,
              }))}
            />

            {mode === 'prioritized' && (
              <>
                <div className="set-row">
                  <span className="set-row__label">{t('Savings Rate')}</span>
                  {/* Straight off the selected row — never `Int(pct*100)` client-side. */}
                  <span className="set-row__value" data-testid="settings-savings-rate">
                    {position?.percentDisplay ?? savings.percentageDisplay}
                  </span>
                </div>
                <Slider
                  ariaLabel={t('Savings Rate')}
                  ariaValueText={position?.percentDisplay ?? ''}
                  variant="accent"
                  value={index}
                  min={0}
                  max={positions.length - 1}
                  step={1}
                  onChange={setIndex}
                  testId="settings-savings-slider"
                />
              </>
            )}

            {/* Split-ONLY: prioritized cannot over-allocate, so this must not be universal. */}
            {mode === 'split' && (
              <>
                <SplitSideRow side="emergency" label={t('Emergency')} data={savings.split.emergency} />
                <SplitSideRow side="savings" label={t('Savings')} data={savings.split.savings} />
                <div className="set-row">
                  <span className="set-row__label">{t('Total Monthly')}</span>
                  <span className="set-row__value" data-testid="settings-split-total-monthly">
                    {savings.split.requestedTotal.display}
                  </span>
                </div>
                {savings.split.wasScaledDown && (
                  <p className="set-caption set-caption--warning">
                    {t('Total exceeds available income. Amounts will be reduced proportionally.')}
                  </p>
                )}
              </>
            )}

            <Divider />

            <div className="set-row">
              <Toggle
                checked={boost}
                onChange={setBoost}
                label={t('Savings Boost')}
                testId="settings-boost-switch"
              />
            </div>
            {/* `boostedPercentDisplay` is always sent; the ROW is conditional. */}
            {boost && (
              <div className="set-row">
                <span className="set-row__label">{t('Effective Rate')}</span>
                <span className="set-row__value">{savings.boostedPercentDisplay}</span>
              </div>
            )}
          </GlassCard>
          <p className="set-caption">{t('Savings are calculated from income after expenses.')}</p>
        </section>

        {/* §8.4 Remaining Money — the one section that hits the R36 shadowed label. */}
        <section className="set-section">
          <SectionHeader title={t('Remaining Money')} variant="grouped" />
          <GlassCard>
            <div className="set-row">
              <span className="set-row__label">{t('Destination')}</span>
              <Menu
                value={destination}
                onChange={setDestination}
                ariaLabel={t('Destination')}
                testId="settings-destination-menu"
                options={state.reference.remainingMoneyDestinations.map((d) => ({
                  value: d.value,
                  label: settingsDestinationLabel(d.value, d.displayName, t, tDomain),
                }))}
              />
            </div>
          </GlassCard>
          <p className="set-caption">{t('Where leftover money goes after savings allocation.')}</p>
        </section>

        {showAccounts && (
          <section className="set-section">
            <SectionHeader title={t('Accounts')} variant="grouped" />
            <GlassCard padded={false}>
              <div className="set-accounts">
                {state.accounts.map((account, i) => (
                  <div key={account.id}>
                    <AccountRow account={account} />
                    {i < state.accounts.length - 1 && <Divider inset />}
                  </div>
                ))}
              </div>
            </GlassCard>
            <p className="set-caption">{t('Tap an account to edit its settings.')}</p>
          </section>
        )}
      </div>
    </Sheet>
  )
}

/* ------------------------------------------------------------------ *
 * R36 — Settings shadows ONE destination label
 * ------------------------------------------------------------------ */

/**
 * `SettingsSheet.swift:698-706` declares a `private extension RemainingMoneyDestination`
 * whose `displayName` **shadows Domain's for that file only**. So `.primary` reads
 * differently on the two screens, and both are translated:
 *
 *   | case             | Settings                          | Onboarding                              |
 *   |------------------|-----------------------------------|-----------------------------------------|
 *   | `primary`        | "Primary Account" / Cont principal | "Keep in Primary" / Păstrează în Principal |
 *   | `primarySavings` | identical on both                  | identical                               |
 *   | `personal`       | identical on both                  | identical                               |
 *
 * ⚠️ Do NOT unify them, and do not leave either in English. Only `.primary` is overridden
 * — mapping the whole enum through a Settings table would silently change the other two.
 */
function settingsDestinationLabel(
  value: RemainingMoneyDestinationValue,
  domainDisplayName: string,
  t: (key: string) => string,
  tDomain: (key: string) => string,
): string {
  return value === 'primary' ? t('Primary Account') : tDomain(domainDisplayName)
}

/* ------------------------------------------------------------------ *
 * §8.3 Account rows
 * ------------------------------------------------------------------ */

function AccountRow({ account }: { account: Account }) {
  return (
    <button
      type="button"
      className="set-account"
      data-testid={`settings-account-row-${accountSlug(account)}`}
    >
      <span className="set-account__icon">
        <Symbol name={account.icon} />
      </span>
      <span className="set-account__text">
        <span className="set-account__name">{account.name}</span>
        {/*
          R27/N5/N6: 2–3 INDEPENDENTLY COLOURED runs at an 8px gap — never one string, and
          never split on "•" (the bullet belongs to the part). The absences are data, not
          logic: no `emergencyMultiplier` simply means the server sends no "3× income" part,
          and a non-primary-savings account sends no "Primary" part. There is nothing to
          branch on here, which is why this renders the array as given.
        */}
        <span className="set-account__subtitle">
          {account.subtitleParts.map((part, i) => (
            <SubtitlePart key={i} part={part} />
          ))}
        </span>
      </span>
      <span className="set-account__chevron">
        <Symbol name="chevron.right" />
      </span>
    </button>
  )
}

function SubtitlePart({ part }: { part: AccountSubtitlePart }) {
  return (
    <span
      className={`set-account__part set-account__part--${part.tone}`}
      data-testid="settings-account-subtitle-part"
    >
      {part.text}
    </span>
  )
}

/* ------------------------------------------------------------------ *
 * Split sides
 * ------------------------------------------------------------------ */

function SplitSideRow({
  side,
  label,
  data,
}: {
  side: 'emergency' | 'savings'
  label: string
  data: AppState['settings']['savings']['split']['emergency']
}) {
  return (
    <div className="set-row">
      <span className="set-row__label">{label}</span>
      <span className="set-row__value" data-testid={`settings-split-${side}-rate`}>
        {data.percentDisplay}
      </span>
      {/*
        ⚠️ Resolved against availableIncome, and each side rounds half-even independently —
        so the two sides can display as summing to 1,183 beside a total of 1,182.
        Server-computed; reproduce, do not reconcile.
      */}
      <span className="set-row__value" data-testid={`settings-split-${side}-resolved-amount`}>
        {data.resolvedAmount.display}
      </span>
    </div>
  )
}

/** Kept for the account editor, which needs `balanceEditorValue` rather than `editing`. */
export function accountEditorBalance(account: Account): EditingString {
  /*
   * ⚠️ The Settings account editor uses `TextField(format: .number)`, NOT `AmountFormatter`.
   * It follows the DEVICE locale, groups (`"1,182.5"`), and shows `"0"` rather than blank.
   * `Money.editing` is wrong for this one field — verified in the simulator, where Target
   * Amount renders `27,000 RON` beside a Current Balance of `2.365` for a stored `2365`.
   */
  return editingString(account.balanceEditorValue)
}
