# Categories

## Overview

Categories organize expenses into logical groups for analysis and visualization. Diameris provides sensible default categories based on the Python script's `CATEGORII_CHELTUIELI`, while allowing users to create custom categories. Foundation Models can suggest categories for new expenses when available.

**Key Principle:** Categories are tools for understanding spending patterns, not rigid requirements. Every expense can optionally have a category.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | See default expense categories | I can quickly categorize common expenses |
| User | Create custom categories | I can organize expenses my way |
| User | Assign icons and colors to categories | Categories are visually distinct |
| User | See spending totals by category | I understand where my money goes |
| User | Get category suggestions | Adding expenses is faster |

---

## Category Model

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier |
| `name` | String | Yes | Category name (e.g., "Auto/Transport") |
| `icon` | String | Yes | SF Symbol name |
| `colorHex` | String | Yes | Hex color code |
| `isDefault` | Bool | Yes | Whether this is a system default |
| `sortOrder` | Int | Yes | Display order |
| `createdAt` | Date | Yes | When created |

### Domain Entity

```swift
// Domain/Entities/Category.swift
struct Category: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var icon: String  // SF Symbol name
    var colorHex: String
    var isDefault: Bool
    var sortOrder: Int
    var createdAt: Date

    var color: Color {
        Color(hex: colorHex)
    }
}
```

---

## Default Categories

Based on the Python script's `CATEGORII_CHELTUIELI`:

| Name | SF Symbol | Color | Example Expenses |
|------|-----------|-------|------------------|
| Auto/Transport | `car.fill` | `#3B82F6` (Blue) | Gas, car insurance, maintenance, vehicle tax |
| Subscriptions | `tv.fill` | `#8B5CF6` (Purple) | Netflix, Spotify, iCloud, YouTube Premium |
| Lifestyle | `heart.fill` | `#EC4899` (Pink) | Food, haircuts, random expenses |
| Housing | `house.fill` | `#F59E0B` (Amber) | Rent, utilities |
| Pets | `pawprint.fill` | `#10B981` (Emerald) | Pet food, litter, vet |
| Health/Fitness | `figure.run` | `#06B6D4` (Cyan) | Gym, supplements |

### Default Categories Definition

```swift
extension Category {
    static let defaults: [Category] = [
        Category(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: String(localized: "Auto/Transport"),
            icon: "car.fill",
            colorHex: "#3B82F6",
            isDefault: true,
            sortOrder: 0,
            createdAt: .distantPast
        ),
        Category(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: String(localized: "Subscriptions"),
            icon: "tv.fill",
            colorHex: "#8B5CF6",
            isDefault: true,
            sortOrder: 1,
            createdAt: .distantPast
        ),
        Category(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: String(localized: "Lifestyle"),
            icon: "heart.fill",
            colorHex: "#EC4899",
            isDefault: true,
            sortOrder: 2,
            createdAt: .distantPast
        ),
        Category(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: String(localized: "Housing"),
            icon: "house.fill",
            colorHex: "#F59E0B",
            isDefault: true,
            sortOrder: 3,
            createdAt: .distantPast
        ),
        Category(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: String(localized: "Pets"),
            icon: "pawprint.fill",
            colorHex: "#10B981",
            isDefault: true,
            sortOrder: 4,
            createdAt: .distantPast
        ),
        Category(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: String(localized: "Health/Fitness"),
            icon: "figure.run",
            colorHex: "#06B6D4",
            isDefault: true,
            sortOrder: 5,
            createdAt: .distantPast
        ),
    ]
}
```

---

## UI/UX

### Category List View (Settings or Budget)

