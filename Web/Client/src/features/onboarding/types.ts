/**
 * Onboarding-local types.
 *
 * Two kinds of thing live here:
 *  1. The **draft** — the client-owned mirror of `OnboardingViewModel`. Onboarding is the
 *     one flow where nothing is persisted until the last screen, so the draft is genuinely
 *     client state. It holds NO derived money: every amount shown on screen comes back
 *     from `POST /api/onboarding/preview` (DECISIONS.md R2).
 *  2. **Pending API shapes** — fields `main`/`Backend` have announced but not yet shipped
 *     (R13 `savingsSliderPositions`, R18 `emergencyMultiplierOptions`). They are typed as
 *     OPTIONAL extensions of the published response types, so the screens can be built
 *     against the real shape and light up the moment the server serves them. Nothing here
 *     fabricates a value the server would otherwise own.
 */

import type {
  Account,
  AccountTypeValue,
  AllocationModeValue,
  MoneyValue,
  OnboardingPreview,
  Reference,
  RemainingMoneyDestinationValue,
  SavingsInputModeValue,
  SFSymbol,
  Uuid,
} from '../../lib/api'
import type { EditingString, Money } from '../../lib/money'

/* ================================================================== *
 * Draft — mirrors OnboardingViewModel (PARITY-SPEC §2.0, §2.8)
 * ================================================================== */

/** Mirrors `Domain.AccountEntry` as onboarding holds it, before any save. */
export interface DraftAccount {
  readonly id: Uuid
  readonly name: string
  readonly accountType: AccountTypeValue
  readonly isPrimary: boolean
  readonly isPrimarySavings: boolean
  /** Emergency only. `AccountsScreen.addAccount` sets 3.0 (PARITY-SPEC §2.4). */
  readonly emergencyMultiplier?: number
  readonly emergencyHardCap?: Money
  readonly currentBalance: Money
  /**
   * Raw text of the balance field, so a half-typed "12." survives a re-render.
   *
   * `EditingString`, not `string` (DECISIONS.md **R24**): every one of these `*Text`
   * fields feeds an amount input, and seeding one from a `MoneyValue.display`
   * (`"9,000 RON"`) parses to **9** — a 1000× silent loss. Branding them makes that a
   * compile error at the draft boundary, which is where the mistake would be made.
   */
  readonly balanceText: EditingString
  /** Raw text of the hard-cap field. */
  readonly hardCapText: EditingString
}

/**
 * Changes applied to a draft account.
 *
 * `Partial<DraftAccount>` is not usable here: under `exactOptionalPropertyTypes` it
 * forbids passing an explicit `undefined`, and clearing the emergency multiplier / hard
 * cap is a real operation (`handleTypeChange` and the "Set maximum" toggle both do it).
 * So the value union carries `undefined` deliberately, and `updateAccount` deletes those
 * keys rather than storing them.
 */
export type AccountChanges = { [K in keyof DraftAccount]?: DraftAccount[K] | undefined }

/** Mirrors the four seeded `ExpenseInput` rows. */
export interface DraftExpense {
  readonly id: Uuid
  /**
   * Stable English slug (`food`, `rent`, `gas`, `streaming`) for the Reviewer's testid
   * contract. Derived from the seed key, never from `name` — the name is localized at
   * seed time, so a slug taken from it would become `mancare` in Romanian and the parity
   * suite would fail on a screen that is completely correct.
   */
  readonly slug: string
  readonly name: string
  readonly icon: SFSymbol
  readonly amount: Money
  readonly amountText: EditingString
  readonly categoryId?: Uuid
  /** `undefined` MEANS the primary account — the iOS convention (`"Main"` in the menu). */
  readonly linkedAccountId?: Uuid
}

/** Same reasoning as `AccountChanges`: clearing `linkedAccountId` means "pay from Main". */
export type ExpenseChanges = { [K in keyof DraftExpense]?: DraftExpense[K] | undefined }

/** Mirrors `Domain.SavingsAllocationEntry`. Defaults per DOMAIN-CONTRACT §2. */
export interface DraftSavings {
  readonly allocationMode: AllocationModeValue
  readonly savingsInputMode: SavingsInputModeValue
  readonly percentage: number
  readonly fixedAmount: Money
  readonly fixedAmountText: EditingString
  readonly boostEnabled: boolean
  readonly boostMultiplier: number
  /** ⚠️ BOTH split sides default to `fixedAmount` at 0 — NOT to the 10%/15% rates.
   *  A client defaulting to percentage shows 473/710 RON where iOS shows nothing
   *  (GROUND-TRUTH "Split allocation mode", PARITY-SPEC §2.6 cross-check box). */
  readonly splitEmergencyInputMode: SavingsInputModeValue
  readonly splitEmergencyAmount: Money
  readonly splitEmergencyAmountText: EditingString
  readonly splitEmergencyPercentage: number
  readonly splitSavingsInputMode: SavingsInputModeValue
  readonly splitSavingsAmount: Money
  readonly splitSavingsAmountText: EditingString
  readonly splitSavingsPercentage: number
}

export interface OnboardingDraft {
  readonly name: string
  readonly currencyCode: string
  readonly monthlyIncome: Money
  readonly incomeText: EditingString
  readonly accounts: readonly DraftAccount[]
  readonly expenses: readonly DraftExpense[]
  readonly savings: DraftSavings
  readonly remainingMoneyDestination: RemainingMoneyDestinationValue
}

