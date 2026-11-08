/**
 * Typed client for the Vapor server — `Web/Docs/API-CONTRACT.md` **v1.1**.
 *
 * Base is `/api`: in dev, Vite proxies it to http://127.0.0.1:8080 (vite.config.ts);
 * in prod the server serves this SPA itself, so it is same-origin either way and there
 * is no CORS (API-CONTRACT §0, DECISIONS.md D4).
 *
 * Five contract rules encoded here:
 *  1. §0.1 — money in **responses** is `MoneyValue`; render `.display` verbatim, never
 *     re-format. Money in **requests** is a plain JSON *string*; a number gets a 400.
 *  2. §0.2 — **every mutating endpoint returns the entire `AppState`**. Replace the whole
 *     client store with the response; never patch it.
 *  3. §2.7 — enum tables come from `state.reference`. Never hardcode enum lists in TS.
 *  4. **Null fields are OMITTED, not sent as `null`** (v1.1). Swift's `Codable` uses
 *     `encodeIfPresent`, so `"profile": null` never appears — the key is simply absent.
 *     Every such field is typed `field?: T`, NOT `field: T | null`, and the difference is
 *     load-bearing: `state.profile === null` is **always false** and would silently treat
 *     a fresh install as onboarded. Test with `if (!state.profile)` or `?? null`.
 *     (Request payloads are the opposite — there an explicit `null` clears a value, so
 *     those fields stay `T | null` deliberately.)
 *  5. §0.1 — **`MoneyValue.editing` is display-only** and uses the HOST LOCALE's decimal
 *     separator: `1182.5` comes back as `"1182,5"` on this machine. Never parse it, never
 *     send it back. On submit, return the canonical `amount` you were given, or round-trip
 *     typed text through `parseUserInput` / `POST /api/parse-amount`.
 */

import type { DisplayString, EditingString, Money } from './money'

export const API_BASE = '/api'

/* ================================================================== *
 * Errors — Vapor's shape (§4)
 * ================================================================== */

export interface ApiErrorBody {
  readonly error: true
  readonly reason: string
}

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly path: string,
    /** Server-supplied `reason`, or the raw body when it was not the Vapor shape. */
    readonly reason: string,
  ) {
    super(`${status} on ${path}: ${reason}`)
    this.name = 'ApiError'
  }

  /** `409` — a rule violation the UI is expected to surface (§4). */
  get isConflict(): boolean {
    return this.status === 409
  }
}

/* ================================================================== *
 * §0.1 Money
 * ================================================================== */

/**
 * A monetary value as the server sends it.
 *
 * - `display` — ready to render, currency appended, `","` grouping forced. **Render this.**
 * - `editing` — seeds a prefilled input; `""` when the amount is <= 0 (iOS behaviour).
 *   ⚠️ **Display-only, and locale-formatted.** `formatForEditing` forces the grouping
 *   separator to `""` but leaves the DECIMAL separator to `Locale.current`, so `1182.5`
 *   arrives as `"1182,5"` here. That matches iOS, which shows `1182,5` in the New Month
 *   fields. Never `parseFloat` it and never send it back as an amount.
 * - `amount` — the exact canonical decimal (`.` separator, no grouping). **This is what
 *   you send back** in a request payload. You should never need to compute with it.
 */
export interface MoneyValue {
  readonly amount: Money
  readonly display: DisplayString
  readonly editing: EditingString
  /**
   * Computed from the `Decimal` itself (v1.4). **The only correct zero test.**
   * Both naive alternatives are wrong in opposite directions:
   *   `display === "0 RON"` → also true for `0.4`, which is NOT zero.
   *   `-0.004` → `display` is `"-0 RON"`, so a real negative reads as a zero string.
   * And `parseFloat(amount) === 0` would be client-side numeric logic (R2).
   */
  readonly isZero: boolean
}

/** Money in a request body is a bare decimal string. */
export type MoneyRequest = Money

