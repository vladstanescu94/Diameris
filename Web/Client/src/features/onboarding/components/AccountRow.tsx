/**
 * `AccountRow` + `EmergencyMultiplierPicker` — PARITY-SPEC §2.4.1 / §2.4.2.
 *
 * Every number rendered here comes from the server's preview copy of this account
 * (`emergencyTarget.display`, `emergencyProgress`, `emergencyProgressDisplay`). The row
 * never derives a target from income × multiplier — that is the R18 item 2 hole.
 */

import { useState, type CSSProperties } from 'react'
import type { AccountTypeRef, AccountTypeValue } from '../../../lib/api'
import type { TFunction } from '../../../lib/i18n'
import { Symbol } from '../../../lib/icons'
import { editingString, parseUserInput } from '../../../lib/money'
import { Badge, Divider, GlassCard, Menu, ProgressBar, Toggle } from '../../../ui'
import {
  EMERGENCY_MULTIPLIERS,
  EMERGENCY_MULTIPLIER_CAPTIONS,
  isPositive,
} from '../draft'
import type {
  AccountChanges,
  AccountExt,
  DraftAccount,
  EmergencyMultiplierOption,
} from '../types'

/** `formatForEditing(0)` is `""` on iOS; the same empty field here. */
const EMPTY_INPUT = editingString('')

/** `AccountType+Color.swift` — the one mapping, mirrored onto tokens. */
export const ACCOUNT_TYPE_COLOR: Readonly<Record<AccountTypeValue, string>> = {
  primary: 'var(--accent-primary)',
  emergency: 'var(--color-warning)',
  savings: 'var(--accent-secondary)',
  personal: 'var(--color-purple)',
  joint: 'var(--color-pink)',
  other: 'var(--label-secondary)',
}

/** Only emergency and savings rows expand (`AccountRow.swift`, §2.4.1). */
export function isExpandable(account: DraftAccount): boolean {
  return account.accountType === 'emergency' || account.accountType === 'savings'
}

export interface AccountRowProps {
  account: DraftAccount
  /** The same account as the server sees it, for target/progress. `undefined` before the
   *  first preview lands, so the key is required and the value nullable. */
  serverAccount: AccountExt | undefined
  accountTypes: readonly AccountTypeRef[]
  /** `reference.emergencyMultiplierOptions` — `null` on a server that predates R18. */
  multiplierOptions: readonly EmergencyMultiplierOption[] | null
  currencyCode: string
  /** True when a DIFFERENT account already occupies the emergency slot. */
  disableEmergency: boolean
  expanded: boolean
  onToggleExpanded: () => void
  onChange: (changes: AccountChanges) => void
  onChangeType: (accountType: AccountTypeValue) => void
  /** Absent for the primary account, which can never be removed. */
  onDelete?: () => void
  onSetPrimarySavings: () => void
  t: TFunction
  tDomain: TFunction
}

