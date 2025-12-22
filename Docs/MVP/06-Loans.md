# Loans

## Overview

Loan tracking helps users understand how debt impacts their monthly budget and plan for payoff. Users can define any type of loan (car, personal, mortgage, etc.) with basic details. The app calculates remaining payments, estimated payoff date, and shows the future budget impact when loans are paid off.

**Key Principle:** Loans are a significant budget item. Understanding payoff timelines motivates users and helps them plan for freed-up income.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | Add my loans with balance and payment | My budget reflects debt obligations |
| User | See remaining payments and payoff date | I know when I'll be debt-free |
| User | Understand budget impact after payoff | I can plan for freed-up money |
| User | Track multiple loans | All my debts are visible |
| User | Update loan balance over time | My data stays accurate |

---

## Loan Model

### Core Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | UUID | Yes | Unique identifier |
| `name` | String | Yes | Descriptive name (e.g., "Car Loan") |
| `originalAmount` | Decimal | No | Initial loan amount (for reference) |
| `remainingBalance` | Decimal | Yes | Current balance owed |
| `monthlyPayment` | Decimal | Yes | Fixed monthly payment |
| `interestRate` | Double? | No | Annual interest rate (optional) |
| `startDate` | Date? | No | When the loan started |
| `notes` | String? | No | User notes |
| `createdAt` | Date | Yes | When added to app |
| `updatedAt` | Date | Yes | Last modification |

### Domain Entity

```swift
// Domain/Entities/Loan.swift
struct Loan: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var originalAmount: Decimal?
    var remainingBalance: Decimal
    var monthlyPayment: Decimal
    var interestRate: Double?
    var startDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    // Calculated properties
    var remainingPayments: Int {
        guard monthlyPayment > 0 else { return 0 }
        return Int(ceil(Double(truncating: (remainingBalance / monthlyPayment) as NSNumber)))
    }

    var remainingMonths: Double {
        guard monthlyPayment > 0 else { return 0 }
        return Double(truncating: (remainingBalance / monthlyPayment) as NSNumber)
    }

    var estimatedPayoffDate: Date {
        Calendar.current.date(
            byAdding: .month,
            value: remainingPayments,
            to: Date()
        ) ?? Date()
    }

    var annualPayment: Decimal {
        monthlyPayment * 12
    }

    var isActive: Bool {
        remainingBalance > 0
    }
}
```

---

## Example: Car Loan (from Python Script)

```
Name: Car Loan
Remaining Balance: 52,800.68 RON
Monthly Payment: 2,850 RON
Interest Rate: (optional)

Calculated:
- Remaining Payments: 19 months
- Estimated Payoff: July 2027
- Annual Payment: 34,200 RON
```

---

## UI/UX

### Loans List (Goals Tab)

```
┌─────────────────────────────────────┐
│  LOANS                         [+]  │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🚗 Car Loan                 │    │
│  │                             │    │
│  │ 52,801 RON remaining        │    │
│  │ 2,850 RON/month             │    │
│  │                             │    │
│  │ ████████████░░░░ 19 months  │    │
│  │ Payoff: July 2027           │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🏠 Personal Loan            │    │
│  │                             │    │
│  │ 15,000 RON remaining        │    │
│  │ 500 RON/month               │    │
│  │                             │    │
│  │ ████░░░░░░░░░░░░ 30 months  │    │
│  │ Payoff: June 2028           │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  TOTAL MONTHLY PAYMENTS             │
│  3,350 RON                          │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Progress bar showing time remaining
- Clear payoff date
- Total monthly payments summary
- Tap for detail view

### Add/Edit Loan Sheet

```
┌─────────────────────────────────────┐
│  Add Loan                       ✕   │
│                                     │
│  Name                               │
│  ┌─────────────────────────────┐    │
│  │  Car Loan                   │    │
│  └─────────────────────────────┘    │
│                                     │
│  Remaining Balance                  │
│  ┌─────────────────────────────┐    │
│  │  RON      │    52,800.68    │    │
│  └─────────────────────────────┘    │
│                                     │
│  Monthly Payment                    │
│  ┌─────────────────────────────┐    │
│  │  RON      │    2,850        │    │
│  └─────────────────────────────┘    │
│                                     │
│  OPTIONAL DETAILS                   │
│                                     │
│  Interest Rate (annual)             │
│  ┌─────────────────────────────┐    │
│  │         │    8.5   %        │    │
│  └─────────────────────────────┘    │
│                                     │
│  Original Amount                    │
│  ┌─────────────────────────────┐    │
│  │  RON      │    75,000       │    │
│  └─────────────────────────────┘    │
│                                     │
│  Notes                              │
│  ┌─────────────────────────────┐    │
│  │  Includes insurance         │    │
│  └─────────────────────────────┘    │
│                                     │
│            [Save Loan]              │
│                                     │
└─────────────────────────────────────┘
```

### Loan Detail View

```
┌─────────────────────────────────────┐
│  ← Car Loan                  [Edit] │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │    [Countdown Ring]         │    │
│  │      19 months              │    │
│  │      remaining              │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  BALANCE                            │
│  52,800.68 RON                      │
│                                     │
│  MONTHLY PAYMENT                    │
│  2,850 RON                          │
│                                     │
│  ANNUAL PAYMENT                     │
│  34,200 RON                         │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  PAYOFF TIMELINE                    │
│  Estimated: July 2027               │
│  Remaining payments: 19             │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  💰 AFTER PAYOFF                    │
│                                     │
│  When this loan is paid off,        │
│  you'll have +2,850 RON/month       │
│  freed up for savings!              │
│                                     │
│  Potential extra savings:           │
│  +34,200 RON/year                   │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  Update Balance                     │
│  ┌─────────────────────────────┐    │
│  │  52,800.68 RON           [✓]│    │
│  └─────────────────────────────┘    │
│                                     │
│        [Mark as Paid Off]           │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Countdown visualization
- Clear payoff projection
- Post-payoff benefit highlighted
- Quick balance update
- Option to mark as paid off

