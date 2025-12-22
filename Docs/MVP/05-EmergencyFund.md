# Emergency Fund

## Overview

The emergency fund is a core financial safety feature in Diameris. It tracks progress toward building a financial cushion equal to 3 months of net income—a widely recommended personal finance practice. The emergency fund has **allocation priority**: savings go to the emergency fund first, then to regular savings once the target is reached.

**Key Principle:** Financial safety before growth. Emergency fund completion unlocks regular savings.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | See my emergency fund progress | I know how secure I am financially |
| User | Know the target amount | I have a clear goal |
| User | Track contributions over time | I see my progress |
| User | Know when it's complete | I can shift focus to other goals |
| User | Understand allocation priority | I know where my savings go |

---

## Emergency Fund Model

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier |
| `currentBalance` | Decimal | Yes | Amount currently saved |
| `targetMultiplier` | Double | Yes | Multiplier for target (default: 3) |
| `lastUpdated` | Date | Yes | When balance was last updated |
| `createdAt` | Date | Yes | When tracking started |

### Domain Entity

```swift
// Domain/Entities/EmergencyFund.swift
struct EmergencyFund: Identifiable, Equatable, Sendable {
    let id: UUID
    var currentBalance: Decimal
    var targetMultiplier: Double  // Default: 3.0
    var lastUpdated: Date
    var createdAt: Date

    // Target is calculated based on monthly income
    func target(monthlyIncome: Decimal) -> Decimal {
        monthlyIncome * Decimal(targetMultiplier)
    }

    func progress(monthlyIncome: Decimal) -> Double {
        let target = target(monthlyIncome: monthlyIncome)
        guard target > 0 else { return 0 }
        return min(1.0, Double(truncating: (currentBalance / target) as NSNumber))
    }

    func isComplete(monthlyIncome: Decimal) -> Bool {
        currentBalance >= target(monthlyIncome: monthlyIncome)
    }

    func remaining(monthlyIncome: Decimal) -> Decimal {
        max(0, target(monthlyIncome: monthlyIncome) - currentBalance)
    }
}
```

---

## Target Calculation

### Default Target: 3x Monthly Income

```
Target = Monthly Net Income × 3

Example:
Monthly Income: 14,303 RON
Target: 14,303 × 3 = 42,909 RON
```

**Why 3 months?**
- Industry-standard recommendation for financial security
- Covers most unexpected expenses or job loss scenarios
- Achievable goal for most income levels

### Customization (Settings)

Users can adjust the multiplier in Settings:
- Minimum: 1x (1 month)
- Default: 3x (3 months)
- Maximum: 12x (1 year)

---

## Allocation Priority Logic

The emergency fund has **first priority** for savings allocation:

```swift
func allocateSavings(
    availableSavings: Decimal,
    emergencyFund: EmergencyFund,
    monthlyIncome: Decimal
) -> SavingsAllocation {
    let remaining = emergencyFund.remaining(monthlyIncome: monthlyIncome)

    if remaining <= 0 {
        // Emergency fund complete - all goes to regular savings
        return SavingsAllocation(
            toEmergencyFund: 0,
            toRegularSavings: availableSavings,
            emergencyFundComplete: true
        )
    } else if availableSavings >= remaining {
        // This month completes the emergency fund
        return SavingsAllocation(
            toEmergencyFund: remaining,
            toRegularSavings: availableSavings - remaining,
            emergencyFundComplete: true  // Will be complete after this allocation
        )
    } else {
        // All savings go to emergency fund
        return SavingsAllocation(
            toEmergencyFund: availableSavings,
            toRegularSavings: 0,
            emergencyFundComplete: false
        )
    }
}

struct SavingsAllocation {
    let toEmergencyFund: Decimal
    let toRegularSavings: Decimal
    let emergencyFundComplete: Bool
}
```

---

## UI/UX

### Emergency Fund Card (Dashboard/Goals)

