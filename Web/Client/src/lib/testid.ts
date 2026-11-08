/**
 * Test-id slugs — the client half of `Web/Verify/parity/testids.ts`.
 *
 * The Reviewer owns that file and it is a **contract**, not a convenience: the parity
 * harness locates every asserted value through it. Never rename an id locally — if one
 * does not fit the markup, message the Reviewer.
 *
 * Slug rules, derived from the constants the specs use:
 *  - categories and expenses slugify their NAME: `"Auto/Transport"` -> `auto-transport`,
 *    `"Food/Groceries"` -> `food-groceries`, `"Rent"` -> `rent`.
 *  - accounts are keyed by TYPE, not name, because the contract expects `main` /
 *    `emergency` / `savings` where the names are "Main Account" / "Emergency Fund" /
 *    "Savings". Slugifying those names would give `main-account` and `emergency-fund`,
 *    so the primary account maps `primary -> main` and the rest use their type verbatim.
 *    Type-keying also survives a user renaming an account, which name-keying would not.
 */

import type { Account } from './api'

/** Lowercase, non-alphanumerics collapsed to single hyphens, trimmed. */
export function slugify(value: string): string {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
}

/**
 * ⚠️ Type-keyed, per the header. Two accounts of the same type would collide; the parity
 * fixture has one of each. Raised with the Reviewer.
 */
export function accountSlug(account: Pick<Account, 'accountType' | 'isPrimary'>): string {
  if (account.isPrimary || account.accountType === 'primary') return 'main'
  return account.accountType
}