/* ================================================================== *
 * Pending server fields — R13 / R18
 * ================================================================== */

/**
 * DECISIONS.md **R13**. One row per selectable slider position, so dragging is an array
 * index lookup and the client never computes `Int(pct*100)` or `pct × availableIncome`.
 *
 * ✅ **Served since 2026-08-06** on `POST /api/onboarding/preview` — 46 rows covering
 * 0.05…0.50 at the `savingsConstants.step` of 0.01. Every visible string on the savings
 * screen is read out of the selected row; nothing is derived from `percentage`.
 */
export interface SavingsSliderPosition {
  readonly percentage: number
  /** `Int(percentage * 100)`, truncated server-side. */
  readonly percent: number
  /** Pre-truncated display, e.g. `"25%"`. */
  readonly percentDisplay: string
  readonly savings: MoneyValue
  readonly isRecommended: boolean
  readonly isSnapValue: boolean
  /** `0.20 <= percentage <= 0.30` decided server-side — the "Great savings rate!" badge. */
  readonly showsGreatRateBadge: boolean
}

/**
 * DECISIONS.md **R18 item 3**, served on `reference.emergencyMultiplierOptions`.
 *
 * ⚠️ `target` / `targetUncapped` on these REFERENCE rows are resolved against the *stored*
 * profile, which during onboarding is not the draft — they read `0 RON` on a fresh store.
 * So the picker uses this list for the options, labels and captions, and takes the target
 * from the **preview's own copy of the account** (`emergencyTarget`,
 * `emergencyTargetUncapped`, `isCapActive`), which is draft-aware.
 */
export interface EmergencyMultiplierOption {
  readonly multiplier: number
  /** `"3×"` — U+00D7, not the letter x. */
  readonly display: string
  /** "Minimum recommended" / "Standard protection" / … */
  readonly caption: string
  readonly target: MoneyValue
  readonly targetUncapped: MoneyValue
  readonly isCapActive: boolean
  readonly isSelected: boolean
}

/** One side of split mode, fully resolved server-side (R18 item 1). */
export interface SplitSide {
  readonly inputMode: SavingsInputModeValue
  readonly percentage: number
  readonly percent: number
  readonly percentDisplay: string
  readonly fixedAmount: MoneyValue
  /** What this side actually contributes at the current input mode. */
  readonly resolvedAmount: MoneyValue
}

export interface SplitPreview {
  readonly emergency: SplitSide
  readonly savings: SplitSide
  readonly requestedTotal: MoneyValue
  /** `TransferCalculator.swift:161-163` scales both sides down when over budget. */
  readonly scaleRatio: string
  readonly wasScaledDown: boolean
  readonly actualEmergencyAllocation: MoneyValue
  readonly actualSavingsAllocation: MoneyValue
}

/**
 * The published preview response plus the fields the server sends that `api.ts` has not
 * typed yet.
 *
 * Written as an **intersection, not an `extends`** on purpose: when Frontend adds these to
 * `api.ts` as required properties, an intersection quietly resolves to the required form,
 * whereas an interface extension would fail to compile (as `expenseNames` did).
 */
export type OnboardingPreviewExt = OnboardingPreview & {
  readonly savingsSliderPositions?: readonly SavingsSliderPosition[]
  /** Same table at the same step, for split mode's two per-side sliders. */
  readonly splitSliderPositions?: readonly SavingsSliderPosition[]
  readonly split?: SplitPreview
  /** `Int(min(1, pct * boostMultiplier) * 100)%` — R18's `boostedPercentDisplay`. */
  readonly boostedPercentDisplay?: string
}

/**
 * `savingsConstants` plus the slider fields Backend added for R13.
 *
 * `snapValues`/`snapThreshold` drive the drag snap; `step` is the table granularity.
 * `presets` is deliberately NOT used — see the note in `SavingsScreen`.
 */
export type SavingsConstantsExt = Reference['savingsConstants'] & {
  readonly step?: number
  readonly snapThreshold?: number
  readonly snapValues?: readonly number[]
  readonly accessibilityStep?: number
  readonly greatRateRange?: readonly [number, number]
}

/** `reference` plus the same not-yet-typed additions. */
export type ReferenceExt = Reference & {
  readonly emergencyMultiplierOptions?: readonly EmergencyMultiplierOption[]
}

/**
 * `Account` plus R18 item 2's cap fields and the per-account multiplier options.
 *
 * Backend serves the options in two places: on `reference` (resolved against the *stored*
 * profile — `0 RON` targets mid-onboarding) and on each account (resolved against that
 * account's own income and cap). The per-account copy is the one to prefer.
 */
export type AccountExt = Account & {
  readonly emergencyTargetUncapped?: MoneyValue
  readonly isCapActive?: boolean
  readonly multiplierOptions?: readonly EmergencyMultiplierOption[]
}

/*
 * `AccountExpenseTransferExt` removed by Frontend: `expenseNames` is now on
 * `AccountExpenseTransfer` in `api.ts` as a REQUIRED `readonly string[]`, so the widening
 * is redundant. It had to go rather than merely be ignored — an interface cannot make an
 * inherited required property optional, so it no longer compiled. Import
 * `AccountExpenseTransfer` from `../../lib/api` directly.
 */
