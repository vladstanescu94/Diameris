import Foundation
@testable import Domain

enum Fixture {
    static func expense(
        _ name: String,
        _ amount: Decimal,
        _ frequency: Frequency = .monthly,
        linkedTo account: AccountEntry? = nil,
        enabled: Bool = true
    ) -> ExpenseEntry {
        ExpenseEntry(
            name: name,
            amount: amount,
            frequency: frequency,
            icon: "circle",
            linkedAccountId: account?.id,
            isEnabled: enabled
        )
    }

    static func prioritized(_ percentage: Double = 0.25, boost: Bool = false) -> SavingsAllocationEntry {
        SavingsAllocationEntry(percentage: percentage, boostEnabled: boost, boostMultiplier: 3.0)
    }

    static func split(emergency: Decimal, savings: Decimal) -> SavingsAllocationEntry {
        SavingsAllocationEntry(
            allocationMode: .split,
            splitEmergencyInputMode: .fixedAmount,
            splitEmergencyAmount: emergency,
            splitSavingsInputMode: .fixedAmount,
            splitSavingsAmount: savings
        )
    }

    static func plan(
        income: Decimal,
        expenses: [ExpenseEntry] = [],
        allocation: SavingsAllocationEntry = prioritized(),
        accounts: [AccountEntry],
        destination: RemainingMoneyDestination = .primary
    ) -> TransferPlan {
        TransferCalculator.calculate(
            income: income,
            expenses: expenses,
            allocation: allocation,
            accounts: accounts,
            remainingDestination: destination
        )
    }
}

extension TransferPlan {
    /// Every unit of income, as it actually leaves (or stays in) the primary account.
    var sumOfParts: Decimal {
        remainsInPrimary
            + accountExpenseTransfers.reduce(0) { $0 + $1.amount }
            + totalAccountAllocations
            + remainingMoney
    }

    /// Every amount a user would have to type into a banking app.
    var allAmounts: [Decimal] {
        [remainsInPrimary, remainingMoney, totalSavings]
            + accountAllocations.map(\.amount)
            + accountExpenseTransfers.map(\.amount)
    }
}

extension Decimal {
    /// True when the value has no sub-cent digits — i.e. it is a real, transferable amount.
    var isWholeCents: Bool {
        var copy = self * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &copy, 0, .plain)
        return rounded == self * 100
    }
}