export type Uuid = string
/** ISO-8601, e.g. `"2026-08-06T13:22:41Z"`. */
export type IsoDate = string

/** SF Symbol name — map to Lucide with `Symbol` / `iconFor` from `./icons`. */
export type SFSymbol = string

/* ================================================================== *
 * §2.7 Enum value types
 * ================================================================== */

export type AccountTypeValue =
  | 'primary'
  | 'emergency'
  | 'savings'
  | 'personal'
  | 'joint'
  | 'other'
export type FrequencyValue = 'monthly' | 'annual'
export type AllocationModeValue = 'prioritized' | 'split'
export type SavingsInputModeValue = 'percentage' | 'fixedAmount'
export type RemainingMoneyDestinationValue = 'primarySavings' | 'primary' | 'personal'

/* ================================================================== *
 * §2.1–2.3 Entities
 * ================================================================== */

export interface Account {
  readonly id: Uuid
  readonly name: string
  readonly purpose?: string
  readonly accountType: AccountTypeValue
  readonly accountTypeDisplayName: string
  readonly accountTypeDescription: string
  readonly icon: SFSymbol
  readonly isPrimary: boolean
  readonly isPrimarySavings: boolean
  readonly emergencyMultiplier?: number
  readonly emergencyHardCap?: MoneyValue
  readonly currentBalance: MoneyValue
  readonly sortOrder: number
  /** null for non-emergency accounts, and when no multiplier is set. */
  readonly emergencyTarget?: MoneyValue
  readonly emergencyProgress?: number
  /** `Int(progress * 100)` — truncated, matching iOS. Do not re-derive. */
  readonly emergencyProgressPercent?: number
  readonly emergencyProgressDisplay?: string
  readonly isEmergencyComplete: boolean
  /**
   * New Month step 2 lists only reconcilable accounts (R14). ⚠️ Do NOT hardcode the
   * `emergency|savings|personal` rule client-side — a `personal` account IS reconcilable
   * and was simply absent from the walkthrough data that made it look like two types.
   */
  readonly isReconcilable: boolean
  /**
   * "was 1,182 RON last month". ⚠️ Misleading but faithful: it formats the account's
   * CURRENT balance, the same value that prefills the field above it, so on first open the
   * caption and the input always agree.
   */
  readonly wasLastMonthDisplay: string
  /**
   * ⚠️ For the Settings account-editor balance field ONLY. That field uses
   * `TextField(format: .number)`, **not** `AmountFormatter` — so it follows the DEVICE
   * locale, applies grouping (`"1,182.5"`) and shows `"0"` rather than blank.
   * `Money.editing` is wrong there and right everywhere else.
   */
  readonly balanceEditorValue: string
  /**
   * ⚠️ v1.2 BREAKING: replaces the flat `subtitle` string, which is gone entirely.
   *
   * iOS renders an `HStack(spacing: Spacing.xs)` — an **8px gap** — of 2–3 independently
   * coloured `Text` views, so there never was one string to render. The bullet belongs to
   * the part, which is why splitting on "•" was always the wrong fix.
   *   Main Account   -> [{ "Primary", secondary }]
   *   Emergency Fund -> [{ "Emergency", secondary }, { "• 3× income", accentSecondary }]
   *   Savings        -> [{ "Savings", secondary }, { "• Primary", accentPrimary }]
   * With a hard cap the third part reads "• 3× income (max 30,000 RON)". The multiplier
   * badge is gated on `emergencyMultiplier != nil`, NOT on the account type, so a
   * non-emergency account carrying a stray multiplier still shows it — as iOS does.
   */
  readonly subtitleParts: readonly AccountSubtitlePart[]
}

/** One coloured run of a Settings account-row subtitle (v1.2). */
export interface AccountSubtitlePart {
  readonly text: string
  readonly tone: 'secondary' | 'accentPrimary' | 'accentSecondary'
}

export interface Category {
  readonly id: Uuid
  /** Raw English from Domain — NOT localized server-side. Translate via i18n `domain` ns. */
  readonly name: string
  readonly icon: SFSymbol
  readonly colorHex: string
  readonly isDefault: boolean
  readonly sortOrder: number
}

