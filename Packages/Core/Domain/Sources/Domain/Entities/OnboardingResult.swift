import Foundation

/// What onboarding collected, handed to the app to persist.
/// Account balances are final: the first month's transfer plan is already applied.
public struct OnboardingResult: Sendable {
    public let name: String
    public let currencyCode: String
    public let incomeName: String
    public let monthlyIncome: Decimal
    public let expenses: [ExpenseEntry]
    /// In display order.
    public let accounts: [AccountEntry]
    public let savingsAllocation: SavingsAllocationEntry
    public let remainingMoneyDestination: RemainingMoneyDestination

    public init(
        name: String,
        currencyCode: String,
        incomeName: String,
        monthlyIncome: Decimal,
        expenses: [ExpenseEntry],
        accounts: [AccountEntry],
        savingsAllocation: SavingsAllocationEntry,
        remainingMoneyDestination: RemainingMoneyDestination
    ) {
        self.name = name
        self.currencyCode = currencyCode
        self.incomeName = incomeName
        self.monthlyIncome = monthlyIncome
        self.expenses = expenses
        self.accounts = accounts
        self.savingsAllocation = savingsAllocation
        self.remainingMoneyDestination = remainingMoneyDestination
    }
}
