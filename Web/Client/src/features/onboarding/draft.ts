/**
 * The onboarding draft and its mutations — a direct port of `OnboardingViewModel`.
 *
 * Every rule here comes from PARITY-SPEC §2.4 "Mutation rules", §2.6 and §2.8, and the
 * two "Skip for now" semantics in DECISIONS.md R23. They are pure functions over the
 * draft so they can be unit-tested without rendering anything, which is what makes the
 * asymmetric skip behaviours (expenses zeroes, savings resets to 25 %) assertable.
 *
 * **No arithmetic anywhere in this file** (R2). Money is moved around as opaque decimal
 * strings; the only numeric predicates used are `isZero` / `isNegative` from `money.ts`,
 * which are string inspections.
 */

import type {
  AccountPayload,
  AccountTypeValue,
  Category,
  ExpensePayload,
  OnboardingPayload,
  SFSymbol,
  Uuid,
} from '../../lib/api'
import { ZERO, editingString, isNegative, isZero, type Money } from '../../lib/money'
import type {
  AccountChanges,
  DraftAccount,
  ExpenseChanges,
  DraftExpense,
  DraftSavings,
  OnboardingDraft,
} from './types'

/* ------------------------------------------------------------------ *
 * Seeds
 * ------------------------------------------------------------------ */

/**
 * `SavingsAllocationEntry()` (DOMAIN-CONTRACT §2).
 *
 * ⚠️ The two split sides default to **fixedAmount 0**, not to their percentages. The
 * 10 % / 15 % below are the rates revealed only *after* a side is switched to Percentage.
 */
/** The empty amount field — `formatForEditing(0)` is `""` on iOS too. */
const EMPTY = editingString('')

export const DEFAULT_SAVINGS: DraftSavings = {
  allocationMode: 'prioritized',
  savingsInputMode: 'percentage',
  percentage: 0.25,
  fixedAmount: ZERO,
  fixedAmountText: EMPTY,
  boostEnabled: false,
  boostMultiplier: 3,
  splitEmergencyInputMode: 'fixedAmount',
  splitEmergencyAmount: ZERO,
  splitEmergencyAmountText: EMPTY,
  splitEmergencyPercentage: 0.1,
  splitSavingsInputMode: 'fixedAmount',
  splitSavingsAmount: ZERO,
  splitSavingsAmountText: EMPTY,
  splitSavingsPercentage: 0.15,
}

/**
 * The four seeded expense rows (`OnboardingViewModel.swift:16-21`, DOMAIN-CONTRACT §6).
 * `categoryName` is the English Domain category name, resolved to a real `categoryId`
 * against the server's `state.categories` — the IDs themselves are never hardcoded.
 */
export const SEED_EXPENSES: readonly {
  readonly nameKey: string
  /** Language-independent id for testids (Reviewer's `EXPENSE` slugs). */
  readonly slug: string
  readonly icon: SFSymbol
  readonly categoryName: string
}[] = [
  { nameKey: 'Food', slug: 'food', icon: 'cart.fill', categoryName: 'Food/Groceries' },
  { nameKey: 'Rent', slug: 'rent', icon: 'house.fill', categoryName: 'Housing' },
  { nameKey: 'Gas', slug: 'gas', icon: 'fuelpump.fill', categoryName: 'Auto/Transport' },
  { nameKey: 'Streaming', slug: 'streaming', icon: 'tv.fill', categoryName: 'Subscriptions' },
]

/** `AccountEntry` static factories (DOMAIN-CONTRACT §5) — keys in the `domain` catalog. */
export const ACCOUNT_FACTORY_NAMES = {
  primary: 'Main Account',
  emergency: 'Emergency Fund',
  savings: 'Savings',
  personal: 'Personal',
  joint: 'Joint',
} as const

/** `EmergencyMultiplierPicker.swift:15`. Kept until `emergencyMultiplierOptions` ships (R18). */
export const EMERGENCY_MULTIPLIERS: readonly number[] = [3, 4, 5, 6]

/** `multiplierDescription` (`EmergencyMultiplierPicker.swift:191-197`) — localization keys. */
export const EMERGENCY_MULTIPLIER_CAPTIONS: Readonly<Record<string, string>> = {
  '3': 'Minimum recommended',
  '4': 'Standard protection',
  '5': 'Enhanced protection',
  '6': 'Maximum security',
}

export const DEFAULT_EMERGENCY_MULTIPLIER = 3

function newId(): Uuid {
  return crypto.randomUUID()
}

export interface SeedOptions {
  /** Localizes the seeded names, exactly as iOS seeds `"Food".localized` at init. */
  readonly translateOnboarding: (key: string) => string
  readonly translateDomain: (key: string) => string
  readonly currencyCode: string
  readonly categories: readonly Category[]
}

function categoryIdFor(categories: readonly Category[], name: string): Uuid | undefined {
  return categories.find((category) => category.name === name)?.id
}