export interface Expense {
  readonly id: Uuid
  readonly name: string
  readonly amount: MoneyValue
  readonly frequency: FrequencyValue
  readonly frequencyDisplayName: string
  readonly frequencyIcon: SFSymbol
  readonly monthlyAmount: MoneyValue
  readonly annualAmount: MoneyValue
  readonly icon: SFSymbol
  readonly categoryId?: Uuid
  readonly category?: Category
  /** `null` MEANS THE PRIMARY ACCOUNT (iOS convention). Use `linkedAccountName`. */
  readonly linkedAccountId?: Uuid
  readonly linkedAccountName: string
  readonly isEnabled: boolean
  readonly notes?: string
  readonly sortOrder: number
}

/* ================================================================== *
 * §1 Profile + settings
 * ================================================================== */

export interface Profile {
  readonly name: string
  readonly currencyCode: string
  readonly currencyDisplayName: string
  readonly remainingMoneyDestination: RemainingMoneyDestinationValue
  readonly remainingMoneyDestinationDisplayName: string
  readonly createdAt: IsoDate
}

/** R13: one row per selectable slider position. Dragging is an INDEX LOOKUP, never maths. */
export interface SavingsSliderPosition {
  readonly percentage: number
  readonly percent: number
  readonly percentDisplay: string
  readonly savings: MoneyValue
  readonly isRecommended: boolean
  readonly isSnapValue: boolean
  /** The "Great savings rate!" badge band (20–30%). */
  readonly showsGreatRateBadge: boolean
}

/** One side of Split mode (R18.1). */
export interface SplitSide {
  readonly inputMode: SavingsInputModeValue
  readonly fixedAmount: MoneyValue
  readonly percentage: number
  readonly percent: number
  readonly percentDisplay: string
  /**
   * ⚠️ Resolved against **`availableIncome`, not gross income** — 10% of 4,730 is 473,
   * not 900. And each side rounds half-even INDEPENDENTLY, so 473 + 710 displays as 1,183
   * beside a total of 1,182. Reproduce that; do not reconcile it.
   */
  readonly resolvedAmount: MoneyValue
}

export interface SplitSettings {
  readonly emergency: SplitSide
  readonly savings: SplitSide
  readonly requestedTotal: MoneyValue
  readonly scaleRatio: string
  /** Drives the split-ONLY "Total exceeds available income" footer. */
  readonly wasScaledDown: boolean
  readonly actualEmergencyAllocation: MoneyValue
  readonly actualSavingsAllocation: MoneyValue
}

export interface SavingsSettings {
  readonly savingsSliderPositions: readonly SavingsSliderPosition[]
  readonly splitSliderPositions: readonly SavingsSliderPosition[]
  readonly split: SplitSettings
  /** Always present; render the row only when `boostEnabled`. */
  readonly boostedPercentDisplay: string
  readonly percentage: number
  readonly percentageDisplay: string
  readonly effectivePercentage: number
  readonly effectivePercentageDisplay: string
  readonly boostEnabled: boolean
  readonly boostMultiplier: number
  readonly isBoostApplicable: boolean
  readonly allocationMode: AllocationModeValue
  readonly allocationModeDisplayName: string
  readonly allocationModeDescription: string
  readonly savingsInputMode: SavingsInputModeValue
  readonly fixedAmount: MoneyValue
  readonly splitEmergencyInputMode: SavingsInputModeValue
  readonly splitEmergencyAmount: MoneyValue
  readonly splitEmergencyPercentage: number
  readonly splitSavingsInputMode: SavingsInputModeValue
  readonly splitSavingsAmount: MoneyValue
  readonly splitSavingsPercentage: number
  readonly isValid: boolean
}

export interface Settings {
  readonly income: MoneyValue
  readonly savings: SavingsSettings
}

/* ================================================================== *
 * §2.4 dashboard
 * ================================================================== */