export function AccountRow({
  account,
  serverAccount,
  accountTypes,
  multiplierOptions,
  currencyCode,
  disableEmergency,
  expanded,
  onToggleExpanded,
  onChange,
  onChangeType,
  onDelete,
  onSetPrimarySavings,
  t,
  tDomain,
}: AccountRowProps) {
  const [editingName, setEditingName] = useState(false)
  const type = accountTypes.find((entry) => entry.value === account.accountType)
  const color = ACCOUNT_TYPE_COLOR[account.accountType]
  const expandable = isExpandable(account)

  const options = accountTypes.map((entry) => ({
    value: entry.value,
    // ⚠️ ` (only one allowed)` is built by string interpolation in iOS and is NOT
    // localized there (§2.4.3). Reproduced through t() so RO at least has the option.
    label:
      entry.value === 'emergency' && disableEmergency
        ? `${tDomain(entry.displayName)}${t(' (only one allowed)')}`
        : tDomain(entry.displayName),
  }))

  return (
    <GlassCard padded={false} radius="lg">
      <div className="ob-account-row__main">
        <span
          className="ob-account-row__icon"
          style={{ '--ob-account-color': color } as CSSProperties}
          aria-hidden
        >
          <Symbol name={type?.icon ?? 'creditcard.fill'} size="var(--font-title3-size)" />
        </span>

        <div className="ob-account-row__content">
          <div className="ob-account-row__name-line">
            {/*
              §2.4.1: the name is a label until tapped, and only then becomes a field —
              which is also what keeps the badge on the same line as the name, as in
              `04-onboarding-accounts.jpg`. Committing on Return and NOT on blur mirrors
              the iOS behaviour (there is no blur commit there); writing through on every
              keystroke means nothing can be lost either way.
            */}
            {editingName ? (
              <input
                className="ob-account-row__name-input"
                value={account.name}
                autoFocus
                aria-label={t('Account name')}
                onChange={(event) => onChange({ name: event.target.value })}
                onKeyDown={(event) => {
                  if (event.key === 'Enter') setEditingName(false)
                }}
              />
            ) : (
              <button
                type="button"
                className="ob-account-row__name"
                onClick={() => setEditingName(true)}
              >
                {account.name}
              </button>
            )}
            {account.isPrimary && <Badge tone="accent">{t('Primary')}</Badge>}
            {account.isPrimarySavings && <Badge tone="secondary">{t('Auto-Save')}</Badge>}
          </div>
          {/* The glyph now sits INSIDE the capsule, as `AccountTypeSelector(compact:)`
              does (§2.4.3) — Frontend added `Menu.icon` for this. */}
          <Menu
            options={options}
            value={account.accountType}
            onChange={onChangeType}
            ariaLabel={t('Account type')}
            variant="glass"
            icon={type?.icon ?? 'creditcard.fill'}
          />
        </div>

        <div className="ob-account-row__trailing">
          {expandable && (
            <button
              type="button"
              className="ob-icon-button"
              aria-expanded={expanded}
              aria-label={account.name}
              onClick={onToggleExpanded}
            >
              <span className={expanded ? 'ob-chevron ob-chevron--expanded' : 'ob-chevron'}>
                <Symbol name="chevron.down" size="var(--font-caption-size)" />
              </span>
            </button>
          )}
          {onDelete && (
            <button
              type="button"
              className="ob-icon-button"
              aria-label={t('Remove %@', [account.name])}
              onClick={onDelete}
            >
              <Symbol name="xmark.circle.fill" size="var(--icon-md)" />
            </button>
          )}
        </div>
      </div>

      {expandable && expanded && (
        <>
          <Divider inset />
          <div className="ob-account-row__expanded">
            {account.accountType === 'emergency' ? (
              <EmergencyDetail
                account={account}
                serverAccount={serverAccount}
                multiplierOptions={multiplierOptions}
                currencyCode={currencyCode}
                onChange={onChange}
                t={t}
              />
            ) : (
              <SavingsDetail
                account={account}
                onSetPrimarySavings={onSetPrimarySavings}
                t={t}
              />
            )}
          </div>
        </>
      )}
    </GlassCard>
  )
}

/* ================================================================== *
 * Emergency detail — multiplier picker, balance, progress
 * ================================================================== */

