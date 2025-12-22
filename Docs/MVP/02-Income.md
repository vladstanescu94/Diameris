# Income

## Overview

Income tracking is the foundation of budget calculations in Diameris. For MVP, we focus on a single primary income source (monthly salary after taxes). This represents the baseline for all budget allocations, savings calculations, and emergency fund targets.

**MVP Scope:** Single income source, monthly frequency, configurable currency.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | Enter my monthly salary | The app can calculate my budget |
| User | Update my income when it changes | My budget reflects my current situation |
| User | See my income clearly displayed | I understand my starting point |
| User | Choose my currency | Amounts are meaningful to me |

---

## Income Model

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier |
| `name` | String | Yes | Display name (default: "Salary") |
| `amount` | Decimal | Yes | Net monthly amount after taxes |
| `frequency` | Frequency | Yes | Always `.monthly` for MVP |
| `currency` | Currency | Yes | User's selected currency |
| `isActive` | Bool | Yes | Whether income is included in calculations |
| `createdAt` | Date | Yes | When the income was added |
| `updatedAt` | Date | Yes | Last modification date |

### Frequency Enum (MVP)

```swift
enum Frequency: String, Codable, CaseIterable {
    case monthly
    case annual

    var monthlyMultiplier: Decimal {
        switch self {
        case .monthly: return 1
        case .annual: return 1/12
        }
    }

    var annualMultiplier: Decimal {
        switch self {
        case .monthly: return 12
        case .annual: return 1
        }
    }
}
```

### Currency Enum (MVP)

```swift
enum Currency: String, Codable, CaseIterable {
    case ron = "RON"
    case eur = "EUR"
    case usd = "USD"

    var symbol: String {
        switch self {
        case .ron: return "lei"
        case .eur: return "€"
        case .usd: return "$"
        }
    }

    var locale: Locale {
        switch self {
        case .ron: return Locale(identifier: "ro_RO")
        case .eur: return Locale(identifier: "de_DE")
        case .usd: return Locale(identifier: "en_US")
        }
    }
}
```

---

## Data Model (Domain Entity)

```swift
// Domain/Entities/Income.swift
struct Income: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var amount: Decimal
    var frequency: Frequency
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    // Computed properties
    var monthlyAmount: Decimal {
        amount * frequency.monthlyMultiplier
    }

    var annualAmount: Decimal {
        amount * frequency.annualMultiplier
    }
}
```

---

## UI/UX

### Income Display (Dashboard)

```
┌─────────────────────────────────────┐
│  MONTHLY INCOME                     │
│                                     │
│  💰 14,303 RON                      │
│     Salary                          │
│                                     │
│  ≈ 2,878 EUR                        │
│  (at current exchange rate)         │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Prominent display of primary income
- Secondary display of equivalent in alternative currency (nice-to-have)
- Tap to edit

### Edit Income Screen

```
┌─────────────────────────────────────┐
│  ← Edit Income                      │
│                                     │
│  Name                               │
│  ┌─────────────────────────────┐    │
│  │  Salary                     │    │
│  └─────────────────────────────┘    │
│                                     │
│  Amount (after taxes)               │
│  ┌─────────────────────────────┐    │
│  │  RON     │    14,303        │    │
│  └─────────────────────────────┘    │
│                                     │
│  This is your net monthly income,   │
│  after all deductions.              │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  CALCULATIONS BASED ON THIS:        │
│  • Emergency Fund Target: 42,909 RON│
│  • Savings (25%): 2,751 RON/month   │
│                                     │
│            [Save Changes]           │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Show impact of income on other calculations
- Real-time update preview
- Liquid Glass card for the form
- Currency selector integrated with amount field

---

## Calculations

### Monthly Income
The base value used for all calculations:

```swift
func calculateMonthlyIncome(incomes: [Income]) -> Decimal {
    incomes
        .filter { $0.isActive }
        .reduce(0) { $0 + $1.monthlyAmount }
}
```

### Annual Income

```swift
func calculateAnnualIncome(incomes: [Income]) -> Decimal {
    incomes
        .filter { $0.isActive }
        .reduce(0) { $0 + $1.annualAmount }
}
```

### Impact on Other Features

| Feature | How Income is Used |
|---------|-------------------|
| Emergency Fund | Target = 3 × monthly income |
| Savings | Amount = monthly income × savings percentage |
| Budget Analysis | Calculates expense-to-income ratios |
| Transfer Planning | Allocation base |

---

## Validation Rules

| Rule | Validation | Error Message |
|------|------------|---------------|
| Amount required | `amount > 0` | "Please enter your income amount" |
| Reasonable maximum | `amount <= 10,000,000` | "Please enter a valid amount" |
| Name required | `name.count >= 1` | "Please enter a name for this income" |
| Name length | `name.count <= 100` | "Name is too long" |

---

## Implementation Notes

### SwiftData Entity

```swift
// Platform/Persistence/IncomeEntity.swift
@Model
final class IncomeEntity {
    var id: UUID
    var name: String
    var amount: Decimal
    var frequency: String  // Raw value of Frequency enum
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    func toDomain() -> Income {
        Income(
            id: id,
            name: name,
            amount: amount,
            frequency: Frequency(rawValue: frequency) ?? .monthly,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

### Repository Protocol

```swift
// Domain/Repositories/IncomeRepositoryProtocol.swift
protocol IncomeRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Income]
    func fetchActive() async throws -> [Income]
    func save(_ income: Income) async throws
    func delete(_ income: Income) async throws
}
```

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| No income entered | Prompt user to add income; disable calculations |
| Income set to 0 | Allow (user might be unemployed); show warning |
| Income updated mid-month | Recalculate all allocations; show change impact |
| Multiple incomes (future) | Sum all active incomes for calculations |

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Multiple income sources | Complexity; single salary covers most users | Phase 2 |
| Income history | Nice-to-have; not core planning | Phase 2 |
| Biweekly/weekly frequencies | Monthly sufficient for MVP | Phase 2 |
| Tax calculations | Too complex; user enters net amount | Phase 2+ |
| Income projections | Future planning feature | Phase 2+ |

---

## Open Questions

1. **Currency per income vs. global:** Should each income have its own currency, or use global app currency?
   - **Recommendation:** Global currency for MVP (simpler).

2. **Income name:** Should we have a fixed "Salary" or allow custom names?
   - **Recommendation:** Allow custom names (flexibility).

3. **Decimal precision:** How many decimal places for amounts?
   - **Recommendation:** 2 decimal places for display, full precision in storage.

---

## References

- [01-Onboarding.md](./01-Onboarding.md) - Income entry during onboarding
- [05-EmergencyFund.md](./05-EmergencyFund.md) - Emergency fund target calculation
- [07-Savings.md](./07-Savings.md) - Savings calculation
- [Architecture.md](../Architecture.md) - Entity patterns