```
┌─────────────────────────────────────┐
│  EMERGENCY FUND                     │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │      [Progress Ring]        │    │
│  │         86.3%               │    │
│  │                             │    │
│  │    37,056 / 42,909 RON      │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  Target: 3× monthly income          │
│                                     │
│  5,853 RON remaining                │
│  ~2.1 months to complete            │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Prominent progress ring (Liquid Glass)
- Show percentage, current/target amounts
- Time to completion estimate
- Tap for detail view

### Emergency Fund Complete State

```
┌─────────────────────────────────────┐
│  EMERGENCY FUND                     │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │      [Checkmark Ring]       │    │
│  │          ✓                  │    │
│  │       COMPLETE              │    │
│  │                             │    │
│  │    42,909 / 42,909 RON      │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  🎉 Great job! Your emergency       │
│     fund is fully funded.           │
│                                     │
│  Savings now go to regular          │
│  savings account.                   │
│                                     │
└─────────────────────────────────────┘
```

### Emergency Fund Detail View

```
┌─────────────────────────────────────┐
│  ← Emergency Fund                   │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │    [Large Progress Ring]    │    │
│  │         86.3%               │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  CURRENT BALANCE                    │
│  37,056 RON                         │
│                                     │
│  TARGET (3× income)                 │
│  42,909 RON                         │
│                                     │
│  REMAINING                          │
│  5,853 RON                          │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  MONTHLY CONTRIBUTION               │
│  2,751 RON (from savings)           │
│                                     │
│  ESTIMATED COMPLETION               │
│  ~2.1 months (February 2026)        │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  💡 WHY 3 MONTHS?                   │
│  Financial experts recommend        │
│  3-6 months of expenses as an       │
│  emergency cushion for unexpected   │
│  costs or job loss.                 │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Update Balance                     │
│  ┌─────────────────────────────┐    │
│  │  37,056 RON              [✓]│    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Large progress visualization
- Clear breakdown of numbers
- Educational content about why emergency funds matter
- Manual balance update (since we don't track actual transactions)

---

## Calculations

### Time to Completion

```swift
func monthsToComplete(
    emergencyFund: EmergencyFund,
    monthlyContribution: Decimal,
    monthlyIncome: Decimal
) -> Double? {
    let remaining = emergencyFund.remaining(monthlyIncome: monthlyIncome)
    guard remaining > 0, monthlyContribution > 0 else { return nil }
    return Double(truncating: (remaining / monthlyContribution) as NSNumber)
}
```

### Monthly Contribution

```swift
func monthlyContribution(
    monthlyIncome: Decimal,
    monthlyExpenses: Decimal,
    savingsPercentage: Double,
    emergencyFund: EmergencyFund
) -> Decimal {
    let availableForSavings = monthlyIncome - monthlyExpenses
    let totalSavings = availableForSavings * Decimal(savingsPercentage)

    if emergencyFund.isComplete(monthlyIncome: monthlyIncome) {
        return 0  // No more contributions needed
    }

    let remaining = emergencyFund.remaining(monthlyIncome: monthlyIncome)
    return min(totalSavings, remaining)
}
```

---

## Implementation Notes

### SwiftData Entity

```swift
// Platform/Persistence/EmergencyFundEntity.swift
@Model
final class EmergencyFundEntity {
    var id: UUID
    var currentBalance: Decimal
    var targetMultiplier: Double
    var lastUpdated: Date
    var createdAt: Date

    func toDomain() -> EmergencyFund {
        EmergencyFund(
            id: id,
            currentBalance: currentBalance,
            targetMultiplier: targetMultiplier,
            lastUpdated: lastUpdated,
            createdAt: createdAt
        )
    }
}
```

### Repository Protocol

```swift
protocol EmergencyFundRepositoryProtocol: Sendable {
    func fetch() async throws -> EmergencyFund?
    func save(_ fund: EmergencyFund) async throws
    func updateBalance(_ newBalance: Decimal) async throws
}
```

### Initial Setup

On first launch, create emergency fund with:
- `currentBalance`: 0 (or user can enter existing amount)
- `targetMultiplier`: 3.0
- `lastUpdated`: now
- `createdAt`: now

---

## State Transitions

```
┌──────────────────┐
│   Not Started    │  currentBalance = 0
│    (0%)          │
└────────┬─────────┘
         │ User adds first contribution
         ▼
┌──────────────────┐
│   In Progress    │  0 < currentBalance < target
│   (1% - 99%)     │
└────────┬─────────┘
         │ currentBalance >= target
         ▼
┌──────────────────┐
│    Complete      │  currentBalance >= target
│    (100%)        │  Regular savings activated
└──────────────────┘
```

---

## Milestone Celebrations

When emergency fund reaches certain milestones, celebrate:

| Milestone | Message | Haptic |
|-----------|---------|--------|
| 25% | "Quarter of the way there!" | `.impact(weight: .light)` |
| 50% | "Halfway to financial security!" | `.impact(weight: .medium)` |
| 75% | "Almost there! Keep going!" | `.impact(weight: .medium)` |
| 100% | "Emergency fund complete!" | `.success` |

---

## Foundation Models Integration

### Progress Insights

FM can provide personalized encouragement:

```swift
@Generable
struct EmergencyFundInsight {
    @Guide(description: "A brief, encouraging message about the user's progress")
    let message: String

    @Guide(description: "A specific, actionable tip")
    let tip: String?
}

let prompt = """
User has \(progress)% of their emergency fund complete.
Current: \(current) RON, Target: \(target) RON.
Provide brief encouragement and an optional tip.
"""
```

### Fallback

When FM unavailable:
- Use static messages based on progress percentage
- No personalized insights

---

## Validation Rules

| Rule | Validation | Error Message |
|------|------------|---------------|
| Balance non-negative | `currentBalance >= 0` | "Balance cannot be negative" |
| Reasonable balance | `currentBalance <= 100,000,000` | "Please enter a valid amount" |
| Valid multiplier | `1 <= multiplier <= 12` | "Multiplier must be between 1 and 12" |

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Contribution history | Manual balance update sufficient | Phase 2 |
| Automatic updates | No bank integration | Phase 2+ |
| Multiple emergency funds | Single fund sufficient | Phase 2 |
| Custom target amount | Multiplier-based simpler | Phase 2 |

---

## Open Questions

1. **Initial balance prompt:** Should onboarding ask for existing emergency fund balance?
   - **Recommendation:** Yes, optional step in onboarding or first Goals view.

2. **Over-funded:** What if balance exceeds target?
   - **Recommendation:** Show as 100%+ complete; suggest moving excess to regular savings.

3. **Income changes:** When income changes, target changes. How to handle?
   - **Recommendation:** Recalculate target dynamically; show clear messaging about target change.

---

## References

- [07-Savings.md](./07-Savings.md) - Savings allocation logic
- [09-TransferPlanning.md](./09-TransferPlanning.md) - Emergency fund in transfer plan
- [10-BudgetAnalysis.md](./10-BudgetAnalysis.md) - Emergency fund health metrics
- Python script `FOND_URGENTA_*` variables and logic
