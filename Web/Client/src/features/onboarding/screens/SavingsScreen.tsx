/**
 * Savings — PARITY-SPEC §2.6.
 *
 * Order: header → allocation mode → allocation section → savings-flow info →
 * savings preview → Continue / Skip for now.
 *
 * Two things that catch people out and are handled explicitly here:
 *  - **Split defaults to Fixed Amount 0 on BOTH sides**, total 0. The 10 %/15 % are rates
 *    revealed only after a side is toggled to Percentage (§2.6 cross-check box).
 *  - **"Skip for now" does NOT zero savings** — it restores 25 % prioritized/percentage
 *    and still persists a savings row (R23).
 */

import type { AllocationModeValue, SavingsInputModeValue } from '../../../lib/api'
import { Symbol } from '../../../lib/icons'
import { editingString, parseUserInput } from '../../../lib/money'
import { GlassCard, PillButton, SegmentedControl, Slider, Toggle } from '../../../ui'
import { OnboardingHeader, OnboardingScreen, SectionTitle } from '../components/Chrome'
import { SavingsSlider } from '../components/SavingsSlider'
import {
  hasEmergencyAccount,
  hasIncome,
  hasPrimarySavingsAccount,
  isPositive,
  skipSavings,
  updateSavings,
} from '../draft'
import type { StepProps } from './shared'
import type { SavingsConstantsExt, SavingsSliderPosition } from '../types'

