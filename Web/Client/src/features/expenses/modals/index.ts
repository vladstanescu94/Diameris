/**
 * The three Expenses modals. `ExpensesScreen.tsx` (Frontend's) wires the entry points:
 * the toolbar `+` and a row tap open `AddExpenseSheet`; the `…` overflow's
 * "Manage Categories" opens `CategoryManagementView`. `AddCategorySheet` is presented from
 * inside the other two, exactly as iOS does, so it needs no entry point of its own.
 */

export { AddExpenseSheet } from './AddExpenseSheet'
export type { AddExpenseSheetProps } from './AddExpenseSheet'
export { CategoryManagementView } from './CategoryManagementView'
export type { CategoryManagementViewProps } from './CategoryManagementView'
export { AddCategorySheet } from './AddCategorySheet'
export type { AddCategorySheetProps } from './AddCategorySheet'
export { orderedCategories, defaultCategories, customCategories } from './categoryOrder'
/** Dev-only (`?dev=modals`); never reachable from app navigation — see the file header. */
export { ModalsDevHarness } from './ModalsDevHarness'