---

## Calculations

### Remaining Months (Simple)

For MVP, we use simple division (ignoring interest compounding):

```swift
func remainingMonths(balance: Decimal, monthlyPayment: Decimal) -> Double {
    guard monthlyPayment > 0 else { return 0 }
    return Double(truncating: (balance / monthlyPayment) as NSNumber)
}
```

### Estimated Payoff Date

```swift
func estimatedPayoffDate(remainingMonths: Double) -> Date {
    let months = Int(ceil(remainingMonths))
    return Calendar.current.date(
        byAdding: .month,
        value: months,
        to: Date()
    ) ?? Date()
}
```

### Total Monthly Loan Payments

```swift
func totalMonthlyLoanPayments(loans: [Loan]) -> Decimal {
    loans
        .filter { $0.isActive }
        .reduce(0) { $0 + $1.monthlyPayment }
}
```

### Post-Payoff Savings Potential

```swift
func postPayoffSavingsPotential(loan: Loan) -> (monthly: Decimal, annual: Decimal) {
    (
        monthly: loan.monthlyPayment,
        annual: loan.monthlyPayment * 12
    )
}
```

---

## Budget Integration

### Loan Payments as Expenses

Loan payments are typically included in the expense calculations:

```swift
// Option 1: Auto-create expense for each loan
func createExpenseFromLoan(_ loan: Loan) -> Expense {
    Expense(
        id: UUID(),
        name: "\(loan.name) Payment",
        amount: loan.monthlyPayment,
        frequency: .monthly,
        categoryID: autoCategory?.id,  // "Auto/Transport" or similar
        isEnabled: true,
        notes: "Auto-generated from loan",
        createdAt: Date(),
        updatedAt: Date()
    )
}

// Option 2: Separate loan payments in calculations
func totalMonthlyObligations(
    expenses: [Expense],
    loans: [Loan]
) -> Decimal {
    let expenseTotal = expenses.filter(\.isEnabled).reduce(0) { $0 + $1.monthlyAmount }
    let loanTotal = loans.filter(\.isActive).reduce(0) { $0 + $1.monthlyPayment }
    return expenseTotal + loanTotal
}
```

**Decision:** For MVP, use Option 2—keep loans separate from expenses in calculations, but show combined total where relevant.

---

## State Transitions

```
┌──────────────────┐
│     Active       │  remainingBalance > 0
│                  │  Counted in monthly obligations
└────────┬─────────┘
         │ remainingBalance = 0 or marked paid off
         ▼
┌──────────────────┐
│    Paid Off      │  remainingBalance = 0
│                  │  🎉 Celebration!
│                  │  Removed from obligations
└──────────────────┘
```

### Payoff Celebration

When a loan is paid off:
- Show celebration animation/haptic
- Highlight freed-up monthly amount
- Suggest redirecting to savings

---

## Implementation Notes

### SwiftData Entity

```swift
// Platform/Persistence/LoanEntity.swift
@Model
final class LoanEntity {
    var id: UUID
    var name: String
    var originalAmount: Decimal?
    var remainingBalance: Decimal
    var monthlyPayment: Decimal
    var interestRate: Double?
    var startDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    func toDomain() -> Loan {
        Loan(
            id: id,
            name: name,
            originalAmount: originalAmount,
            remainingBalance: remainingBalance,
            monthlyPayment: monthlyPayment,
            interestRate: interestRate,
            startDate: startDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
```

### Repository Protocol

```swift
protocol LoanRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Loan]
    func fetchActive() async throws -> [Loan]
    func save(_ loan: Loan) async throws
    func delete(_ loan: Loan) async throws
    func updateBalance(_ loan: Loan, newBalance: Decimal) async throws
    func markAsPaidOff(_ loan: Loan) async throws
}
```

---

## Validation Rules

| Rule | Validation | Error Message |
|------|------------|---------------|
| Name required | `name.count >= 1` | "Please enter a loan name" |
| Balance non-negative | `remainingBalance >= 0` | "Balance cannot be negative" |
| Payment positive | `monthlyPayment > 0` | "Monthly payment must be greater than 0" |
| Interest rate valid | `0 <= rate <= 100` | "Interest rate must be between 0% and 100%" |

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| No loans | Show empty state with "No active loans" |
| Balance updated to 0 | Prompt to mark as paid off |
| Payment > Balance | Remaining payments = 1 |
| Very long payoff (>10 years) | Show years instead of months |

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Amortization schedule | Complex; simple payoff sufficient | Phase 2 |
| Extra payment simulation | Nice-to-have | Phase 2 |
| Interest calculation | Simple division for MVP | Phase 2 |
| Loan payment history | Manual balance update sufficient | Phase 2 |
| Refinance comparison | Advanced feature | Phase 2+ |

---

## Open Questions

1. **Loans vs. Expenses:** Should loan payments also appear as expenses, or be tracked separately?
   - **Recommendation:** Track separately but show combined monthly obligations.

2. **Auto-update balance:** Should balance auto-decrement monthly?
   - **Recommendation:** No—manual update keeps user engaged and accurate.

3. **Paid-off loans:** Keep or delete?
   - **Recommendation:** Keep with "paid off" status for history; option to delete.

---

## References

- [03-Expenses.md](./03-Expenses.md) - Expense relationship
- [09-TransferPlanning.md](./09-TransferPlanning.md) - Loan payments in allocation
- [10-BudgetAnalysis.md](./10-BudgetAnalysis.md) - Debt analysis metrics
- Python script `CREDIT_AUTO_*` variables