export interface DashboardSummary {
  readonly income: MoneyValue
  readonly expenses: MoneyValue
  readonly savings: MoneyValue
  readonly personalSpending: MoneyValue
}

export interface EmergencyFundSummary {
  readonly accountId: Uuid
  readonly accountName: string
  readonly balance: MoneyValue
  readonly target: MoneyValue
  readonly progress: number
  /** Truncated int, pre-computed (R2). */
  readonly progressPercent: number
  readonly progressDisplay: string
  readonly multiplier: number
  readonly targetCaption: string
  readonly isComplete: boolean
}

export interface ExpenseBreakdownRow {
  readonly id: Uuid
  readonly name: string
  readonly icon: SFSymbol
  readonly amount: MoneyValue
  /** `Int((amount / total) * 100)` — TRUNCATED server-side. Render, never re-derive. */
  readonly percent: number
  readonly percentDisplay: string
}

export interface DashboardState {
  readonly currentMonthDisplay: string
  readonly summary: DashboardSummary
  readonly emergencyFund?: EmergencyFundSummary
  readonly primaryAccount?: Account
  readonly otherAccounts: readonly Account[]
  /** Enabled expenses with monthlyAmount > 0, amount-descending, capped at 5. */
  readonly expenseBreakdown: readonly ExpenseBreakdownRow[]
}

/* ================================================================== *
 * §2.5 expensesScreen
 * ================================================================== */

export interface ExpenseCategoryGroup {
  /**
   * Stable group key (v1.5): the `categoryId`, a dangling category's id, or the
   * uncategorized sentinel `00000000-0000-0000-0000-000000000000`. **Use this as the React
   * key.** Keying on `category?.id ?? SENTINEL` collapses every dangling-category group
   * into one row — two expenses pointing at two different deleted categories must produce
   * two groups.
   */
  readonly id: Uuid
  /**
   * Server-resolved display name (v1.5) — `category?.name` or `"Uncategorized"`. Render
   * this rather than inventing the fallback string client-side, so the EN/RO wording has
   * exactly one source.
   */
  readonly name: string
  /**
   * OMITTED (not `null`) for the two group kinds that have no category (PARITY-SPEC §5.2):
   * a dangling `categoryId`, and the uncategorized bucket. Render the grey
   * `questionmark.circle.fill` fallback when it is missing.
   */
  readonly category?: Category
  readonly enabledCount: number
  readonly totalCount: number
  /** e.g. "1/1 enabled" — pre-assembled server-side. */
  readonly enabledCaption: string
  readonly monthlyTotal: MoneyValue
  readonly annualTotal: MoneyValue
  readonly expenses: readonly Expense[]
}

export interface ExpensesScreenState {
  readonly totalMonthly: MoneyValue
  readonly totalAnnual: MoneyValue
  readonly categories: readonly ExpenseCategoryGroup[]
}

/* ================================================================== *
 * §2.6 transferPlan
 * ================================================================== */

export interface AccountAllocation {
  /** ⚠️ There is NO `id` — iOS mints a fresh UUID per recompute. Key on `accountId`. */
  readonly accountId: Uuid
  readonly accountName: string
  readonly accountType: AccountTypeValue
  readonly icon: SFSymbol
  readonly amount: MoneyValue
  readonly progressBefore?: number
  readonly progressAfter?: number
  readonly progressBeforePercent?: number
  readonly progressAfterPercent?: number
  /** e.g. "0% → 4%" (literal U+2192). Omitted unless both progresses are set. */
  readonly progressChangeDisplay?: string
  /**
   * DECISIONS.md **R30** — the New Month row subtitle, composed server-side because the
   * two screens word completion DIFFERENTLY: New Month *replaces* the progress line with
   * "Completes fund to 100%!" and additionally requires `accountType == emergency`, while
   * onboarding *appends* a "Target reached!" row for any account type. A uniform
   * client-side "if isComplete, show the completion string" is wrong on one of them.
   */
  readonly newMonthNote?: string
  /** Colour hint for `progressChangeDisplay` / `newMonthNote`. */
  readonly progressChangeTone?: string
  readonly targetAmount?: MoneyValue
  readonly currentBalance: MoneyValue
  readonly isComplete: boolean
}