export function createDraft(options: SeedOptions): OnboardingDraft {
  const primary: DraftAccount = {
    id: newId(),
    name: options.translateDomain(ACCOUNT_FACTORY_NAMES.primary),
    accountType: 'primary',
    isPrimary: true,
    isPrimarySavings: false,
    currentBalance: ZERO,
    balanceText: EMPTY,
    hardCapText: EMPTY,
  }
  const expenses: DraftExpense[] = SEED_EXPENSES.map((seed) => {
    const categoryId = categoryIdFor(options.categories, seed.categoryName)
    return {
      id: newId(),
      slug: seed.slug,
      name: options.translateOnboarding(seed.nameKey),
      icon: seed.icon,
      amount: ZERO,
      amountText: EMPTY,
      ...(categoryId ? { categoryId } : {}),
    }
  })
  return {
    name: '',
    currencyCode: options.currencyCode,
    monthlyIncome: ZERO,
    incomeText: EMPTY,
    accounts: [primary],
    expenses,
    savings: DEFAULT_SAVINGS,
    remainingMoneyDestination: 'primarySavings',
  }
}

/* ------------------------------------------------------------------ *
 * Predicates — `canAdvance` (PARITY-SPEC §2.0)
 * ------------------------------------------------------------------ */

export const MAX_NAME_LENGTH = 50

export function trimmedName(draft: OnboardingDraft): string {
  return draft.name.trim()
}

export function isNameValid(draft: OnboardingDraft): boolean {
  const trimmed = trimmedName(draft)
  return trimmed.length >= 1 && trimmed.length <= MAX_NAME_LENGTH
}

/** `monthlyIncome > 0` — a string inspection, never a numeric comparison. */
export function hasIncome(draft: OnboardingDraft): boolean {
  return !isZero(draft.monthlyIncome) && !isNegative(draft.monthlyIncome)
}

export function hasPrimaryAccount(draft: OnboardingDraft): boolean {
  return draft.accounts.some((account) => account.isPrimary)
}

export function hasEmergencyAccount(draft: OnboardingDraft): boolean {
  return draft.accounts.some((account) => account.accountType === 'emergency')
}

export function hasPrimarySavingsAccount(draft: OnboardingDraft): boolean {
  return draft.accounts.some((account) => account.isPrimarySavings)
}

export function isPositive(amount: Money): boolean {
  return !isZero(amount) && !isNegative(amount)
}

/* ------------------------------------------------------------------ *
 * Account mutations (PARITY-SPEC §2.4 "Mutation rules")
 * ------------------------------------------------------------------ */

export function addAccount(
  draft: OnboardingDraft,
  name: string,
  accountType: AccountTypeValue,
): OnboardingDraft {
  // Guarded against a double-add: only one emergency account may exist.
  if (accountType === 'emergency' && hasEmergencyAccount(draft)) return draft

  const account: DraftAccount = {
    id: newId(),
    name,
    accountType,
    isPrimary: false,
    isPrimarySavings: accountType === 'savings' && !hasPrimarySavingsAccount(draft),
    currentBalance: ZERO,
    balanceText: EMPTY,
    hardCapText: EMPTY,
    ...(accountType === 'emergency'
      ? { emergencyMultiplier: DEFAULT_EMERGENCY_MULTIPLIER }
      : {}),
  }
  return { ...draft, accounts: [...draft.accounts, account] }
}

/** Applies changes, treating an explicit `undefined` as "remove this optional field". */
function applyAccountChanges(account: DraftAccount, changes: AccountChanges): DraftAccount {
  const next: Record<string, unknown> = { ...account, ...changes }
  for (const [key, value] of Object.entries(changes)) {
    if (value === undefined) delete next[key]
  }
  return next as unknown as DraftAccount
}

export function updateAccount(
  draft: OnboardingDraft,
  accountId: Uuid,
  changes: AccountChanges,
): OnboardingDraft {
  return {
    ...draft,
    accounts: draft.accounts.map((account) =>
      account.id === accountId ? applyAccountChanges(account, changes) : account,
    ),
  }
}

/**
 * `handleTypeChange` — note the guard reads "is there a primary-savings account" over the
 * accounts as they are *before* the change, so re-selecting Savings on the account that is
 * already primary savings keeps it primary (the ⚠️ in PARITY-SPEC §2.4).
 */
export function changeAccountType(
  draft: OnboardingDraft,
  accountId: Uuid,
  newType: AccountTypeValue,
): OnboardingDraft {
  if (newType === 'emergency' && hasEmergencyAccount(draft)) return draft
  const alreadyHasPrimarySavings = hasPrimarySavingsAccount(draft)

  return {
    ...draft,
    accounts: draft.accounts.map((account) => {
      if (account.id !== accountId) return account
      const base: DraftAccount = {
        ...account,
        accountType: newType,
        isPrimarySavings:
          newType === 'savings' ? account.isPrimarySavings || !alreadyHasPrimarySavings : false,
      }
      if (newType === 'emergency') {
        return { ...base, emergencyMultiplier: DEFAULT_EMERGENCY_MULTIPLIER }
      }
      // Leaving emergency clears BOTH the multiplier and the hard cap.
      return applyAccountChanges(base, {
        emergencyMultiplier: undefined,
        emergencyHardCap: undefined,
        hardCapText: EMPTY,
      })
    }),
  }
}