export function SavingsScreen({
  draft,
  update,
  preview,
  state,
  t,
  tDomain,
  advance,
  indicatorLabel,
}: StepProps) {
  const { savings } = draft
  const reference = state.reference
  const hasEmergency = hasEmergencyAccount(draft)
  const hasSavings = hasPrimarySavingsAccount(draft)

  const mode = reference.allocationModes.find((entry) => entry.value === savings.allocationMode)

  /*
   * ⚠️ Two different server fields, because `preview.savingsAmount` is **mode-blind**:
   * verified live, a split payload with both sides at fixed 0 still returns
   * `savingsAmount: "1,182 RON"` (the prioritized 25 % figure) while
   * `transferPlan.totalSavings` correctly returns `"0 RON"`. iOS shows
   * `calculateSavings` in prioritized mode and `min(splitTotal, availableIncome)` in split
   * mode (§2.6 step 5), so the split screen reads the plan's total. Reported to Backend;
   * this is a field choice, not a computation.
   */
  const savingsAmount =
    savings.allocationMode === 'split' ? preview?.transferPlan.totalSavings : preview?.savingsAmount

  /*
   * R13: the percent label has no local source. `savingsSliderPositions` is not served
   * yet, so the fallback is the SERVER's own `percentageDisplay` — valid precisely because
   * the slider is inert while the table is missing, so the draft rate cannot drift from
   * the stored one. The moment the table ships, `positions` wins and this is dead code.
   */
  const positions = preview?.savingsSliderPositions ?? null
  /*
   * ⚠️ `savingsConstants.presets` (5 values) is NOT the snap set. Backend confirmed it is
   * `SavingsAllocationEntry.presets`, dead code referenced by no view, while the slider
   * snaps to `snapValues` (7 values, `SavingsSlider.swift:119`). Using `presets` would feel
   * subtly wrong at 0.35 and 0.40 and never fail a test.
   */
  const savingsConstants = reference.savingsConstants as SavingsConstantsExt
  const storedSavings = state.settings.savings
  const percentDisplay =
    savings.percentage === storedSavings.percentage ? storedSavings.percentageDisplay : null

  /*
   * `canEnableBoost = percentage * boostMultiplier <= 1.0` (`SavingsSlider.swift:21-24`) —
   * a product the client must not compute. The server ships the resolved boolean as
   * `settings.savings.isBoostApplicable`, so it is read from there whenever the draft rate
   * matches the stored one (always, while the slider is inert under R13). If the rates ever
   * diverge the toggle stays enabled, which is the iOS behaviour at the default 25 %.
   */
  const canEnableBoost =
    savings.percentage === storedSavings.percentage ? storedSavings.isBoostApplicable : true

  const inputModeSegments = reference.savingsInputModes.map((entry) => ({
    value: entry.value,
    label: tDomain(entry.displayName),
    testId: entry.value === 'percentage' ? 'onb-mode-percentage' : 'onb-mode-fixed',
  }))

  return (
    <OnboardingScreen
      step="savings"
      indicatorLabel={indicatorLabel}
      footer={
        <>
          <PillButton fullWidth onClick={advance}>
            {t('Continue')}
          </PillButton>
          <PillButton
            variant="glass"
            fullWidth
            onClick={() => {
              update(skipSavings)
              advance()
            }}
          >
            {t('Skip for now')}
          </PillButton>
        </>
      }
    >
      <OnboardingHeader
        icon="banknote.fill"
        iconColor="var(--accent-secondary)"
        title={t('How much do you want to save?')}
        subtitle={t('Savings are calculated from your income after expenses.')}
      />

      {/* 2. Allocation strategy */}
      <section className="ob-section">
        <SectionTitle>{t('Allocation Strategy')}</SectionTitle>
        <SegmentedControl<AllocationModeValue>
          segments={reference.allocationModes.map((entry) => ({
            value: entry.value,
            label: tDomain(entry.displayName),
            testId: entry.value === 'split' ? 'onb-strategy-split' : 'onb-strategy-priority',
          }))}
          value={savings.allocationMode}
          onChange={(allocationMode) =>
            update((current) => updateSavings(current, { allocationMode }))
          }
          ariaLabel={t('Allocation Strategy')}
        />
        {mode && <p className="ob-caption">{tDomain(mode.description)}</p>}
      </section>

      {/* 3. Allocation section */}
      {savings.allocationMode === 'prioritized' ? (
        <section className="ob-section">
          <SectionTitle>{t('Monthly Savings')}</SectionTitle>
          <SegmentedControl<SavingsInputModeValue>
            segments={inputModeSegments}
            value={savings.savingsInputMode}
            onChange={(savingsInputMode) =>
              update((current) => updateSavings(current, { savingsInputMode }))
            }
            ariaLabel={t('Savings Type')}
          />

          {savings.savingsInputMode === 'percentage' ? (
            <>
              <SavingsSlider
                positions={positions}
                snapValues={savingsConstants.snapValues ?? []}
                snapThreshold={savingsConstants.snapThreshold ?? 0}
                percentage={savings.percentage}
                percentDisplay={percentDisplay}
                savingsDisplay={savingsAmount?.display ?? null}
                onChangePercentage={(percentage) =>
                  update((current) => updateSavings(current, { percentage }))
                }
                t={t}
              />
              <BoostCard
                enabled={savings.boostEnabled}
                canEnable={canEnableBoost}
                onToggle={(boostEnabled) =>
                  update((current) => updateSavings(current, { boostEnabled }))
                }
                t={t}
              />
            </>
          ) : (
            <div className="ob-currency-field">
              <span className="ob-boxed-input__currency">{draft.currencyCode}</span>
              <input
                className="ob-currency-field__input"
                inputMode="decimal"
                placeholder="0"
                value={savings.fixedAmountText}
                aria-label={t('Amount')}
                onChange={(event) =>
                  update((current) =>
                    updateSavings(current, {
                      fixedAmountText: editingString(event.target.value),
                      fixedAmount: parseUserInput(event.target.value),
                    }),
                  )
                }
              />
            </div>
          )}
        </section>
      ) : (
        <section className="ob-section">
          <SectionTitle>{t('Monthly Amounts')}</SectionTitle>

          {!hasEmergency && !hasSavings && (
            <p className="ob-footnote">
              {t('Add an emergency or savings account first to use split mode.')}
            </p>
          )}

          {hasEmergency && (
            <SplitBlock
              icon="shield.fill"
              label={t('Emergency Fund')}
              inputMode={savings.splitEmergencyInputMode}
              inputModeSegments={inputModeSegments}
              amountText={savings.splitEmergencyAmountText}
              /* R18 item 1 — every split figure is now served: the per-side rate label
                 (`percentDisplay`) and the resolved money (`resolvedAmount`, e.g. 473 RON
                 at 10 % of 4,730), already scaled down by `scaleRatio` when the requested
                 total exceeds available income. */
              percentDisplay={preview?.split?.emergency.percentDisplay ?? null}
              resolvedAmount={preview?.split?.emergency.resolvedAmount.display ?? null}
              percentage={savings.splitEmergencyPercentage}
              positions={preview?.splitSliderPositions ?? null}
              onChangePercentage={(splitEmergencyPercentage) =>
                update((current) => updateSavings(current, { splitEmergencyPercentage }))
              }
              currencyCode={draft.currencyCode}
              onChangeInputMode={(splitEmergencyInputMode) =>
                update((current) => updateSavings(current, { splitEmergencyInputMode }))
              }
              onChangeAmount={(text) =>
                update((current) =>
                  updateSavings(current, {
                    splitEmergencyAmountText: editingString(text),
                    splitEmergencyAmount: parseUserInput(text),
                  }),
                )
              }
              t={t}
            />
          )}

          {hasSavings && (
            <SplitBlock
              icon="banknote.fill"
              label={t('Savings')}
              inputMode={savings.splitSavingsInputMode}
              inputModeSegments={inputModeSegments}
              amountText={savings.splitSavingsAmountText}
              percentDisplay={preview?.split?.savings.percentDisplay ?? null}
              resolvedAmount={preview?.split?.savings.resolvedAmount.display ?? null}
              percentage={savings.splitSavingsPercentage}
              positions={preview?.splitSliderPositions ?? null}
              onChangePercentage={(splitSavingsPercentage) =>
                update((current) => updateSavings(current, { splitSavingsPercentage }))
              }
              currencyCode={draft.currencyCode}
              onChangeInputMode={(splitSavingsInputMode) =>
                update((current) => updateSavings(current, { splitSavingsInputMode }))
              }
              onChangeAmount={(text) =>
                update((current) =>
                  updateSavings(current, {
                    splitSavingsAmountText: editingString(text),
                    splitSavingsAmount: parseUserInput(text),
                  }),
                )
              }
              t={t}
            />
          )}
        </section>
      )}

      {/* 4. How your savings are distributed */}
      {(hasEmergency || hasSavings) && (
        <GlassCard radius="lg">
          <div className="ob-stack-sm">
            <p className="ob-flow__head">
              <span className="ob-flow__head-icon">
                <Symbol name="info.circle" size="var(--font-caption-size)" />
              </span>
              {t('How your savings are distributed')}
            </p>
            {flowItems(savings.allocationMode, hasEmergency, hasSavings, savings).map(
              (item, index) => (
                <p key={item.text} className="ob-flow__item">
                  <span className="ob-flow__number">{index + 1}</span>
                  <span className="ob-flow__icon">
                    <Symbol name={item.icon} size="var(--font-caption-size)" />
                  </span>
                  {t(item.text)}
                </p>
              ),
            )}
          </div>
        </GlassCard>
      )}

      {/* 5. This month's savings — shown only with an income and a non-zero amount */}
      {hasIncome(draft) && savingsAmount && isPositive(savingsAmount.amount) && (
        <div className="ob-preview-card">
          <p className="ob-preview-card__title">{t("This month's savings")}</p>
          <p className="ob-row">
            <span className="ob-preview-card__amount" data-testid="onb-savings-thismonth-value">
              {savingsAmount.display}
            </span>
            <span className="ob-impact__caption">{t('going to your accounts')}</span>
          </p>
        </div>
      )}
    </OnboardingScreen>
  )
}