export interface AccountExpenseTransfer {
  readonly accountId: Uuid
  readonly accountName: string
  readonly icon: SFSymbol
  readonly amount: MoneyValue
  /**
   * The expenses funded by this transfer, for the `"for Food, Rent"` caption
   * (PARITY-SPEC §2.7 `ExpenseTransferCard`). Verified on the live server by Frontend2.
   */
  readonly expenseNames: readonly string[]
}

export interface TransferPlan {
  readonly income: MoneyValue
  readonly totalExpenses: MoneyValue
  readonly availableIncome: MoneyValue
  readonly totalSavings: MoneyValue
  /** Domain's priority order (emergency first, then savings). Do NOT reorder. */
  readonly accountAllocations: readonly AccountAllocation[]
  readonly remainsInPrimary: MoneyValue
  /** Sorted by accountName ascending, server-side (§2.6). */
  readonly accountExpenseTransfers: readonly AccountExpenseTransfer[]
  readonly remainingMoney: MoneyValue
  readonly remainingDestination: RemainingMoneyDestinationValue
  readonly remainingDestinationDisplayName: string
  /** `abs(total - income) < 0.01` on Swift Decimal — pre-computed (R2). */
  readonly isBalanced: boolean
  readonly hasAccountAllocations: boolean
  readonly totalAccountAllocations: MoneyValue
  /**
   * ⚠️ Groups with the HOST LOCALE separator (`"Income: 9.000 | …"`) because Domain's
   * `summary` does not force `","` the way `formatForDisplay` does. No iOS view renders
   * it — use the individual `MoneyValue.display` fields instead.
   */
  readonly summary: string
}

/* ================================================================== *
 * §2.7 reference — enum tables for every picker
 * ================================================================== */

export interface AccountTypeRef {
  readonly value: AccountTypeValue
  readonly displayName: string
  readonly description: string
  readonly icon: SFSymbol
  readonly hasBehavior: boolean
  readonly isUnique: boolean
}

export interface FrequencyRef {
  readonly value: FrequencyValue
  readonly displayName: string
  readonly icon: SFSymbol
}

export interface AllocationModeRef {
  readonly value: AllocationModeValue
  readonly displayName: string
  readonly description: string
}

export interface SavingsInputModeRef {
  readonly value: SavingsInputModeValue
  readonly displayName: string
}

export interface RemainingMoneyDestinationRef {
  readonly value: RemainingMoneyDestinationValue
  /** ⚠️ `primary` is Domain's "Keep in Primary"; SettingsSheet relabels it (§2.7). */
  readonly displayName: string
  readonly description: string
  readonly icon: SFSymbol
}

export interface CurrencyRef {
  readonly value: string
  readonly symbol: string
  readonly displayName: string
}

export interface SavingsConstants {
  readonly minimumPercentage: number
  readonly maximumPercentage: number
  readonly recommendedPercentage: number
  readonly presets: readonly number[]
  readonly defaultBoostMultiplier: number
  readonly defaultEmergencyMultiplier: number
  readonly emergencyMultiplierRange: readonly [number, number]
}

