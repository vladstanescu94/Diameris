# Expenses

## Overview

Expense tracking is the core feature of Diameris. Users define recurring expenses with their frequency (monthly or annual), and the app normalizes them for budget calculations. This mirrors the Python script's `CHELTUIELI_LUNARE` and `CHELTUIELI_ANUALE` dictionaries.

**Key Principle:** Expenses are recurring/planned, not transaction logs. Users define "I spend ~3000 RON/month on food" rather than logging each grocery receipt.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | Add monthly recurring expenses | My budget reflects regular costs |
| User | Add annual expenses | One-time yearly costs are spread across months |
| User | Categorize my expenses | I can see spending by category |
| User | Enable/disable expenses | I can model different scenarios |
| User | See monthly vs annual totals | I understand both perspectives |
| User | Edit expenses easily | I can adjust as costs change |

---

## Expense Model

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier |
| `name` | String | Yes | Descriptive name (e.g., "Netflix") |
| `amount` | Decimal | Yes | Cost in user's currency |
| `frequency` | Frequency | Yes | `.monthly` or `.annual` |
| `categoryID` | UUID? | No | Link to category (optional) |
| `isEnabled` | Bool | Yes | Whether included in calculations |
| `notes` | String? | No | Optional user notes |
| `createdAt` | Date | Yes | When added |
| `updatedAt` | Date | Yes | Last modification |

### Domain Entity

```swift
// Domain/Entities/Expense.swift
struct Expense: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var amount: Decimal
    var frequency: Frequency
    var categoryID: UUID?
    var isEnabled: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // Normalized to monthly for calculations
    var monthlyAmount: Decimal {
        switch frequency {
        case .monthly: return amount
        case .annual: return amount / 12
        }
    }

    // Normalized to annual
    var annualAmount: Decimal {
        switch frequency {
        case .monthly: return amount * 12
        case .annual: return amount
        }
    }
}
```

---

## Default Expenses (From Python Script)

Based on the source script, these are typical expense patterns:

### Monthly Expenses
| Name | Category | Example Amount |
|------|----------|----------------|
| Food & Groceries | Lifestyle | 3,000 RON |
| Gas/Transportation | Auto | 300 RON |
| Gym Membership | Health/Fitness | 200 RON |
| Apple Music | Subscriptions | 40 RON |
| YouTube Premium | Subscriptions | 40 RON |
| iCloud Storage | Subscriptions | 10 RON |
| Haircuts | Lifestyle | 65 RON |
| Random/Misc | Lifestyle | 400 RON |
| Cat Food | Pets | 400 RON |
| Cat Litter | Pets | 100 RON |

### Annual Expenses
| Name | Category | Example Amount |
|------|----------|----------------|
| Car Service/Maintenance | Auto | 2,000 RON |
| Car Insurance | Auto | 2,500 RON |
| Vehicle Tax | Auto | 250 RON |
| Disney+ | Subscriptions | 370 RON |
| Crunchyroll | Subscriptions | 320 RON |
| Gym Supplements | Health/Fitness | 500 RON |

---

## UI/UX

### Expense List View

```
┌─────────────────────────────────────┐
│  ← Budget                     [+]   │
│                                     │
│  MONTHLY EXPENSES                   │
│  Total: 4,555 RON/month             │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🍽️ Food & Groceries         │    │
│  │    3,000 RON/month          │    │
│  │    Lifestyle                │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ⛽ Gas                       │    │
│  │    300 RON/month            │    │
│  │    Auto/Transport           │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🏋️ Gym Membership           │    │
│  │    200 RON/month            │    │
│  │    Health/Fitness           │    │
│  └─────────────────────────────┘    │
│                                     │
│  ... more ...                       │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ANNUAL EXPENSES                    │
│  Total: 5,940 RON/year              │
│  (495 RON/month equivalent)         │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🔧 Car Service              │    │
│  │    2,000 RON/year           │    │
│  │    ≈ 167 RON/month          │    │
│  │    Auto/Transport           │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Grouped by frequency (Monthly / Annual)
- Show monthly equivalent for annual expenses
- Category icon and label
- Swipe to delete/edit
- Tap for detail/edit view

### Add/Edit Expense Sheet

```
┌─────────────────────────────────────┐
│  Add Expense                    ✕   │
│                                     │
│  Name                               │
│  ┌─────────────────────────────┐    │
│  │  Netflix                    │    │
│  └─────────────────────────────┘    │
│                                     │
│  Amount                             │
│  ┌─────────────────────────────┐    │
│  │  RON      │    50           │    │
│  └─────────────────────────────┘    │
│                                     │
│  Frequency                          │
│  ┌──────────┐  ┌──────────┐         │
│  │ Monthly ◉│  │ Annual  ○│         │
│  └──────────┘  └──────────┘         │
│                                     │
│  Category                           │
│  ┌─────────────────────────────┐    │
│  │  📺 Subscriptions        ▼  │    │
│  └─────────────────────────────┘    │
│                                     │
│  Notes (optional)                   │
│  ┌─────────────────────────────┐    │
│  │  Shared with partner        │    │
│  └─────────────────────────────┘    │
│                                     │
│           [Save Expense]            │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Presented as sheet (Liquid Glass background)
- Category picker with icons
- Frequency toggle (default: monthly)
- Optional notes field
- Foundation Models: Suggest category based on expense name

### Expense Detail View