/* ------------------------------------------------------------------ *
 * Flow items (§2.6 step 4)
 * ------------------------------------------------------------------ */

interface FlowItem {
  readonly icon: string
  readonly text: string
}

function flowItems(
  allocationMode: AllocationModeValue,
  hasEmergency: boolean,
  hasSavings: boolean,
  savings: { splitEmergencyInputMode: SavingsInputModeValue; splitSavingsInputMode: SavingsInputModeValue },
): readonly FlowItem[] {
  const items: FlowItem[] = []
  if (allocationMode === 'prioritized') {
    if (hasEmergency) {
      items.push({ icon: 'shield.fill', text: 'Emergency fund fills first until target reached' })
    }
    if (hasSavings) {
      items.push({ icon: 'banknote.fill', text: 'Remaining savings go to your savings account' })
    }
    return items
  }
  if (hasEmergency) {
    items.push({
      icon: 'shield.fill',
      text:
        savings.splitEmergencyInputMode === 'percentage'
          ? 'Percentage of income to emergency each month'
          : 'Fixed amount to emergency each month',
    })
  }
  if (hasSavings) {
    items.push({
      icon: 'banknote.fill',
      text:
        savings.splitSavingsInputMode === 'percentage'
          ? 'Percentage of income to savings each month'
          : 'Fixed amount to savings each month',
    })
  }
  return items
}