function EmergencyDetail({
  account,
  serverAccount,
  multiplierOptions,
  currencyCode,
  onChange,
  t,
}: {
  account: DraftAccount
  serverAccount: AccountExt | undefined
  multiplierOptions: readonly EmergencyMultiplierOption[] | null
  currencyCode: string
  onChange: (changes: AccountChanges) => void
  t: TFunction
}) {
  const progress = serverAccount?.emergencyProgress
  const progressDisplay = serverAccount?.emergencyProgressDisplay
  const complete = serverAccount?.isEmergencyComplete === true

  return (
    <>
      <div className="ob-stack-sm">
        <p className="ob-caption">{t('Target: months of income')}</p>
        <EmergencyMultiplierPicker
          account={account}
          serverAccount={serverAccount}
          multiplierOptions={multiplierOptions}
          currencyCode={currencyCode}
          onChange={onChange}
          t={t}
        />
      </div>

      <div className="ob-stack-sm">
        <p className="ob-caption">{t('Current balance')}</p>
        <div className="ob-boxed-input">
          <span className="ob-boxed-input__currency">{currencyCode}</span>
          <input
            className="ob-boxed-input__field"
            inputMode="decimal"
            placeholder="0"
            value={account.balanceText}
            aria-label={t('Current balance')}
            onChange={(event) =>
              onChange({
                balanceText: editingString(event.target.value),
                currentBalance: parseUserInput(event.target.value),
              })
            }
          />
        </div>
      </div>

      {progress !== undefined && progressDisplay !== undefined && (
        <div className="ob-stack-sm">
          <div className="ob-progress-row">
            <span>{t('Progress')}</span>
            <span
              className="ob-progress-row__value"
              style={{ color: complete ? 'var(--color-green)' : 'var(--color-orange)' }}
            >
              {/* R20: the LABEL is the server's truncated string… */}
              {progressDisplay}
            </span>
          </div>
          {/* …and the GEOMETRY is the full double. Two fields, two jobs. */}
          <ProgressBar
            progress={progress}
            variant="tint"
            color={complete ? 'var(--color-green)' : 'var(--color-orange)'}
            ariaValueText={progressDisplay}
            ariaLabel={t('Progress')}
          />
        </div>
      )}
    </>
  )
}

export interface EmergencyMultiplierPickerProps {
  account: DraftAccount
  serverAccount: AccountExt | undefined
  multiplierOptions: readonly EmergencyMultiplierOption[] | null
  currencyCode: string
  onChange: (changes: AccountChanges) => void
  t: TFunction
}

/**
 * §2.4.2. Four discrete options with per-option captions and the struck-through uncapped
 * target when the hard cap bites.
 *
 * Both R18 gaps are now closed by the server:
 *   - the options come from `reference.emergencyMultiplierOptions` (`3×`…`6×` with their
 *     captions) — `reference.savingsConstants.emergencyMultiplierRange: [3, 6]` never could
 *     have expressed four discrete stops. `EMERGENCY_MULTIPLIERS` remains only as the
 *     fallback for a server that predates the field;
 *   - the **target** comes from the preview's copy of this account, not from those
 *     reference rows: their `target` is resolved against the *stored* profile and reads
 *     `0 RON` mid-onboarding, whereas `serverAccount.emergencyTarget` /
 *     `emergencyTargetUncapped` / `isCapActive` follow the draft. Tapping 3×→6× therefore
 *     updates the figure live, with no client arithmetic anywhere.
 */
