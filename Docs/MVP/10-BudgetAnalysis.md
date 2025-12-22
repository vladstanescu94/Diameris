# Budget Analysis

## Overview

Budget Analysis provides intelligent insights and recommendations about the user's financial situation. It replicates the Python script's `analiza_optimizari()` function, offering benchmarks, health indicators, optimization suggestions, and scenario comparisons. Foundation Models enhance analysis with personalized recommendations when available, with deterministic fallbacks.

**Key Principle:** Don't just show numbers—help users understand what they mean and what to do about them.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | See how my budget compares to benchmarks | I know if I'm on track |
| User | Get specific optimization suggestions | I can improve my finances |
| User | Understand my income distribution | I see where my money goes |
| User | See a health score or assessment | I have a quick summary |
| User | View top expenses | I know what to focus on |
| User | See scenario projections | I can plan for changes |

---

## Analysis Components

### 1. Income Distribution

Show how income is allocated across categories:

```swift
struct IncomeDistribution {
    let expenses: DistributionItem
    let savings: DistributionItem
    let flexible: DistributionItem

    struct DistributionItem {
        let amount: Decimal
        let percentage: Double
        let benchmark: BenchmarkStatus
    }

    enum BenchmarkStatus {
        case good, warning, critical
    }
}

func calculateDistribution(
    income: Decimal,
    expenses: Decimal,
    savings: Decimal
) -> IncomeDistribution {
    let flexible = income - expenses - savings

    let expensePercent = Double(truncating: (expenses / income) as NSNumber) * 100
    let savingsPercent = Double(truncating: (savings / income) as NSNumber) * 100
    let flexiblePercent = Double(truncating: (flexible / income) as NSNumber) * 100

    return IncomeDistribution(
        expenses: DistributionItem(
            amount: expenses,
            percentage: expensePercent,
            benchmark: expensePercent > 70 ? .critical : expensePercent > 50 ? .warning : .good
        ),
        savings: DistributionItem(
            amount: savings,
            percentage: savingsPercent,
            benchmark: savingsPercent < 10 ? .critical : savingsPercent < 20 ? .warning : .good
        ),
        flexible: DistributionItem(
            amount: flexible,
            percentage: flexiblePercent,
            benchmark: flexiblePercent < 10 ? .warning : .good
        )
    )
}
```

### 2. Financial Benchmarks

Standard benchmarks from personal finance best practices:

| Metric | Recommended | Warning | Critical |
|--------|-------------|---------|----------|
| Savings Rate | ≥20% | 10-20% | <10% |
| Expense Ratio | ≤50% | 50-70% | >70% |
| Flexible Spending | ≥10% | 5-10% | <5% |
| Emergency Fund | 100% | 50-99% | <50% |
| Transport Costs | ≤20% of income | 20-25% | >25% |

```swift
struct BenchmarkAnalysis {
    let savingsRate: BenchmarkResult
    let expenseRatio: BenchmarkResult
    let flexibleSpending: BenchmarkResult
    let emergencyFund: BenchmarkResult
    let transportCosts: BenchmarkResult

    struct BenchmarkResult {
        let value: Double
        let status: Status
        let recommendation: String?

        enum Status: String {
            case excellent = "Excellent"
            case good = "Good"
            case warning = "Needs Attention"
            case critical = "Critical"
        }
    }
}
```

### 3. Top Expenses

Ranked list of highest expenses:

```swift
struct TopExpense {
    let expense: Expense
    let monthlyAmount: Decimal
    let percentageOfExpenses: Double
    let percentageOfIncome: Double
}

func topExpenses(
    expenses: [Expense],
    count: Int = 5
) -> [TopExpense] {
    let totalExpenses = expenses.reduce(0) { $0 + $1.monthlyAmount }
    let income = /* from income repository */

    return expenses
        .filter { $0.isEnabled }
        .sorted { $0.monthlyAmount > $1.monthlyAmount }
        .prefix(count)
        .map { expense in
            TopExpense(
                expense: expense,
                monthlyAmount: expense.monthlyAmount,
                percentageOfExpenses: Double(truncating: (expense.monthlyAmount / totalExpenses) as NSNumber) * 100,
                percentageOfIncome: Double(truncating: (expense.monthlyAmount / income) as NSNumber) * 100
            )
        }
}
```

### 4. Category Breakdown

Spending by category with insights:

```swift
struct CategoryBreakdown {
    let category: Category
    let monthlyTotal: Decimal
    let annualTotal: Decimal
    let percentageOfExpenses: Double
    let percentageOfIncome: Double
    let expenseCount: Int
    let insight: String?  // FM-generated or static
}
```

### 5. Optimization Recommendations

Actionable suggestions based on analysis:

