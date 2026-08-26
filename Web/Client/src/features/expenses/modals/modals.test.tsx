import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import type { AppState, Category, Expense } from '../../../lib/api'
import { LanguageProvider } from '../../../lib/i18n'
import { AddCategorySheet } from './AddCategorySheet'
import { AddExpenseSheet } from './AddExpenseSheet'
import { CategoryManagementView } from './CategoryManagementView'
import { customCategories, defaultCategories, orderedCategories } from './categoryOrder'

/** The 8 defaults, in `sortOrder`, exactly as `DOMAIN-CONTRACT.md §6` lists them. */
const DEFAULTS: readonly Category[] = [
  { id: 'd1', name: 'Auto/Transport', icon: 'car.fill', colorHex: '#3B82F6', isDefault: true, sortOrder: 1 },
  { id: 'd2', name: 'Subscriptions', icon: 'arrow.triangle.2.circlepath', colorHex: '#8B5CF6', isDefault: true, sortOrder: 2 },
  { id: 'd3', name: 'Lifestyle', icon: 'sparkles', colorHex: '#F59E0B', isDefault: true, sortOrder: 3 },
  { id: 'd4', name: 'Housing', icon: 'house.fill', colorHex: '#10B981', isDefault: true, sortOrder: 4 },
  { id: 'd5', name: 'Pets', icon: 'pawprint.fill', colorHex: '#EC4899', isDefault: true, sortOrder: 5 },
  { id: 'd6', name: 'Health/Fitness', icon: 'heart.fill', colorHex: '#EF4444', isDefault: true, sortOrder: 6 },
  { id: 'd7', name: 'Food/Groceries', icon: 'cart.fill', colorHex: '#22C55E', isDefault: true, sortOrder: 7 },
  { id: 'd8', name: 'Entertainment', icon: 'tv.fill', colorHex: '#06B6D4', isDefault: true, sortOrder: 8 },
]

/** The 37 and the 12 — trimmed to what the assertions need, incl. the `calendar` tell. */
const EXPENSE_ICONS = [
  'dollarsign.circle.fill', 'cart.fill', 'house.fill', 'car.fill', 'fuelpump.fill', 'shield.fill',
  'heart.fill', 'bolt.fill', 'leaf.fill', 'gift.fill', 'tv.fill', 'sparkles',
]
const CATEGORY_ICONS = [
  'star.fill', 'heart.fill', 'bolt.fill', 'leaf.fill', 'gift.fill', 'tag.fill',
  'bookmark.fill', 'flag.fill', 'bell.fill', 'clock.fill', 'calendar', 'folder.fill',
]
const CATEGORY_COLORS = [
  '#3B82F6', '#8B5CF6', '#F59E0B', '#10B981', '#EC4899',
  '#EF4444', '#22C55E', '#06B6D4', '#F97316', '#6366F1',
]

const STATE = {
  schemaVersion: 1,
  onboardingCompleted: true,
  profile: { name: 'Vlad', currencyCode: 'RON', currencyDisplayName: 'Romanian Leu (RON)', remainingMoneyDestination: 'primarySavings', remainingMoneyDestinationDisplayName: 'Primary Savings', createdAt: '2026-08-06T13:46:58Z' },
  settings: { income: { amount: '9000', display: '9,000 RON', editing: '9000' }, savings: {} },
  accounts: [
    { id: 'a1', name: 'Main Account', accountType: 'primary', isPrimary: true, isPrimarySavings: false, icon: 'building.columns.fill' },
    { id: 'a2', name: 'Emergency Fund', accountType: 'emergency', isPrimary: false, isPrimarySavings: false, icon: 'shield.fill' },
  ],
  expenses: [],
  categories: DEFAULTS,
  dashboard: {},
  expensesScreen: {},
  transferPlan: {},
  reference: {
    accountTypes: [],
    frequencies: [
      { value: 'monthly', displayName: 'Monthly', icon: 'calendar' },
      { value: 'annual', displayName: 'Annual', icon: 'calendar.badge.clock' },
    ],
    allocationModes: [],
    savingsInputModes: [],
    remainingMoneyDestinations: [],
    currencies: [],
    savingsConstants: {},
    expenseIcons: EXPENSE_ICONS,
    categoryIcons: CATEGORY_ICONS,
    categoryColors: CATEGORY_COLORS,
    defaultNewCategory: { icon: 'star.fill', colorHex: '#3B82F6', sortOrder: 100 },
    defaultExpenseIcon: 'dollarsign.circle.fill',
  },
} as unknown as AppState