export interface Reference {
  readonly accountTypes: readonly AccountTypeRef[]
  readonly frequencies: readonly FrequencyRef[]
  readonly allocationModes: readonly AllocationModeRef[]
  readonly savingsInputModes: readonly SavingsInputModeRef[]
  readonly remainingMoneyDestinations: readonly RemainingMoneyDestinationRef[]
  readonly currencies: readonly CurrencyRef[]
  readonly savingsConstants: SavingsConstants
  /**
   * The Add Expense icon grid — **37** entries, in iOS order (`AddExpenseSheet.swift:193-231`).
   * The "18" in earlier docs was a clipped-screenshot miscount.
   */
  readonly expenseIcons: readonly SFSymbol[]
  /**
   * The New Category icon grid — **12** entries (R12). ⚠️ A DIFFERENT list from
   * `expenseIcons`: they overlap on only 5 symbols, and `calendar` is in this grid but not
   * that one. Sharing one array between the two screens breaks one of them silently.
   */
  readonly categoryIcons: readonly SFSymbol[]
  /** The New Category colour swatches — 10 hex strings (R12). Never hardcode a palette. */
  readonly categoryColors: readonly string[]
  readonly defaultNewCategory: {
    readonly icon: SFSymbol
    readonly colorHex: string
    readonly sortOrder: number
  }
  readonly defaultExpenseIcon: SFSymbol
}

/* ================================================================== *
 * §1 AppState — the one read
 * ================================================================== */

export interface AppState {
  readonly schemaVersion: number
  readonly onboardingCompleted: boolean
  /** `null` before onboarding completes. */
  readonly profile?: Profile
  readonly settings: Settings
  readonly accounts: readonly Account[]
  readonly expenses: readonly Expense[]
  readonly categories: readonly Category[]
  readonly dashboard: DashboardState
  readonly expensesScreen: ExpensesScreenState
  readonly transferPlan: TransferPlan
  readonly reference: Reference
}

/* ================================================================== *
 * PENDING CONTRACT CHANGES — announced by `main`, not yet in API-CONTRACT v1.
 *
 * Deliberately NOT typed here: guessing the shape of an unpublished field is how a typed
 * client drifts from its server. Backend will publish these and the types land then. Until
 * they do, **do not build a local workaround** for any of them.
 *
 *  R13 `savingsSliderPositions` — a precomputed table covering every selectable savings
 *      slider position, each carrying `percentDisplay` and a full money triple. Dragging
 *      the slider is an ARRAY INDEX LOOKUP. The savings screens (onboarding step 6 and
 *      Settings) must not be built until this exists, and the "That's 1,182 RON/month"
 *      caption must never be computed locally as a stopgap.
 *  R14 `Account.isReconcilable` — New Month step 2 lists only reconcilable accounts.
 *      Do NOT hardcode the `emergency|savings|personal` rule client-side.
 *  R14 `Account.wasLastMonthDisplay` — the "was X last month" caption on that step.
 *  R12 `reference.categoryIcons` (12) and `reference.categoryColors` (10), joining
 *      `expenseIcons` (37). All three server-served; never hardcode a palette.
 *
 * `Account.subtitleParts` LANDED in v1.2 — see the type. Do not reconstruct a flat
 * `subtitle` string from it, and never split on "•": the bullet belongs to the part.
 *
 * Behavioural rules already settled, recorded where they will be needed:
 *
 *  **Split allocation mode defaults to Fixed Amount at 0 on BOTH sides** — total `0 RON`.
 *  The 10% / 15% in `splitEmergencyPercentage` / `splitSavingsPercentage` are the rates
 *  revealed *after* toggling a side to Percentage; they are NOT allocation defaults. A
 *  client that defaults to Percentage shows 473 / 710 RON allocated where iOS shows
 *  nothing.
 *
 *  **"Skip for now" means "discard my edits", not "opt out"** — and it differs per screen:
 *   - Expenses skip zeroes every amount, so no expense rows persist and
 *     `availableIncome == income`.
 *   - Savings skip RESETS to 25% / prioritized / percentage and **still persists 25%**.
 *
 * Two behavioural rules for the Expenses screen, already settled (R14 gap 4, R17):
 *  - **Search filters rows only.** The header `totalMonthly` / `totalAnnual` and every
 *    "n/m enabled" count are GLOBAL and search-independent. Typing in the search box
 *    changes the list and leaves the header total unchanged. Recomputing the total from
 *    the visible rows would be both the wrong number and client-side maths.
 *  - **Custom-category order** tie-breaks on `createdAt` then `name`: iOS sorts by
 *    `sortOrder` with an unstable sort and every custom category has `sortOrder = 100`.
 * ================================================================== */

