# Transfer Planning

## Overview

Transfer Planning generates a step-by-step list of transfers to make after receiving income. It calculates how much to move from the primary account to each additional account based on the budget allocation: expenses stay in primary (for automatic payments), savings go to emergency/savings accounts, shared expenses go to joint accounts, and flexible spending goes to a personal account.

**Key Principle:** Make payday transfers easy. Show exactly how much goes where, so the user can execute transfers in their banking app.

---

## User Stories

| As a... | I want to... | So that... |
|---------|--------------|------------|
| User | See a transfer checklist after payday | I know exactly what to move and where |
| User | Copy transfer amounts | I can paste them into my banking app |
| User | Understand the allocation logic | I trust the suggestions |
| User | Mark transfers as done | I can track my progress |
| User | See what stays in primary | I know what's for automatic payments |

---

## Transfer Calculation

### Allocation Logic

```
Income arrives in Primary Account

Calculate allocations:
1. Expenses (stay in Primary) = Monthly expenses for automatic payments
2. Emergency Fund = Savings allocation to emergency (if not complete)
3. Regular Savings = Savings allocation after emergency fund
4. Shared/Joint = Specific expenses marked for joint account (e.g., food)
5. Flexible = Remaining after all allocations

Generate transfers:
- Primary → Joint: [Shared amount]
- Primary → Emergency: [Emergency allocation]
- Primary → Savings: [Regular savings allocation]
- Primary → Personal: [Flexible amount]
- Primary retains: [Expense amount for auto-payments]
```

### Implementation

```swift
struct TransferPlan {
    let incomeAmount: Decimal
    let transfers: [Transfer]
    let remainsInPrimary: Decimal
    let verification: Verification

    struct Transfer {
        let fromAccount: Account
        let toAccount: Account
        let amount: Decimal
        let purpose: String
        let note: String?
        var isCompleted: Bool
    }

    struct Verification {
        let totalTransfers: Decimal
        let totalAllocated: Decimal  // transfers + remains
        let isBalanced: Bool         // totalAllocated == incomeAmount
    }
}

func calculateTransferPlan(
    income: Decimal,
    expenses: [Expense],
    savingsCalculation: SavingsCalculation,
    accounts: [Account],
    jointExpenses: [Expense]  // Expenses marked for joint account
) -> TransferPlan {
    let primaryAccount = accounts.first { $0.isPrimary }!

    var transfers: [Transfer] = []

    // 1. Joint account transfer (shared expenses)
    if let jointAccount = accounts.first(where: { $0.accountType == .joint }) {
        let jointTotal = jointExpenses.reduce(0) { $0 + $1.monthlyAmount }
        if jointTotal > 0 {
            transfers.append(Transfer(
                fromAccount: primaryAccount,
                toAccount: jointAccount,
                amount: jointTotal,
                purpose: String(localized: "Shared expenses"),
                note: String(localized: "Food, shared bills"),
                isCompleted: false
            ))
        }
    }

    // 2. Emergency fund transfer
    if savingsCalculation.toEmergencyFund > 0,
       let emergencyAccount = accounts.first(where: { $0.accountType == .emergency }) {
        transfers.append(Transfer(
            fromAccount: primaryAccount,
            toAccount: emergencyAccount,
            amount: savingsCalculation.toEmergencyFund,
            purpose: String(localized: "Emergency fund"),
            note: emergencyFundNote(savingsCalculation),
            isCompleted: false
        ))
    }

    // 3. Regular savings transfer
    if savingsCalculation.toRegularSavings > 0,
       let savingsAccount = accounts.first(where: { $0.accountType == .savings }) {
        transfers.append(Transfer(
            fromAccount: primaryAccount,
            toAccount: savingsAccount,
            amount: savingsCalculation.toRegularSavings,
            purpose: String(localized: "Regular savings"),
            note: nil,
            isCompleted: false
        ))
    }

    // 4. Personal/flexible transfer
    if savingsCalculation.remaining > 0,
       let personalAccount = accounts.first(where: { $0.accountType == .other }) {
        transfers.append(Transfer(
            fromAccount: primaryAccount,
            toAccount: personalAccount,
            amount: savingsCalculation.remaining,
            purpose: String(localized: "Flexible spending"),
            note: String(localized: "Personal expenses, shopping, entertainment"),
            isCompleted: false
        ))
    }

    // Calculate what remains in primary
    let totalTransfers = transfers.reduce(0) { $0 + $1.amount }
    let remainsInPrimary = income - totalTransfers

    return TransferPlan(
        incomeAmount: income,
        transfers: transfers,
        remainsInPrimary: remainsInPrimary,
        verification: Verification(
            totalTransfers: totalTransfers,
            totalAllocated: income,
            isBalanced: true
        )
    )
}
```

