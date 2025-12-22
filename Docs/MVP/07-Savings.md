# Savings

## Overview

The savings system calculates how much money to set aside each month based on a configurable percentage of remaining income after expenses. Savings allocation follows a priority system: emergency fund first, then regular savings. The app provides research-backed recommendations for savings rates.

**Key Principle:** Save consistently, prioritize safety (emergency fund), then build wealth (regular savings).

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | Set my savings percentage | I control how much I save |
| User | See recommended savings rates | I have guidance based on best practices |
| User | Understand where savings go | I know emergency vs regular allocation |
| User | See monthly and annual projections | I can plan long-term |
| User | Adjust savings rate easily | I can respond to life changes |

---

## Savings Model

### Settings (User Configurable)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `savingsPercentage` | Double | 0.25 (25%) | Percentage of available income to save |

### Calculated Values

| Value | Calculation | Description |
|-------|-------------|-------------|
| Available for Savings | Income - Expenses | What can potentially be saved |
| Total Savings | Available × Percentage | How much to save |
| To Emergency Fund | min(Total, Emergency Remaining) | Emergency fund priority |
| To Regular Savings | Total - Emergency Allocation | After emergency fund |

---

## Savings Calculation

### Core Formula

```
Available = Monthly Income - Monthly Expenses
Total Savings = Available × Savings Percentage

If Emergency Fund Incomplete:
    Emergency Allocation = min(Total Savings, Emergency Remaining)
    Regular Savings = Total Savings - Emergency Allocation
Else:
    Emergency Allocation = 0
    Regular Savings = Total Savings
```

### Implementation

```swift
struct SavingsCalculation {
    let available: Decimal           // Income - Expenses
    let totalSavings: Decimal        // Available × Percentage
    let toEmergencyFund: Decimal     // Priority allocation
    let toRegularSavings: Decimal    // After emergency fund
    let remaining: Decimal           // Flexible spending

    var savingsRate: Double {
        guard available > 0 else { return 0 }
        return Double(truncating: (totalSavings / available) as NSNumber)
    }
}

func calculateSavings(
    monthlyIncome: Decimal,
    monthlyExpenses: Decimal,
    savingsPercentage: Double,
    emergencyFund: EmergencyFund
) -> SavingsCalculation {
    let available = monthlyIncome - monthlyExpenses
    guard available > 0 else {
        return SavingsCalculation(
            available: available,
            totalSavings: 0,
            toEmergencyFund: 0,
            toRegularSavings: 0,
            remaining: available
        )
    }

    let totalSavings = available * Decimal(savingsPercentage)
    let emergencyRemaining = emergencyFund.remaining(monthlyIncome: monthlyIncome)

    let toEmergency: Decimal
    let toRegular: Decimal

    if emergencyRemaining <= 0 {
        // Emergency fund complete
        toEmergency = 0
        toRegular = totalSavings
    } else if totalSavings >= emergencyRemaining {
        // This month completes emergency fund
        toEmergency = emergencyRemaining
        toRegular = totalSavings - emergencyRemaining
    } else {
        // All goes to emergency fund
        toEmergency = totalSavings
        toRegular = 0
    }

    return SavingsCalculation(
        available: available,
        totalSavings: totalSavings,
        toEmergencyFund: toEmergency,
        toRegularSavings: toRegular,
        remaining: available - totalSavings
    )
}
```

---

## Research-Backed Recommendations

### Savings Rate Guidelines

Based on personal finance best practices:

| Rate | Assessment | Recommendation |
|------|------------|----------------|
| < 10% | Low | Increase if possible; build emergency fund first |
| 10-15% | Moderate | Good start; aim for 20%+ over time |
| 15-20% | Good | Solid savings rate for most people |
| 20-30% | Very Good | Building wealth effectively |
| > 30% | Excellent | Aggressive saver; ensure quality of life |

### Contextual Recommendations

```swift
func savingsRecommendation(currentRate: Double) -> SavingsRecommendation {
    switch currentRate {
    case ..<0.10:
        return SavingsRecommendation(
            assessment: .low,
            message: String(localized: "Your savings rate is below 10%. Try to save at least 10-15% of your income."),
            suggestedRate: 0.15
        )
    case 0.10..<0.15:
        return SavingsRecommendation(
            assessment: .moderate,
            message: String(localized: "Good start! Aim to increase to 20% over time."),
            suggestedRate: 0.20
        )
    case 0.15..<0.20:
        return SavingsRecommendation(
            assessment: .good,
            message: String(localized: "Solid savings rate. You're on track."),
            suggestedRate: nil
        )
    case 0.20..<0.30:
        return SavingsRecommendation(
            assessment: .veryGood,
            message: String(localized: "Excellent! You're building wealth effectively."),
            suggestedRate: nil
        )
    default:
        return SavingsRecommendation(
            assessment: .excellent,
            message: String(localized: "Outstanding savings rate! Make sure you're also enjoying life."),
            suggestedRate: nil
        )
    }
}

struct SavingsRecommendation {
    enum Assessment { case low, moderate, good, veryGood, excellent }
    let assessment: Assessment
    let message: String
    let suggestedRate: Double?
}
```

---

## UI/UX

### Savings Overview (Dashboard)