```
┌─────────────────────────────────────┐
│  ← Categories                  [+]  │
│                                     │
│  DEFAULT CATEGORIES                 │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🚗 Auto/Transport           │    │
│  │    5 expenses • 3,017 RON   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 📺 Subscriptions            │    │
│  │    6 expenses • 140 RON     │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 💖 Lifestyle                │    │
│  │    4 expenses • 3,465 RON   │    │
│  └─────────────────────────────┘    │
│                                     │
│  ... more default categories ...    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  CUSTOM CATEGORIES                  │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🎮 Gaming                   │    │
│  │    2 expenses • 120 RON     │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Grouped by default vs custom
- Show expense count and total per category
- Color indicator on each row
- Tap to view/edit category
- Swipe to delete (custom only)

### Add/Edit Category Sheet

```
┌─────────────────────────────────────┐
│  Add Category                   ✕   │
│                                     │
│  Name                               │
│  ┌─────────────────────────────┐    │
│  │  Gaming                     │    │
│  └─────────────────────────────┘    │
│                                     │
│  Icon                               │
│  ┌─────────────────────────────┐    │
│  │ 🎮  gamecontroller.fill  ▼  │    │
│  └─────────────────────────────┘    │
│                                     │
│  Color                              │
│  ┌─────────────────────────────┐    │
│  │  ● ● ● ● ● ● ● ●            │    │
│  │  [Selected: Purple]         │    │
│  └─────────────────────────────┘    │
│                                     │
│          [Save Category]            │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Icon picker with SF Symbol search
- Color picker with preset palette
- Preview of category appearance

### Category Picker (in Expense Form)

```
┌─────────────────────────────────────┐
│  Select Category                ✕   │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🔍 Search categories...     │    │
│  └─────────────────────────────┘    │
│                                     │
│  SUGGESTED (if FM available)        │
│  ┌─────────────────────────────┐    │
│  │ ✨ 📺 Subscriptions         │    │
│  │    Based on "Netflix"       │    │
│  └─────────────────────────────┘    │
│                                     │
│  ALL CATEGORIES                     │
│                                     │
│  ○ 🚗 Auto/Transport                │
│  ● 📺 Subscriptions                 │
│  ○ 💖 Lifestyle                     │
│  ○ 🏠 Housing                       │
│  ○ 🐾 Pets                          │
│  ○ 🏃 Health/Fitness                │
│  ○ 🎮 Gaming                        │
│                                     │
│  ─────────────────────────────────  │
│  ○ None (Uncategorized)             │
│                                     │
└─────────────────────────────────────┘
```

---

## Foundation Models Integration

### Category Suggestion

When adding an expense, FM can suggest the most appropriate category:

```swift
@Generable
struct CategorySuggestion {
    @Guide(description: "The suggested category name")
    let categoryName: String

    @Guide(description: "Confidence score from 0 to 1", .range(0...1))
    let confidence: Double
}

// Prompt example
let prompt = """
Given these expense categories: \(categories.map(\.name).joined(separator: ", "))
Suggest the best category for an expense named: "\(expenseName)"
"""

let suggestion = try await session.respond(
    to: prompt,
    generating: CategorySuggestion.self
)
```

### New Category Suggestion

FM can also suggest creating a new category when no existing one fits:

```swift
@Generable
struct NewCategorySuggestion {
    @Guide(description: "Whether a new category should be created")
    let shouldCreateNew: Bool

    @Guide(description: "Suggested new category name")
    let suggestedName: String?

    @Guide(description: "Suggested SF Symbol name")
    let suggestedIcon: String?

    @Guide(description: "Best existing category if not creating new")
    let existingCategoryName: String?
}
```

### Fallback Behavior

When FM unavailable:
- No suggestion shown
- User manually selects from list
- "None" option always available

---

## Calculations

### Category Totals

```swift
func categoryTotals(
    expenses: [Expense],
    categories: [Category]
) -> [CategoryTotal] {
    categories.map { category in
        let expenses = expenses.filter {
            $0.isEnabled && $0.categoryID == category.id
        }
        let monthlyTotal = expenses.reduce(0) { $0 + $1.monthlyAmount }
        return CategoryTotal(
            category: category,
            expenseCount: expenses.count,
            monthlyTotal: monthlyTotal,
            annualTotal: monthlyTotal * 12
        )
    }
    .filter { $0.expenseCount > 0 }
    .sorted { $0.monthlyTotal > $1.monthlyTotal }
}

struct CategoryTotal {
    let category: Category
    let expenseCount: Int
    let monthlyTotal: Decimal
    let annualTotal: Decimal

    var percentageOfTotal: Double {
        // Calculated against total expenses
    }
}
```