```swift
enum RecommendationPriority {
    case high, medium, low
}

struct Recommendation {
    let priority: RecommendationPriority
    let title: String
    let description: String
    let potentialSavings: Decimal?
    let actionable: Bool
}

func generateRecommendations(analysis: BudgetAnalysis) -> [Recommendation] {
    var recommendations: [Recommendation] = []

    // Emergency fund priority
    if analysis.emergencyFundProgress < 0.5 {
        recommendations.append(Recommendation(
            priority: .high,
            title: String(localized: "Build Emergency Fund"),
            description: String(localized: "Your emergency fund is below 50%. Focus on building this safety net."),
            potentialSavings: nil,
            actionable: true
        ))
    }

    // Low savings rate
    if analysis.savingsRate < 0.10 {
        recommendations.append(Recommendation(
            priority: .high,
            title: String(localized: "Increase Savings Rate"),
            description: String(localized: "Saving less than 10% puts long-term goals at risk. Aim for 15-20%."),
            potentialSavings: nil,
            actionable: true
        ))
    }

    // High food spending
    if let foodCategory = analysis.categoryBreakdown.first(where: { $0.category.name.contains("Food") }),
       foodCategory.monthlyTotal > 2500 {
        let potential = foodCategory.monthlyTotal - 2500
        recommendations.append(Recommendation(
            priority: .medium,
            title: String(localized: "Optimize Food Spending"),
            description: String(localized: "Food costs are high. Meal planning could save 300-500 RON/month."),
            potentialSavings: min(potential, 500),
            actionable: true
        ))
    }

    // Subscription audit
    if let subsCategory = analysis.categoryBreakdown.first(where: { $0.category.name.contains("Subscription") }),
       subsCategory.monthlyTotal > 300 {
        recommendations.append(Recommendation(
            priority: .low,
            title: String(localized: "Review Subscriptions"),
            description: String(localized: "Subscriptions total \(subsCategory.monthlyTotal) RON/month. Audit for unused services."),
            potentialSavings: 100,
            actionable: true
        ))
    }

    return recommendations.sorted { $0.priority.rawValue < $1.priority.rawValue }
}
```

---

## UI/UX

### Budget Analysis Screen (Dashboard or Dedicated)

```
┌─────────────────────────────────────┐
│  Budget Analysis                    │
│                                     │
│  BUDGET HEALTH                      │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │     [Health Score Ring]     │    │
│  │          Good               │    │
│  │          78/100             │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  INCOME DISTRIBUTION                │
│  ┌─────────────────────────────┐    │
│  │ ████████████████░░░░░░░░    │    │
│  │ Expenses    Savings  Flex   │    │
│  │   52%        25%     23%    │    │
│  │  7,437     3,576   3,290    │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  BENCHMARKS                         │
│  ┌─────────────────────────────┐    │
│  │ ✅ Savings Rate: 25%        │    │
│  │    Recommended: ≥20%        │    │
│  │                             │    │
│  │ ✅ Expense Ratio: 52%       │    │
│  │    Recommended: ≤50%        │    │
│  │                             │    │
│  │ ⚠️ Emergency Fund: 86%      │    │
│  │    Target: 100%             │    │
│  │                             │    │
│  │ ✅ Transport: 18%           │    │
│  │    Recommended: ≤20%        │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  TOP 5 EXPENSES                     │
│  ┌─────────────────────────────┐    │
│  │ 1. Food          3,000  21% │    │
│  │ 2. Car Loan      2,850  20% │    │
│  │ 3. Gas             300   2% │    │
│  │ 4. Gym             200   1% │    │
│  │ 5. Subscriptions   140   1% │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  RECOMMENDATIONS                    │
│  ┌─────────────────────────────┐    │
│  │ 🔴 HIGH PRIORITY            │    │
│  │                             │    │
│  │ Complete Emergency Fund     │    │
│  │ You're at 86%. Add 5,853    │    │
│  │ RON to reach your target.   │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🟡 MEDIUM PRIORITY          │    │
│  │                             │    │
│  │ Optimize Food Spending      │    │
│  │ At 3,000 RON/month, meal    │    │
│  │ prep could save ~400 RON.   │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🟢 SUGGESTIONS              │    │
│  │                             │    │
│  │ Review Subscriptions        │    │
│  │ 140 RON/month. Check if     │    │
│  │ all services are used.      │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

### Quick Summary Card (Dashboard)

```
┌─────────────────────────────────────┐
│  💰 QUICK SUMMARY                   │
│                                     │
│  Income: 14,303 RON                 │
│  Expenses: 7,437 RON (52%)          │
│  Savings: 3,576 RON (25%)           │
│  Remaining: 3,290 RON               │
│                                     │
│  Emergency Fund: ████████░░ 86%     │
│                                     │
│  🚗 Car loan ends in 19 months      │
│     +2,850 RON/month freed up!      │
│                                     │
└─────────────────────────────────────┘
```

---

## Foundation Models Integration

### Personalized Analysis

FM generates personalized insights based on the full budget context:

```swift
@Generable
struct PersonalizedAnalysis {
    @Guide(description: "A 2-3 sentence overall assessment of the budget")
    let overallAssessment: String

