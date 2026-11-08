import SwiftUI
import SwiftData
import Persistence
import Utilities

/// Reads the stored settings and hands a snapshot to `SettingsForm`, which edits a local copy.
/// Profile and savings edits are written on Save (Cancel discards them); account edits are
/// saved by their own sheet.
struct SettingsSheet: View {
    @Query private var userProfiles: [UserProfile]
    @Query private var savingsAllocations: [SavingsAllocation]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Query private var incomes: [Income]
    @Query private var expenses: [Expense]

    var body: some View {
        let profile = userProfiles.first
        let monthlyIncome = incomes.first?.amount ?? 0
        let allocation = savingsAllocations.first?.toEntry() ?? SavingsAllocationEntry()
        let plan = TransferCalculator.calculate(
            income: monthlyIncome,
            expenses: expenses.map { $0.toEntry() },
            allocation: allocation,
            accounts: accounts.map { $0.toEntry() },
            remainingDestination: profile?.remainingMoneyDestination ?? .primary
        )

        SettingsForm(
            name: profile?.name ?? "",
            currency: profile.flatMap { Currency(rawValue: $0.currencyCode) } ?? .ron,
            remainingDestination: profile?.remainingMoneyDestination ?? .primarySavings,
            allocation: allocation,
            accounts: accounts,
            monthlyIncome: monthlyIncome,
            availableIncome: plan.availableIncome
        )
    }
}

#Preview {
    SettingsSheet()
        .modelContainer(for: PersistenceSchema.models, inMemory: true)
}