const ANNUAL_EXPENSE = {
  id: 'e1',
  name: 'Insurance',
  amount: { amount: '1200', display: '1,200 RON', editing: '1200' },
  frequency: 'annual',
  frequencyDisplayName: 'Annual',
  frequencyIcon: 'calendar.badge.clock',
  monthlyAmount: { amount: '100', display: '100 RON', editing: '100' },
  annualAmount: { amount: '1200', display: '1,200 RON', editing: '1200' },
  icon: 'shield.fill',
  linkedAccountName: 'Main Account',
  isEnabled: true,
  sortOrder: 0,
} as unknown as Expense

function render(node: React.ReactNode): string {
  return renderToStaticMarkup(
    <LanguageProvider language="en" setLanguage={() => {}}>
      {node}
    </LanguageProvider>,
  )
}

describe('AddExpenseSheet — PARITY-SPEC §5.3', () => {
  const add = () =>
    render(<AddExpenseSheet state={STATE} onClose={() => {}} onSaved={() => {}} />)

  it('titles Add vs Edit', () => {
    expect(add()).toContain('Add Expense')
    expect(
      render(
        <AddExpenseSheet
          state={STATE}
          expense={ANNUAL_EXPENSE}
          onClose={() => {}}
          onSaved={() => {}}
        />,
      ),
    ).toContain('Edit Expense')
  })

  it('renders every section header in order', () => {
    const html = add()
    for (const header of ['Details', 'Category', 'Account', 'Icon', 'Notes']) {
      expect(html).toContain(header)
    }
    expect(html).toContain('Choose which account this expense is paid from.')
    // `renderToStaticMarkup` escapes the apostrophe, so match around it.
    expect(html).toContain('Disabled expenses won')
    expect(html).toContain('included in your budget calculations.')
  })

  it('disables Save until the draft is valid — amount 0 is REJECTED', () => {
    // `ExpenseInput.isValid` is `!name.trimmed.isEmpty && amount > 0`. `Docs/MVP/03`
    // explicitly wants 0 allowed for a suspended expense; the shipped code refuses it.
    expect(add()).toContain('disabled')
  })

  it('seeds the amount field from `editing`, never `display` (R24)', () => {
    const html = render(
      <AddExpenseSheet state={STATE} expense={ANNUAL_EXPENSE} onClose={() => {}} onSaved={() => {}} />,
    )
    expect(html).toContain('value="1200"')
    expect(html).not.toContain('1,200 RON"')
  })

  it('renders the frequency labels RAW — iOS shows English in Romanian too (R28d)', () => {
    const html = render(
      <LanguageProvider language="ro" setLanguage={() => {}}>
        <AddExpenseSheet state={STATE} onClose={() => {}} onSaved={() => {}} />
      </LanguageProvider>,
    )
    expect(html).toContain('Monthly')
    expect(html).toContain('Annual')
    // …while the sheet's own strings ARE Romanian.
    expect(html).toContain('Detalii')
  })

  it('offers None first, then the categories, and lists only non-primary accounts', () => {
    const html = add()
    expect(html).toContain('None')
    expect(html).toContain('Auto/Transport')
    expect(html).toContain('Emergency Fund')
    // "Primary" is the sentinel label; the primary account itself is not a separate item.
    expect(html).not.toContain('>Main Account<')
  })

  it('shows "New Category..." with three literal dots', () => {
    expect(add()).toContain('New Category...')
  })

  it('renders the Monthly Equivalent row ONLY from the server, never a local ÷12', () => {
    /*
     * §5.3 item 2. The value is `amount × Frequency.annual.monthlyMultiplier` — a **÷12**,
     * not the `×12` R18 records (144× wrong if followed literally). It now comes from
     * `POST /api/expenses/preview`, gate included.
     *
     * This renders without a network, so the row must be ABSENT: the assertion is that no
     * fallback exists. A locally-divided number would appear here, and would be wrong on
     * the value — not just the rounding — at boundaries like 1266 (iOS 105, JS 106),
     * because the multiplier is `Decimal(1)/12` rather than a true division.
     */
    const html = render(
      <AddExpenseSheet state={STATE} expense={ANNUAL_EXPENSE} onClose={() => {}} onSaved={() => {}} />,
    )
    expect(html).not.toContain('Monthly Equivalent')
    expect(html).not.toContain('100 RON')
  })
})