---

## UI/UX

### Transfer Planning Screen (Transfers Tab)

```
┌─────────────────────────────────────┐
│  Transfers                          │
│                                     │
│  AFTER PAYDAY                       │
│  Based on 14,303 RON income         │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  TRANSFERS TO MAKE                  │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ □ 🍽️ → Joint Account        │    │
│  │                             │    │
│  │   3,000 RON          [Copy] │    │
│  │   Shared expenses (food)    │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ □ 🛡️ → Emergency Fund       │    │
│  │                             │    │
│  │   2,751 RON          [Copy] │    │
│  │   Progress: 86% → 92%       │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ □ 🎯 → Personal             │    │
│  │                             │    │
│  │   1,497 RON          [Copy] │    │
│  │   Flexible spending         │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  STAYS IN MAIN ACCOUNT              │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 🏦 Main Checking            │    │
│  │                             │    │
│  │   7,055 RON                 │    │
│  │   For automatic payments:   │    │
│  │   • Car loan: 2,850 RON     │    │
│  │   • Subscriptions: 140 RON  │    │
│  │   • Other expenses...       │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ✓ VERIFICATION                     │
│  Transfers: 7,248 RON               │
│  Remains: 7,055 RON                 │
│  Total: 14,303 RON ✓                │
│                                     │
└─────────────────────────────────────┘
```

**UI Notes:**
- Checkbox to mark transfers complete
- Copy button for each amount
- Progress indicator for emergency fund
- Clear breakdown of what stays in primary
- Verification sum at bottom

### Transfer Completed State

```
┌─────────────────────────────────────┐
│  ┌─────────────────────────────┐    │
│  │ ✓ 🍽️ → Joint Account        │    │
│  │                             │    │
│  │   3,000 RON          Done   │    │
│  │   ─────────────────────     │    │
│  │                             │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### All Transfers Complete

```
┌─────────────────────────────────────┐
│  Transfers                          │
│                                     │
│  ┌─────────────────────────────┐    │
│  │                             │    │
│  │     ✓ All transfers done    │    │
│  │                             │    │
│  │   Great job! Your money is  │    │
│  │   allocated for the month.  │    │
│  │                             │    │
│  │      [Reset for Next Month] │    │
│  │                             │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

### Instructions View (Expandable)

```
┌─────────────────────────────────────┐
│  📱 HOW TO TRANSFER                 │
│                                     │
│  1. Open your banking app           │
│  2. Go to Transfers                 │
│  3. Select "To own account" or      │
│     "Internal transfer"             │
│  4. Choose destination account      │
│  5. Enter amount (use Copy button)  │
│  6. Confirm transfer                │
│  7. Check off in Diameris           │
│                                     │
│  💡 Set up standing orders for      │
│     recurring transfers to save     │
│     time each month.                │
│                                     │
└─────────────────────────────────────┘
```

---

## Transfer Persistence

### Monthly Reset

Transfers are session-based (not persisted) by default. User can:
- Mark transfers as complete (persisted for current month)
- Reset at start of new month

```swift
struct MonthlyTransferStatus {
    let month: Date  // First day of month
    var completedTransferIDs: Set<UUID>
    var allComplete: Bool
}
```

---

## Account Mapping

### Default Account Assignments

| Allocation | Account Type | Fallback |
|------------|--------------|----------|
| Shared expenses | `.joint` | Stay in primary |
| Emergency fund | `.emergency` | First savings account |
| Regular savings | `.savings` | None (stays in primary) |
| Flexible spending | `.other` | Stay in primary |
| Automatic payments | `.checking` (primary) | N/A |