    @Guide(description: "The single most important recommendation")
    let topRecommendation: String

    @Guide(description: "One positive observation about the user's finances")
    let positiveNote: String

    @Guide(description: "Estimated monthly savings potential if recommendations followed", .range(0...10000))
    let savingsPotential: Double?
}

let prompt = """
Analyze this budget:
- Monthly income: \(income) RON
- Monthly expenses: \(expenses) RON (\(expensePercent)%)
- Monthly savings: \(savings) RON (\(savingsPercent)%)
- Emergency fund: \(emergencyProgress)% complete
- Top expenses: \(topExpensesList)
- Loan payments: \(loanTotal) RON/month

Provide personalized analysis.
"""
```

### Optimization Suggestions

FM can identify specific optimization opportunities:

```swift
@Generable
struct OptimizationSuggestion {
    @Guide(description: "Specific area to optimize")
    let area: String

    @Guide(description: "Concrete action to take")
    let action: String

    @Guide(description: "Estimated monthly savings", .range(0...5000))
    let estimatedSavings: Double

    @Guide(description: "Difficulty level", .anyOf(["Easy", "Medium", "Hard"]))
    let difficulty: String
}
```

### Fallback Behavior

When FM unavailable:
- Use rule-based recommendations (as shown in `generateRecommendations`)
- Static benchmark comparisons
- No personalized narrative text

---

## Health Score Calculation

### Composite Score (0-100)

```swift
func calculateHealthScore(analysis: BudgetAnalysis) -> Int {
    var score = 0

    // Savings rate (max 30 points)
    switch analysis.savingsRate {
    case 0.30...: score += 30
    case 0.20..<0.30: score += 25
    case 0.15..<0.20: score += 20
    case 0.10..<0.15: score += 15
    default: score += 5
    }

    // Emergency fund (max 25 points)
    switch analysis.emergencyFundProgress {
    case 1.0...: score += 25
    case 0.75..<1.0: score += 20
    case 0.50..<0.75: score += 15
    case 0.25..<0.50: score += 10
    default: score += 5
    }

    // Expense ratio (max 25 points)
    switch analysis.expenseRatio {
    case ..<0.50: score += 25
    case 0.50..<0.60: score += 20
    case 0.60..<0.70: score += 15
    default: score += 5
    }

    // Flexible spending (max 20 points)
    switch analysis.flexiblePercent {
    case 0.20...: score += 20
    case 0.15..<0.20: score += 15
    case 0.10..<0.15: score += 10
    default: score += 5
    }

    return min(100, score)
}

func healthScoreLabel(_ score: Int) -> String {
    switch score {
    case 90...: return String(localized: "Excellent")
    case 75..<90: return String(localized: "Good")
    case 60..<75: return String(localized: "Fair")
    case 40..<60: return String(localized: "Needs Work")
    default: return String(localized: "Critical")
    }
}
```

---

## Implementation Notes

### Use Case

```swift
// UseCases/AnalyzeBudgetUseCase.swift
protocol AnalyzeBudgetUseCaseProtocol {
    func execute() async throws -> BudgetAnalysis
}

struct BudgetAnalysis {
    let incomeDistribution: IncomeDistribution
    let benchmarks: BenchmarkAnalysis
    let topExpenses: [TopExpense]
    let categoryBreakdown: [CategoryBreakdown]
    let recommendations: [Recommendation]
    let healthScore: Int
    let personalizedInsight: String?  // FM-generated
}
```

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Historical trends | No transaction history | Phase 2 |
| Comparison to previous months | Requires history | Phase 2 |
| Peer comparison | Privacy concerns; complexity | Phase 2+ |
| Scenario simulation | Basic projections only | Phase 2 |
| Export/share analysis | Nice-to-have | Phase 2 |

---

## Open Questions

1. **Health score visibility:** Should health score be prominent or subtle?
   - **Recommendation:** Prominent on dashboard; motivational.

2. **Recommendation frequency:** How often to show recommendations?
   - **Recommendation:** Always available; highlight changes.

3. **FM prompt optimization:** How to balance prompt size vs. quality?
   - **Recommendation:** Include key metrics only; iterate based on results.

---

## References

- [03-Expenses.md](./03-Expenses.md) - Expense data for analysis
- [04-Categories.md](./04-Categories.md) - Category breakdown
- [05-EmergencyFund.md](./05-EmergencyFund.md) - Emergency fund metrics
- [07-Savings.md](./07-Savings.md) - Savings rate benchmarks
- [FoundationModels-Using-on-device-LLM.md](../FoundationModels-Using-on-device-LLM.md) - FM integration
- Python script `analiza_optimizari()` and `quick_summary()` functions