### Uncategorized Expenses

```swift
func uncategorizedTotal(expenses: [Expense]) -> Decimal {
    expenses
        .filter { $0.isEnabled && $0.categoryID == nil }
        .reduce(0) { $0 + $1.monthlyAmount }
}
```

---

## Implementation Notes

### SwiftData Entity

```swift
// Platform/Persistence/CategoryEntity.swift
@Model
final class CategoryEntity {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var isDefault: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \ExpenseEntity.category)
    var expenses: [ExpenseEntity] = []

    func toDomain() -> Category {
        Category(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            isDefault: isDefault,
            sortOrder: sortOrder,
            createdAt: createdAt
        )
    }
}
```

### Repository Protocol

```swift
protocol CategoryRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Category]
    func fetchDefaults() async throws -> [Category]
    func fetchCustom() async throws -> [Category]
    func save(_ category: Category) async throws
    func delete(_ category: Category) async throws
    func seedDefaults() async throws
}
```

### Seeding Defaults

On first launch, seed default categories:

```swift
func seedDefaultsIfNeeded() async throws {
    let existing = try await fetchAll()
    if existing.isEmpty {
        for category in Category.defaults {
            try await save(category)
        }
    }
}
```

---

## Validation Rules

| Rule | Validation | Error Message |
|------|------------|---------------|
| Name required | `name.count >= 1` | "Please enter a category name" |
| Name length | `name.count <= 50` | "Category name is too long" |
| Unique name | No duplicates | "A category with this name already exists" |
| Valid icon | SF Symbol exists | "Please select a valid icon" |
| Valid color | Hex format | "Please select a valid color" |

---

## Color Palette

Predefined colors for category picker:

```swift
extension Category {
    static let colorPalette: [(name: String, hex: String)] = [
        ("Red", "#EF4444"),
        ("Orange", "#F97316"),
        ("Amber", "#F59E0B"),
        ("Yellow", "#EAB308"),
        ("Lime", "#84CC16"),
        ("Green", "#22C55E"),
        ("Emerald", "#10B981"),
        ("Teal", "#14B8A6"),
        ("Cyan", "#06B6D4"),
        ("Sky", "#0EA5E9"),
        ("Blue", "#3B82F6"),
        ("Indigo", "#6366F1"),
        ("Violet", "#8B5CF6"),
        ("Purple", "#A855F7"),
        ("Fuchsia", "#D946EF"),
        ("Pink", "#EC4899"),
        ("Rose", "#F43F5E"),
    ]
}
```

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Category budgets/limits | Complexity; basic tracking first | Phase 2 |
| Sub-categories | Keep flat structure for MVP | Phase 2 |
| Category merge | Edge case | Phase 2 |
| Category analytics | Basic totals sufficient | Phase 2 |

---

## Open Questions

1. **Delete behavior:** When deleting a custom category, should expenses become uncategorized or require reassignment?
   - **Recommendation:** Become uncategorized (simpler).

2. **Icon search:** Full SF Symbol search or curated subset?
   - **Recommendation:** Curated subset (~50 relevant icons) for MVP.

3. **Localization:** Should category names be localized or user-defined?
   - **Recommendation:** Default names localized; custom names as entered.

---

## References

- [03-Expenses.md](./03-Expenses.md) - Expense-category relationship
- [10-BudgetAnalysis.md](./10-BudgetAnalysis.md) - Category breakdown analysis
- [DesignGuidelines.md](../DesignGuidelines.md) - Colors and icons
- Python script `CATEGORII_CHELTUIELI` dictionary