export function EmergencyMultiplierPicker({
  account,
  serverAccount,
  multiplierOptions,
  currencyCode,
  onChange,
  t,
}: EmergencyMultiplierPickerProps) {
  const multiplier = account.emergencyMultiplier
  /*
   * Three sources, most-resolved first:
   *  1. `serverAccount.multiplierOptions` — resolved against THIS account's income and cap;
   *  2. `reference.emergencyMultiplierOptions` — same labels/captions, targets resolved
   *     against the stored profile (so `0 RON` mid-onboarding — labels only);
   *  3. the local constant, for a server predating R18 item 3.
   * The target itself always comes from `serverAccount.emergencyTarget` below, so 1 and 2
   * differ only in whether their own `target` field is meaningful.
   */
  const options =
    serverAccount?.multiplierOptions ??
    multiplierOptions ??
    EMERGENCY_MULTIPLIERS.map((value) => ({
      multiplier: value,
      display: `${value}×`, // U+00D7, not the letter x.
      caption: EMERGENCY_MULTIPLIER_CAPTIONS[String(value)] ?? '',
    }))
  const caption =
    options.find((option) => option.multiplier === multiplier)?.caption ??
    (multiplier === undefined ? '' : (EMERGENCY_MULTIPLIER_CAPTIONS[String(multiplier)] ?? ''))
  const capEnabled = account.emergencyHardCap !== undefined
  const capActive = serverAccount?.isCapActive === true

  return (
    <div className="ob-stack-sm">
      <div className="ob-multipliers" role="group" aria-label={t('Target: months of income')}>
        {options.map((option) => (
          <button
            key={option.multiplier}
            type="button"
            className="ob-multiplier"
            aria-pressed={option.multiplier === multiplier}
            onClick={() => onChange({ emergencyMultiplier: option.multiplier })}
          >
            {option.display}
          </button>
        ))}
      </div>

      <div className="ob-target-row">
        <span>{t('Target:')}</span>
        {/* When the cap bites, the UNCAPPED target renders struck through beside the
            effective one (`EmergencyMultiplierPicker.swift:91-100`). */}
        {capActive && serverAccount?.emergencyTargetUncapped && (
          <span className="ob-target-row__struck" data-testid="ef-target-uncapped">
            {serverAccount.emergencyTargetUncapped.display}
          </span>
        )}
        {serverAccount?.emergencyTarget && (
          <span className="ob-target-row__value" data-testid="ef-target-effective">
            {serverAccount.emergencyTarget.display}
          </span>
        )}
        {caption !== '' && <span className="ob-target-row__description">{t(caption)}</span>}
      </div>

      <Toggle
        checked={capEnabled}
        label={t('Set maximum')}
        ariaLabel={t('Set maximum')}
        onChange={(checked) => {
          if (checked) {
            // Seeds from the server's calculated target — never recomputed locally.
            const seed = serverAccount?.emergencyTarget
            onChange(
              seed
                ? { emergencyHardCap: seed.amount, hardCapText: seed.editing }
                : { hardCapText: EMPTY_INPUT },
            )
          } else {
            onChange({ emergencyHardCap: undefined, hardCapText: EMPTY_INPUT })
          }
        }}
      />

      {capEnabled && (
        <div className="ob-row">
          <span className="ob-caption">{t('Max:')}</span>
          <div className="ob-boxed-input">
            <input
              className="ob-boxed-input__field"
              inputMode="decimal"
              placeholder="0"
              value={account.hardCapText}
              aria-label={t('Maximum amount')}
              onChange={(event) => {
                const parsed = parseUserInput(event.target.value)
                // On every keystroke: <= 0 clears the cap AND switches the toggle off.
                onChange({
                  hardCapText: editingString(event.target.value),
                  ...(isPositive(parsed)
                    ? { emergencyHardCap: parsed }
                    : { emergencyHardCap: undefined }),
                })
              }}
            />
            <span className="ob-boxed-input__currency">{currencyCode}</span>
          </div>
        </div>
      )}
    </div>
  )
}

/* ================================================================== *
 * Savings detail
 * ================================================================== */

function SavingsDetail({
  account,
  onSetPrimarySavings,
  t,
}: {
  account: DraftAccount
  onSetPrimarySavings: () => void
  t: TFunction
}) {
  if (account.isPrimarySavings) {
    return (
      <p className="ob-row">
        <Symbol name="checkmark.circle.fill" color="var(--color-green)" size="var(--icon-sm)" />
        <span className="ob-caption">{t('This account receives automatic savings')}</span>
      </p>
    )
  }
  return (
    <button type="button" className="ob-row ob-row--between" onClick={onSetPrimarySavings}>
      <span className="ob-row">
        <Symbol name="star.fill" color="var(--color-yellow)" size="var(--icon-sm)" />
        <span className="ob-field-label">{t('Set as Primary Savings')}</span>
      </span>
      <Symbol name="chevron.right" size="var(--font-caption-size)" />
    </button>
  )
}