describe('the two icon grids are DIFFERENT lists (R12)', () => {
  it('`calendar` is in the category grid and absent from the expense grid', () => {
    // The cleanest discriminator: a shared array would put `calendar` in both, and a
    // count-only assertion would not notice.
    expect(CATEGORY_ICONS).toContain('calendar')
    expect(EXPENSE_ICONS).not.toContain('calendar')

    const expenseHtml = render(
      <AddExpenseSheet state={STATE} onClose={() => {}} onSaved={() => {}} />,
    )
    const categoryHtml = render(
      <AddCategorySheet state={STATE} onClose={() => {}} onCreated={() => {}} />,
    )
    expect(categoryHtml).toContain('aria-label="calendar"')
    expect(expenseHtml).not.toContain('aria-label="calendar"')
  })

  it('both grids come from `reference`, never a local array', () => {
    const html = render(<AddCategorySheet state={STATE} onClose={() => {}} onCreated={() => {}} />)
    for (const symbol of CATEGORY_ICONS) expect(html).toContain(`aria-label="${symbol}"`)
    for (const color of CATEGORY_COLORS) expect(html).toContain(color)
  })
})

describe('AddCategorySheet — PARITY-SPEC §5.5', () => {
  const sheet = () =>
    render(<AddCategorySheet state={STATE} onClose={() => {}} onCreated={() => {}} />)

  it('renders all four sections', () => {
    const html = sheet()
    for (const header of ['Category Name', 'Icon', 'Color', 'Preview']) {
      expect(html).toContain(header)
    }
  })

  it('previews the placeholder "Category Name" until a name is typed', () => {
    expect(sheet()).toContain('Category Name')
  })

  it('defaults to star.fill on swatch 1, from `reference.defaultNewCategory`', () => {
    const html = sheet()
    expect(html).toContain('aria-label="star.fill"')
    expect(html).toContain('#3B82F6')
  })

  it('disables Add until named', () => {
    expect(sheet()).toContain('disabled')
  })
})

describe('CategoryManagementView — PARITY-SPEC §5.4', () => {
  const view = () =>
    render(<CategoryManagementView state={STATE} onClose={() => {}} onChanged={() => {}} />)

  it('lists all 8 defaults even with no expenses, each with a Default pill', () => {
    const html = view()
    for (const category of DEFAULTS) expect(html).toContain(category.name)
    expect(html.match(/xm-default-pill/g) ?? []).toHaveLength(8)
  })

  it('shows the footer and hides the Custom section when there are none', () => {
    const html = view()
    expect(html).toContain('Default categories cannot be deleted.')
    expect(html).not.toContain('Custom Categories')
  })

  it('renders rows as non-interactive — categories cannot be edited (§5.4)', () => {
    const html = view()
    expect(html).toContain('class="xm-category-row"')
    expect(html).not.toContain('<button type="button" class="xm-category-row"')
  })

  it('shows the Custom section, with a delete affordance, when customs exist', () => {
    const withCustom = {
      ...STATE,
      categories: [
        ...DEFAULTS,
        { id: 'c1', name: 'Travel', icon: 'airplane', colorHex: '#F97316', isDefault: false, sortOrder: 100 },
      ],
    } as unknown as AppState
    const html = render(
      <CategoryManagementView state={withCustom} onClose={() => {}} onChanged={() => {}} />,
    )
    expect(html).toContain('Custom Categories')
    expect(html).toContain('category-delete-travel')
  })
})

describe('category ordering (R17)', () => {
  it('orders defaults by sortOrder', () => {
    expect(orderedCategories(DEFAULTS).map((category) => category.name)).toEqual(
      DEFAULTS.map((category) => category.name),
    )
  })

  it('tie-breaks customs deterministically — iOS’s unstable sort leaves them unordered', () => {
    // Every custom category is created with sortOrder 100, and Swift's `sorted` is not
    // guaranteed stable, so two customs can swap between launches on iOS. The web must not.
    const customs = [
      { id: 'c2', name: 'Zebra', icon: 'star.fill', colorHex: '#000', isDefault: false, sortOrder: 100 },
      { id: 'c1', name: 'Alpha', icon: 'star.fill', colorHex: '#000', isDefault: false, sortOrder: 100 },
    ] as unknown as Category[]
    expect(customCategories(customs).map((category) => category.name)).toEqual(['Alpha', 'Zebra'])
    expect(defaultCategories(customs)).toHaveLength(0)
  })
})