/* ------------------------------------------------------------------ *
 * Boost card (§2.6.2)
 * ------------------------------------------------------------------ */

function BoostCard({
  enabled,
  canEnable,
  onToggle,
  t,
}: {
  enabled: boolean
  canEnable: boolean
  onToggle: (enabled: boolean) => void
  t: StepProps['t']
}) {
  return (
    <GlassCard radius="lg">
      <div className="ob-stack-sm">
        <div className="ob-row ob-row--between">
          <span className="ob-boost__label">
            <span className={enabled ? 'ob-boost__icon ob-boost__icon--on' : 'ob-boost__icon'}>
              <Symbol name="bolt.fill" size="var(--icon-sm)" />
            </span>
            <span>
              <span className="ob-boost__title">{t('Savings Boost')}</span>
              <br />
              <span
                className={
                  canEnable
                    ? 'ob-boost__description'
                    : 'ob-boost__description ob-boost__description--warning'
                }
              >
                {canEnable
                  ? t('Triple your savings temporarily')
                  : t('Lower your savings rate to enable boost')}
              </span>
            </span>
          </span>
          <Toggle
            checked={enabled}
            disabled={!canEnable && !enabled}
            ariaLabel={t('Savings Boost')}
            testId="onb-savings-boost-switch"
            onChange={onToggle}
          />
        </div>

        {enabled && (
          <p className="ob-boost__warning">
            <span className="ob-boost__warning-icon">
              <Symbol name="exclamationmark.triangle" size="var(--font-caption-size)" />
            </span>
            {t('Boost is great for catching up, but not sustainable long-term')}
          </p>
        )}
      </div>
    </GlassCard>
  )
}

/* ------------------------------------------------------------------ *
 * Split per-side block (§2.6 B)
 * ------------------------------------------------------------------ */

function SplitBlock({
  icon,
  label,
  inputMode,
  inputModeSegments,
  amountText,
  percentDisplay,
  resolvedAmount,
  percentage,
  positions,
  onChangePercentage,
  currencyCode,
  onChangeInputMode,
  onChangeAmount,
  t,
}: {
  icon: string
  label: string
  inputMode: SavingsInputModeValue
  inputModeSegments: readonly { value: SavingsInputModeValue; label: string }[]
  amountText: string
  percentDisplay: string | null
  resolvedAmount: string | null
  percentage: number
  positions: readonly SavingsSliderPosition[] | null
  onChangePercentage: (percentage: number) => void
  currencyCode: string
  onChangeInputMode: (mode: SavingsInputModeValue) => void
  onChangeAmount: (text: string) => void
  t: StepProps['t']
}) {
  const index = positions?.findIndex((position) => position.percentage === percentage) ?? -1
  return (
    <div className="ob-split-block">
      <p className="ob-split-block__label">
        <Symbol name={icon} size="var(--icon-sm)" />
        {label}
      </p>
      <SegmentedControl<SavingsInputModeValue>
        segments={inputModeSegments}
        value={inputMode}
        onChange={onChangeInputMode}
        ariaLabel={label}
      />
      {inputMode === 'percentage' ? (
        <>
          <div className="ob-split-rate">
            {/* `Int(pct*100)%` and the resolved money, both server-formatted (§2.6 B). */}
            <span className="ob-split-rate__value">{percentDisplay ?? ''}</span>
            {resolvedAmount && <span className="ob-split-rate__amount">{resolvedAmount}</span>}
          </div>
          {positions && (
            <Slider
              value={index >= 0 ? index : 0}
              min={0}
              max={positions.length - 1}
              step={1}
              variant="accent"
              onChange={(nextIndex) => {
                const next = positions[nextIndex]
                if (next) onChangePercentage(next.percentage)
              }}
              ariaLabel={label}
              ariaValueText={percentDisplay ?? ''}
            />
          )}
        </>
      ) : (
        <div className="ob-currency-field">
          <span className="ob-boxed-input__currency">{currencyCode}</span>
          <input
            className="ob-currency-field__input"
            inputMode="decimal"
            placeholder="0"
            value={amountText}
            aria-label={t('Amount')}
            onChange={(event) => onChangeAmount(event.target.value)}
          />
        </div>
      )}
    </div>
  )
}
