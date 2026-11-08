/**
 * Category ordering — one place, because it is a nondeterminism trap (DECISIONS.md R17).
 *
 * iOS sorts `allCategories` with `sorted { $0.sortOrder < $1.sortOrder }`. Swift's `sorted`
 * is **not guaranteed stable**, and every custom category is created with
 * `sortOrder = 100`, so two customs are formally unordered — they can swap between
 * launches. The web must be deterministic, so ties break further.
 *
 * ⚠️ R17 specifies `createdAt` then `name`. **`Category` carries no `createdAt`** in the
 * API (`api.ts`: id, name, icon, colorHex, isDefault, sortOrder), so only `name` is
 * available and the order is by `(sortOrder, name)`. Two customs with the same name would
 * still be unordered — but they are also indistinguishable on screen, so nothing renders
 * differently. Raised with Backend; if `createdAt` is added, insert it before `name` here
 * and nowhere else.
 */

import type { Category } from '../../../lib/api'

export function orderedCategories(categories: readonly Category[]): readonly Category[] {
  // Compared, never subtracted: the R2 guard is about money, but a comparator that
  // returns a difference is one refactor away from being handed a decimal string.
  return [...categories].sort((left, right) => {
    if (left.sortOrder < right.sortOrder) return -1
    if (left.sortOrder > right.sortOrder) return 1
    return left.name.localeCompare(right.name)
  })
}

export function defaultCategories(categories: readonly Category[]): readonly Category[] {
  return orderedCategories(categories).filter((category) => category.isDefault)
}

export function customCategories(categories: readonly Category[]): readonly Category[] {
  return orderedCategories(categories).filter((category) => !category.isDefault)
}