/** Clears `isPrimarySavings` on every account, then sets it on the target. */
export function setPrimarySavings(draft: OnboardingDraft, accountId: Uuid): OnboardingDraft {
  return {
    ...draft,
    accounts: draft.accounts.map((account) => ({
      ...account,
      isPrimarySavings: account.id === accountId,
    })),
  }
}

export function deleteAccount(draft: OnboardingDraft, accountId: Uuid): OnboardingDraft {
  return { ...draft, accounts: draft.accounts.filter((account) => account.id !== accountId) }
}

/* ------------------------------------------------------------------ *
 * Expense mutations
 * ------------------------------------------------------------------ */

export function updateExpense(
  draft: OnboardingDraft,
  expenseId: Uuid,
  changes: ExpenseChanges,
): OnboardingDraft {
  return {
    ...draft,
    expenses: draft.expenses.map((expense) => {
      if (expense.id !== expenseId) return expense
      const next: Record<string, unknown> = { ...expense, ...changes }
      for (const [key, value] of Object.entries(changes)) {
        if (value === undefined) delete next[key]
      }
      return next as unknown as DraftExpense
    }),
  }
}

/**
 * R23 — **Expenses "Skip for now" zeroes all four amounts.** The rows stay in memory with
 * their name/icon/category; only `amount` is forced to 0. At save, `where amount > 0`
 * means **no expense row is persisted**, so `availableIncome == income`.
 */
export function skipExpenses(draft: OnboardingDraft): OnboardingDraft {
  return {
    ...draft,
    expenses: draft.expenses.map((expense) => ({ ...expense, amount: ZERO, amountText: EMPTY })),
  }
}

/**
 * R23 — **Savings "Skip for now" does NOT zero savings.** It assigns a fresh
 * `SavingsAllocationEntry()`, i.e. back to 25 % prioritized/percentage with boost off, and
 * a savings row **is** persisted. Skipping the savings screen still saves 25 %.
 */
export function skipSavings(draft: OnboardingDraft): OnboardingDraft {
  return { ...draft, savings: DEFAULT_SAVINGS }
}

export function updateSavings(
  draft: OnboardingDraft,
  changes: Partial<DraftSavings>,
): OnboardingDraft {
  return { ...draft, savings: { ...draft.savings, ...changes } }
}

/* ------------------------------------------------------------------ *
 * Payload
 * ------------------------------------------------------------------ */

function accountPayload(account: DraftAccount): AccountPayload {
  return {
    id: account.id,
    name: account.name,
    accountType: account.accountType,
    isPrimary: account.isPrimary,
    isPrimarySavings: account.isPrimarySavings,
    currentBalance: account.currentBalance,
    ...(account.emergencyMultiplier === undefined
      ? {}
      : { emergencyMultiplier: account.emergencyMultiplier }),
    ...(account.emergencyHardCap === undefined
      ? {}
      : { emergencyHardCap: account.emergencyHardCap }),
  }
}

function expensePayload(expense: DraftExpense): ExpensePayload {
  return {
    id: expense.id,
    name: expense.name,
    amount: expense.amount,
    frequency: 'monthly',
    icon: expense.icon,
    ...(expense.categoryId === undefined ? {} : { categoryId: expense.categoryId }),
    ...(expense.linkedAccountId === undefined
      ? {}
      : { linkedAccountId: expense.linkedAccountId }),
  }
}

/**
 * @param persisting `true` for `POST /api/onboarding/complete`, which drops zero-amount
 * expenses exactly as `OnboardingViewModel.save` does (`where expense.amount > 0`,
 * PARITY-SPEC §2.8 step 3). The **preview** keeps them, because the live screens compute
 * their plan from the in-memory rows.
 */
export function toPayload(draft: OnboardingDraft, persisting = false): OnboardingPayload {
  const expenses = persisting
    ? draft.expenses.filter((expense) => isPositive(expense.amount))
    : draft.expenses
  return {
    name: trimmedName(draft),
    currencyCode: draft.currencyCode,
    monthlyIncome: draft.monthlyIncome,
    accounts: draft.accounts.map(accountPayload),
    expenses: expenses.map(expensePayload),
    savings: {
      percentage: draft.savings.percentage,
      boostEnabled: draft.savings.boostEnabled,
      boostMultiplier: draft.savings.boostMultiplier,
      allocationMode: draft.savings.allocationMode,
      savingsInputMode: draft.savings.savingsInputMode,
      fixedAmount: draft.savings.fixedAmount,
      splitEmergencyInputMode: draft.savings.splitEmergencyInputMode,
      splitEmergencyAmount: draft.savings.splitEmergencyAmount,
      splitEmergencyPercentage: draft.savings.splitEmergencyPercentage,
      splitSavingsInputMode: draft.savings.splitSavingsInputMode,
      splitSavingsAmount: draft.savings.splitSavingsAmount,
      splitSavingsPercentage: draft.savings.splitSavingsPercentage,
    },
    remainingMoneyDestination: draft.remainingMoneyDestination,
  }
}