```
┌─────────────────────────────────────┐
│  MONTHLY SAVINGS                    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │     2,751 RON               │    │
│  │     25% of available        │    │
│  │                             │    │
│  │  ┌───────────────────────┐  │    │
│  │  │ Emergency │  Regular  │  │    │
│  │  │   2,751   │     0     │  │    │
│  │  └───────────────────────┘  │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  💡 All savings going to emergency  │
│     fund until complete.            │
│                                     │
└─────────────────────────────────────┘
```

### Savings with Regular Active

```
┌─────────────────────────────────────┐
│  MONTHLY SAVINGS                    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │     2,751 RON               │    │
│  │     25% of available        │    │
│  │                             │    │
│  │  Emergency Fund: ✓ Complete │    │
│  │                             │    │
│  │  All going to Regular       │    │
│  │  Savings: 2,751 RON         │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  📈 Annual projection: 33,012 RON   │
│                                     │
└─────────────────────────────────────┘
```

### Savings Settings

```
┌─────────────────────────────────────┐
│  ← Savings Settings                 │
│                                     │
│  SAVINGS RATE                       │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │  ──────────●──────────      │    │
│  │         25%                 │    │
│  │                             │    │
│  │  5%                    50%  │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  Monthly: 2,751 RON                 │
│  Annual: 33,012 RON                 │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  RECOMMENDATION                     │
│  ┌─────────────────────────────┐    │
│  │ ✅ Very Good                │    │
│  │                             │    │
│  │ You're saving 25% of your   │    │
│  │ available income. Excellent │    │
│  │ rate for building wealth!   │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  💡 BEST PRACTICES                  │
│                                     │
│  • 50/30/20 Rule: 50% needs,        │
│    30% wants, 20% savings           │
│                                     │
│  • Emergency fund first, then       │
│    regular savings                  │
│                                     │
│  • Increase rate by 1% each year    │
│    to build habit gradually         │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Slider for savings percentage (5% - 50%)
- Real-time calculation update
- Recommendation based on current rate
- Educational content about savings best practices

---

## Annual Projections

### Regular Savings Growth

```swift
func annualSavingsProjection(
    monthlySavings: Decimal,
    months: Int = 12
) -> Decimal {
    monthlySavings * Decimal(months)
}

func multiYearProjection(
    monthlySavings: Decimal,
    years: Int
) -> [YearProjection] {
    (1...years).map { year in
        YearProjection(
            year: year,
            totalSaved: monthlySavings * Decimal(12 * year)
        )
    }
}

struct YearProjection {
    let year: Int
    let totalSaved: Decimal
}
```

---

## Phase 2: Savings Boost (Future)

> **Note:** This feature is deferred to Phase 2 but documented here for context.

The Python script has a "Savings Boost" mode that multiplies the savings rate:

```python
SAVINGS_BOOST = True
SAVINGS_BOOST_MULTIPLIER = 3  # 25% × 3 = 75% savings rate
```

### Future Implementation

```swift
struct SavingsModifier {
    var name: String
    var multiplier: Double
    var isActive: Bool
}

// Example modifiers
let boostMode = SavingsModifier(
    name: "Savings Boost",
    multiplier: 3.0,
    isActive: false
)

// Modified calculation
let effectivePercentage = savingsPercentage * (boostMode.isActive ? boostMode.multiplier : 1.0)
```

---

## Validation Rules

| Rule | Validation | Error Message |
|------|------------|---------------|
| Percentage range | `0.05 <= percentage <= 0.50` | "Savings rate must be between 5% and 50%" |
| Meaningful savings | `available > 0` | "Add income to calculate savings" |

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Expenses > Income | Savings = 0; show warning |
| No income entered | Prompt to add income |
| Very high savings (>50%) | Allow but warn about sustainability |
| Very low savings (<5%) | Allow but show recommendation |

---

## Foundation Models Integration

### Personalized Savings Advice

```swift
@Generable
struct SavingsAdvice {
    @Guide(description: "Brief assessment of the user's savings situation")
    let assessment: String

    @Guide(description: "One specific, actionable recommendation")
    let recommendation: String
}

let prompt = """
User saves \(savingsPercentage * 100)% of available income.
Monthly savings: \(monthlySavings) RON
Emergency fund: \(emergencyComplete ? "Complete" : "\(emergencyProgress)% complete")
Provide brief assessment and one actionable tip.
"""
```

### Fallback

When FM unavailable:
- Use static recommendations based on percentage ranges
- No personalized advice

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Savings Boost modifiers | Complexity; basic percentage sufficient | Phase 2 |
| Investment allocation | Beyond scope of budget app | Phase 2+ |
| Savings history/trends | Nice-to-have | Phase 2 |
| Goal-based savings | Custom goals deferred | Phase 2 |

---

## Open Questions

1. **Default percentage:** Is 25% the right default, or should it be 20%?
   - **Recommendation:** 25% (matches Python script; ambitious but achievable).

2. **Percentage steps:** Slider increments of 1% or 5%?
   - **Recommendation:** 1% increments for fine control.

3. **Savings destination:** Should users specify which account receives regular savings?
   - **Recommendation:** Yes, in [09-TransferPlanning.md](./09-TransferPlanning.md).

---

## References

- [05-EmergencyFund.md](./05-EmergencyFund.md) - Emergency fund priority
- [09-TransferPlanning.md](./09-TransferPlanning.md) - Savings account allocation
- [11-Settings.md](./11-Settings.md) - Savings percentage setting
- Python script `SAVINGS_PERCENTAGE` and `SAVINGS_BOOST` variables