/* ================================================================== *
 * §3 Request payloads
 * ================================================================== */

export interface AccountPayload {
  readonly id?: Uuid
  readonly name?: string
  readonly purpose?: string
  readonly accountType?: AccountTypeValue
  readonly isPrimary?: boolean
  readonly isPrimarySavings?: boolean
  readonly emergencyMultiplier?: number | null
  readonly emergencyHardCap?: MoneyRequest | null
  readonly currentBalance?: MoneyRequest
}

export interface ExpensePayload {
  readonly id?: Uuid
  readonly name?: string
  readonly amount?: MoneyRequest
  readonly frequency?: FrequencyValue
  readonly icon?: SFSymbol
  readonly categoryId?: Uuid | null
  readonly linkedAccountId?: Uuid | null
  readonly isEnabled?: boolean
  readonly notes?: string | null
}

export interface SavingsPayload {
  readonly percentage?: number
  readonly boostEnabled?: boolean
  readonly boostMultiplier?: number
  readonly allocationMode?: AllocationModeValue
  readonly savingsInputMode?: SavingsInputModeValue
  readonly fixedAmount?: MoneyRequest
  readonly splitEmergencyInputMode?: SavingsInputModeValue
  readonly splitEmergencyAmount?: MoneyRequest
  readonly splitEmergencyPercentage?: number
  readonly splitSavingsInputMode?: SavingsInputModeValue
  readonly splitSavingsAmount?: MoneyRequest
  readonly splitSavingsPercentage?: number
}

export interface OnboardingPayload {
  readonly name: string
  readonly currencyCode: string
  readonly monthlyIncome: MoneyRequest
  readonly accounts: readonly AccountPayload[]
  readonly expenses: readonly ExpensePayload[]
  readonly savings?: SavingsPayload
  readonly remainingMoneyDestination?: RemainingMoneyDestinationValue
}

export interface OnboardingPreview {
  readonly availableIncome: MoneyValue
  readonly savingsAmount: MoneyValue
  readonly totalExpenses: MoneyValue
  readonly accounts: readonly Account[]
  readonly transferPlan: TransferPlan
}

export interface SettingsPayload {
  readonly name?: string
  readonly currencyCode?: string
  readonly monthlyIncome?: MoneyRequest
  readonly remainingMoneyDestination?: RemainingMoneyDestinationValue
  readonly savings?: SavingsPayload
}

export interface CategoryPayload {
  readonly name: string
  readonly icon: SFSymbol
  readonly colorHex: string
}

export interface NewMonthPayload {
  readonly income: MoneyRequest
  /** account id -> balance string. Omitted accounts keep their stored balance. */
  readonly reconciledBalances: Readonly<Record<Uuid, MoneyRequest>>
}

export interface ProjectedBalance {
  readonly accountId: Uuid
  readonly accountName: string
  readonly before: MoneyValue
  readonly after: MoneyValue
}

export interface NewMonthPreview {
  readonly transferPlan: TransferPlan
  readonly projectedBalances: readonly ProjectedBalance[]
  /**
   * Present (and non-zero) when the remainder had nowhere to go — e.g. the destination is
   * `primarySavings` but no such account exists. When present, show a warning **instead
   * of** the "All amounts add up correctly" banner: the money really is unaccounted for.
   * Omitted when zero (v1.1).
   */
  readonly unallocatedRemainingMoney?: MoneyValue
}

export interface ParseAmountResult {
  readonly amount: Money
  readonly display: string
  readonly editing: string
}

/* ================================================================== *
 * Transport
 * ================================================================== */

interface RequestOptions {
  readonly signal?: AbortSignal
}