```
┌─────────────────────────────────────┐
│  ← Netflix                   [Edit] │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │        50 RON/month         │    │
│  │                             │    │
│  │    📺 Subscriptions         │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ANNUAL COST                        │
│  600 RON/year                       │
│                                     │
│  % OF BUDGET                        │
│  0.35% of monthly income            │
│                                     │
│  NOTES                              │
│  Shared with partner                │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ☑️ Enabled                         │
│  Disable to exclude from budget     │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Added: Dec 15, 2025                │
│  Modified: Dec 20, 2025             │
│                                     │
│        [Delete Expense]             │
│                                     │
└─────────────────────────────────────┘
```

---

## Calculations

### Total Monthly Expenses

```swift
func calculateTotalMonthlyExpenses(expenses: [Expense]) -> Decimal {
    expenses
        .filter { $0.isEnabled }
        .reduce(0) { $0 + $1.monthlyAmount }
}
```

### Total Annual Expenses

```swift
func calculateTotalAnnualExpenses(expenses: [Expense]) -> Decimal {
    expenses
        .filter { $0.isEnabled }
        .reduce(0) { $0 + $1.annualAmount }
}
```

### Expenses by Category

```swift
func expensesByCategory(
    expenses: [Expense],
    categories: [Category]
) -> [(Category, Decimal)] {
    categories.compactMap { category in
        let total = expenses
            .filter { $0.isEnabled && $0.categoryID == category.id }
            .reduce(0) { $0 + $1.monthlyAmount }
        return total > 0 ? (category, total) : nil
    }
    .sorted { $0.1 > $1.1 }
}
```

### Top Expenses

```swift
func topExpenses(expenses: [Expense], count: Int = 5) -> [Expense] {
    expenses
        .filter { $0.isEnabled }
        .sorted { $0.monthlyAmount > $1.monthlyAmount }
        .prefix(count)
        .map { $0 }
}
```

---

## Validation Rules

| Rule | Validation | Error Message |
|------|------------|---------------|
| Name required | `name.count >= 1` | "Please enter an expense name" |
| Name length | `name.count <= 100` | "Name is too long" |
| Amount required | `amount >= 0` | "Please enter an amount" |
| Amount maximum | `amount <= 10,000,000` | "Amount seems too high" |

**Note:** Amount of 0 is valid (user may want to track a suspended expense).

---

## Foundation Models Integration

### Category Suggestion

When user enters an expense name, FM can suggest a category:

```swift
@Generable
struct ExpenseCategorySuggestion {
    @Guide(description: "The most appropriate category ID for this expense")
    let categoryID: UUID?

    @Guide(description: "Confidence score from 0 to 1", .range(0...1))
    let confidence: Double

    @Guide(description: "Brief reasoning for the suggestion")
    let reasoning: String
}

// Usage
let suggestion = try await session.respond(
    to: "Suggest a category for expense named '\(expenseName)'",
    generating: ExpenseCategorySuggestion.self
)

if suggestion.content.confidence > 0.7 {
    // Auto-select category
} else {
    // Show suggestion but let user confirm
}
```

### Fallback

When FM unavailable:
- No category suggestion
- User manually selects category
- Default to "Uncategorized" if none selected

---

## Implementation Notes

### SwiftData Entity

```swift
// Platform/Persistence/ExpenseEntity.swift
@Model
final class ExpenseEntity {
    var id: UUID
    var name: String
    var amount: Decimal
    var frequency: String  // Raw value
    var category: CategoryEntity?
    var isEnabled: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    func toDomain() -> Expense {
        Expense(
            id: id,
            name: name,
            amount: amount,
            frequency: Frequency(rawValue: frequency) ?? .monthly,
            categoryID: category?.id,
            isEnabled: isEnabled,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

### Repository Protocol

```swift
protocol ExpenseRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Expense]
    func fetchEnabled() async throws -> [Expense]
    func fetchByCategory(_ categoryID: UUID) async throws -> [Expense]
    func save(_ expense: Expense) async throws
    func delete(_ expense: Expense) async throws
    func toggleEnabled(_ expense: Expense) async throws
}
```

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| No expenses entered | Show empty state with "Add your first expense" |
| All expenses disabled | Show 0 total with hint to enable expenses |
| Expense amount is 0 | Allow; useful for tracking suspended subscriptions |
| Very large number of expenses | Virtualized list; consider pagination |
| Duplicate names | Allow; warn user but don't prevent |

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Transaction logging | MVP is planning, not tracking | Phase 2+ |
| Receipt scanning | OCR complexity | Phase 2+ |
| Weekly frequency | Monthly/annual sufficient | Phase 2 |
| Expense splitting | Complexity | Phase 2 |
| Expense history/trends | Nice-to-have | Phase 2 |
| Bulk import | Manual entry first | Phase 2 |

---

## Open Questions

1. **Expense ordering:** Should users be able to reorder expenses, or always sort by amount/category?
   - **Recommendation:** Sort by amount (descending) by default; allow category grouping.

2. **Quick add:** Should there be a quick-add mode for common expenses?
   - **Recommendation:** Phase 2; start with full form.

3. **Recurring vs. one-time:** Should MVP support true one-time expenses, or only recurring?
   - **Recommendation:** Annual frequency covers "yearly one-time" costs; true one-time is Phase 2.

---

## References

- [04-Categories.md](./04-Categories.md) - Category definitions
- [10-BudgetAnalysis.md](./10-BudgetAnalysis.md) - Expense analysis features
- [DesignGuidelines.md](../DesignGuidelines.md) - UI patterns
- Python script `CHELTUIELI_LUNARE` and `CHELTUIELI_ANUALE` dictionaries
