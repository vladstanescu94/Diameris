import Foundation
import Dashboard
import Persistence
import Utilities

/// The stored models as the Dashboard reads them. A missing allocation falls back to Domain's
/// defaults (`SavingsAllocationEntry()`).
struct StoredDashboardData: DashboardDataProvider {
    let userName: String
    let monthlyIncome: Decimal
    let currency: Currency
    let accounts: [DashboardAccount]
    let expenses: [DashboardExpense]
    let remainingMoneyDestination: RemainingMoneyDestination
    private let allocation: SavingsAllocationEntry

    init(profile: UserProfile, monthlyIncome: Decimal, accounts: [Account], expenses: [Expense], allocation: SavingsAllocation?) {
        userName = profile.name
        self.monthlyIncome = monthlyIncome
        currency = Currency(rawValue: profile.currencyCode) ?? .ron
        remainingMoneyDestination = profile.remainingMoneyDestination
        self.allocation = allocation?.toEntry() ?? SavingsAllocationEntry()
        self.accounts = accounts.map { account in
            DashboardAccount(
                id: account.id,
                name: account.name,
                accountType: account.accountType,
                isPrimary: account.isPrimary,
                isPrimarySavings: account.isPrimarySavings,
                emergencyMultiplier: account.emergencyMultiplier,
                emergencyHardCap: account.emergencyHardCap,
                currentBalance: account.currentBalance
            )
        }
        // The Dashboard plans a single month, so it receives monthly-equivalent amounts.
        self.expenses = expenses.filter(\.isEnabled).map { expense in
            DashboardExpense(
                id: expense.id,
                name: expense.name,
                amount: expense.monthlyAmount,
                icon: expense.icon,
                linkedAccountId: expense.linkedAccountId
            )
        }
    }

    var savingsPercentage: Double { allocation.percentage }
    var savingsBoostEnabled: Bool { allocation.boostEnabled }
    var savingsBoostMultiplier: Double { allocation.boostMultiplier }
    var allocationMode: AllocationMode { allocation.allocationMode }
    var savingsInputMode: SavingsInputMode { allocation.savingsInputMode }
    var savingsFixedAmount: Decimal { allocation.fixedAmount }
    var splitEmergencyInputMode: SavingsInputMode { allocation.splitEmergencyInputMode }
    var splitEmergencyAmount: Decimal { allocation.splitEmergencyAmount }
    var splitEmergencyPercentage: Double { allocation.splitEmergencyPercentage }
    var splitSavingsInputMode: SavingsInputMode { allocation.splitSavingsInputMode }
    var splitSavingsAmount: Decimal { allocation.splitSavingsAmount }
    var splitSavingsPercentage: Double { allocation.splitSavingsPercentage }
}