### Custom Mapping (Future)

Phase 2 could allow users to customize which expenses go to which accounts.

---

## Validation & Verification

### Balance Check

```swift
func verifyTransferPlan(_ plan: TransferPlan, income: Decimal) -> Bool {
    let totalAllocated = plan.transfers.reduce(0) { $0 + $1.amount } + plan.remainsInPrimary
    return totalAllocated == income
}
```

### Edge Cases

| Scenario | Handling |
|----------|----------|
| No additional accounts | Show only "stays in primary" |
| No joint account | Shared expenses stay in primary |
| No emergency account | Emergency savings noted but no transfer |
| Negative remaining | Warning; budget exceeds income |

---

## Foundation Models Integration

### Transfer Summary

FM can provide a natural language summary of the transfer plan:

```swift
@Generable
struct TransferSummary {
    @Guide(description: "A brief, friendly summary of this month's transfers")
    let summary: String

    @Guide(description: "One tip or observation about the allocation")
    let tip: String?
}

let prompt = """
User has income of \(income) RON.
Transfers: \(transferDescriptions)
Remains in primary: \(remains) RON for automatic payments.
Provide a brief summary and optional tip.
"""
```

### Fallback

When FM unavailable:
- Show transfers without natural language summary
- Use static helper text

---

## Implementation Notes

### Transfer Plan Generation

```swift
// UseCases/GenerateTransferPlanUseCase.swift
protocol GenerateTransferPlanUseCaseProtocol {
    func execute() async throws -> TransferPlan
}

final class GenerateTransferPlanUseCase: GenerateTransferPlanUseCaseProtocol {
    private let incomeRepository: IncomeRepositoryProtocol
    private let expenseRepository: ExpenseRepositoryProtocol
    private let accountRepository: AccountRepositoryProtocol
    private let savingsCalculator: SavingsCalculatorProtocol
    private let emergencyFundRepository: EmergencyFundRepositoryProtocol

    func execute() async throws -> TransferPlan {
        let income = try await incomeRepository.fetchActive()
        let expenses = try await expenseRepository.fetchEnabled()
        let accounts = try await accountRepository.fetchAll()
        let emergencyFund = try await emergencyFundRepository.fetch()

        let monthlyIncome = income.reduce(0) { $0 + $1.monthlyAmount }
        let monthlyExpenses = expenses.reduce(0) { $0 + $1.monthlyAmount }

        let savingsCalc = savingsCalculator.calculate(
            income: monthlyIncome,
            expenses: monthlyExpenses,
            emergencyFund: emergencyFund
        )

        return calculateTransferPlan(
            income: monthlyIncome,
            expenses: expenses,
            savingsCalculation: savingsCalc,
            accounts: accounts,
            jointExpenses: expenses.filter { /* marked as shared */ }
        )
    }
}
```

---

## Out of Scope (MVP)

| Feature | Reason | Phase |
|---------|--------|-------|
| Recurring/scheduled transfers | No bank integration | Phase 2+ |
| Transfer history | Session-based sufficient | Phase 2 |
| Custom account mapping | Default mapping works | Phase 2 |
| Transfer reminders | Notifications feature | Phase 2 |
| Split transfers | Complexity | Phase 2 |

---

## Open Questions

1. **Shared expenses identification:** How do we know which expenses are "shared"?
   - **Recommendation:** Category-based (expenses in "Food & Groceries" go to joint) or explicit marking.

2. **Payday detection:** Should we detect when income arrives?
   - **Recommendation:** Phase 2; for MVP, user triggers manually or monthly reminder.

3. **Partial income:** What if user receives income in installments?
   - **Recommendation:** MVP assumes single monthly income; multi-income Phase 2.

---

## References

- [08-Accounts.md](./08-Accounts.md) - Account definitions
- [07-Savings.md](./07-Savings.md) - Savings allocation logic
- [05-EmergencyFund.md](./05-EmergencyFund.md) - Emergency fund priority
- Python script `planifica_transferuri_ing()` function