async function request<TResponse>(
  method: 'GET' | 'POST' | 'PUT' | 'DELETE',
  path: string,
  body?: unknown,
  options: RequestOptions = {},
): Promise<TResponse> {
  const url = API_BASE + path

  const init: RequestInit = {
    method,
    headers: body === undefined ? {} : { 'Content-Type': 'application/json' },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    ...(options.signal ? { signal: options.signal } : {}),
  }

  const response = await fetch(url, init)
  const text = await response.text()

  if (!response.ok) {
    throw new ApiError(response.status, url, extractReason(text))
  }

  if (response.status === 204 || text.length === 0) return undefined as TResponse
  return JSON.parse(text) as TResponse
}

function extractReason(body: string): string {
  try {
    const parsed = JSON.parse(body) as Partial<ApiErrorBody>
    if (typeof parsed.reason === 'string') return parsed.reason
  } catch {
    // Not the Vapor error shape — fall through to the raw body.
  }
  return body.slice(0, 300)
}

export const http = {
  get: <T>(path: string, options?: RequestOptions) => request<T>('GET', path, undefined, options),
  post: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    request<T>('POST', path, body, options),
  put: <T>(path: string, body?: unknown, options?: RequestOptions) =>
    request<T>('PUT', path, body, options),
  delete: <T>(path: string, options?: RequestOptions) =>
    request<T>('DELETE', path, undefined, options),
}

const id = (value: string) => encodeURIComponent(value)

/**
 * Every method returning `AppState` returns the COMPLETE state (§0.2).
 * Replace the whole store with it — never merge.
 */
export const api = {
  getState: (o?: RequestOptions) => http.get<AppState>('/state', o),

  completeOnboarding: (body: OnboardingPayload, o?: RequestOptions) =>
    http.post<AppState>('/onboarding/complete', body, o),
  previewOnboarding: (body: OnboardingPayload, o?: RequestOptions) =>
    http.post<OnboardingPreview>('/onboarding/preview', body, o),

  updateSettings: (body: SettingsPayload, o?: RequestOptions) =>
    http.put<AppState>('/settings', body, o),

  createAccount: (body: AccountPayload, o?: RequestOptions) =>
    http.post<AppState>('/accounts', body, o),
  updateAccount: (accountId: Uuid, body: AccountPayload, o?: RequestOptions) =>
    http.put<AppState>(`/accounts/${id(accountId)}`, body, o),
  deleteAccount: (accountId: Uuid, o?: RequestOptions) =>
    http.delete<AppState>(`/accounts/${id(accountId)}`, o),

  createExpense: (body: ExpensePayload, o?: RequestOptions) =>
    http.post<AppState>('/expenses', body, o),
  updateExpense: (expenseId: Uuid, body: ExpensePayload, o?: RequestOptions) =>
    http.put<AppState>(`/expenses/${id(expenseId)}`, body, o),
  deleteExpense: (expenseId: Uuid, o?: RequestOptions) =>
    http.delete<AppState>(`/expenses/${id(expenseId)}`, o),

  listCategories: (o?: RequestOptions) =>
    http.get<{ categories: readonly Category[] }>('/categories', o),
  createCategory: (body: CategoryPayload, o?: RequestOptions) =>
    http.post<AppState>('/categories', body, o),
  deleteCategory: (categoryId: Uuid, o?: RequestOptions) =>
    http.delete<AppState>(`/categories/${id(categoryId)}`, o),

  getTransferPlan: (o?: RequestOptions) =>
    http.get<{ transferPlan: TransferPlan }>('/transfer-plan', o),

  previewNewMonth: (body: NewMonthPayload, o?: RequestOptions) =>
    http.post<NewMonthPreview>('/new-month/preview', body, o),
  applyNewMonth: (body: NewMonthPayload, o?: RequestOptions) =>
    http.post<AppState>('/new-month', body, o),

  reset: (o?: RequestOptions) => http.post<AppState>('/reset', undefined, o),

  /** Exact `AmountFormatter.parse`, comma quirk included. See money.ts `parseUserInput`. */
  parseAmount: (text: string, o?: RequestOptions) =>
    http.post<ParseAmountResult>('/parse-amount', { text }, o),
}
