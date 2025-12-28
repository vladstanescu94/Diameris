import Foundation

/// The result of a transfer plan calculation.
/// Shows how money flows from income through accounts based on account types.
public struct TransferPlan: Sendable {
    /// Monthly income
    public let income: Decimal

    /// Total expenses
    public let totalExpenses: Decimal

    /// Available income after expenses
    public let availableIncome: Decimal

    /// Total amount going to savings (based on savings percentage)
    public let totalSavings: Decimal

    /// Allocations to accounts in priority order (emergency first, then savings)
    public let accountAllocations: [AccountAllocation]

    /// Amount that stays in primary account for automatic expense payments
    public let remainsInPrimary: Decimal

    /// Expense transfers to non-primary accounts
    public let accountExpenseTransfers: [AccountExpenseTransfer]

    /// Amount remaining after expenses and savings
    public let remainingMoney: Decimal

    /// Where remaining money goes
    public let remainingDestination: RemainingMoneyDestination

    /// Whether all amounts add up correctly
    public let isBalanced: Bool

    public init(
        income: Decimal,
        totalExpenses: Decimal,
        availableIncome: Decimal,
        totalSavings: Decimal,
        accountAllocations: [AccountAllocation],
        remainsInPrimary: Decimal,
        accountExpenseTransfers: [AccountExpenseTransfer],
        remainingMoney: Decimal,
        remainingDestination: RemainingMoneyDestination,
        isBalanced: Bool
    ) {
        self.income = income
        self.totalExpenses = totalExpenses
        self.availableIncome = availableIncome
        self.totalSavings = totalSavings
        self.accountAllocations = accountAllocations
        self.remainsInPrimary = remainsInPrimary
        self.accountExpenseTransfers = accountExpenseTransfers
        self.remainingMoney = remainingMoney
        self.remainingDestination = remainingDestination
        self.isBalanced = isBalanced
    }
}

// MARK: - Account Allocation

extension TransferPlan {
    /// Represents money being allocated to a specific account based on its type.
    public struct AccountAllocation: Identifiable, Sendable {
        public let id: UUID
        public let accountId: UUID
        public let accountName: String
        public let accountType: AccountType
        public let amount: Decimal

        // Progress tracking (for emergency accounts)
        public let progressBefore: Double?     // 0.0 - 1.0
        public let progressAfter: Double?      // 0.0 - 1.0
        public let targetAmount: Decimal?      // Target for emergency accounts
        public let currentBalance: Decimal
        public let isComplete: Bool            // Will this allocation complete the target?

        public init(
            account: AccountEntry,
            amount: Decimal,
            progressBefore: Double? = nil,
            progressAfter: Double? = nil,
            targetAmount: Decimal? = nil,
            isComplete: Bool = false
        ) {
            self.id = UUID()
            self.accountId = account.id
            self.accountName = account.name
            self.accountType = account.accountType
            self.amount = amount
            self.progressBefore = progressBefore
            self.progressAfter = progressAfter
            self.targetAmount = targetAmount
            self.currentBalance = account.currentBalance
            self.isComplete = isComplete
        }

        /// Format progress change for display (e.g., "86% → 92%")
        public var progressChangeDisplay: String? {
            guard let before = progressBefore, let after = progressAfter else { return nil }
            let beforeInt = Int(before * 100)
            let afterInt = Int(after * 100)
            return "\(beforeInt)% → \(afterInt)%"
        }

        /// Icon for the account type
        public var icon: String {
            accountType.icon
        }
    }
}

// MARK: - Account Expense Transfer

extension TransferPlan {
    /// Represents expenses that are transferred to a specific account.
    public struct AccountExpenseTransfer: Identifiable, Sendable {
        public let id: UUID
        public let accountId: UUID
        public let accountName: String
        public let amount: Decimal
        public let expenseNames: [String]

        public init(accountId: UUID, accountName: String, amount: Decimal, expenseNames: [String]) {
            self.id = UUID()
            self.accountId = accountId
            self.accountName = accountName
            self.amount = amount
            self.expenseNames = expenseNames
        }
    }
}

// MARK: - Convenience Properties

extension TransferPlan {
    /// Check if there are any account allocations
    public var hasAccountAllocations: Bool {
        !accountAllocations.isEmpty && accountAllocations.contains { $0.amount > 0 }
    }

    /// Get the total amount allocated to accounts
    public var totalAccountAllocations: Decimal {
        accountAllocations.reduce(0) { $0 + $1.amount }
    }

    /// Get emergency allocation if present
    public var emergencyAllocation: AccountAllocation? {
        accountAllocations.first { $0.accountType == .emergency }
    }

    /// Get savings allocation if present
    public var savingsAllocation: AccountAllocation? {
        accountAllocations.first { $0.accountType == .savings }
    }

    /// Get summary for display
    public var summary: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        let incomeStr = formatter.string(from: income as NSNumber) ?? "0"
        let savingsStr = formatter.string(from: totalSavings as NSNumber) ?? "0"
        let remainingStr = formatter.string(from: remainingMoney as NSNumber) ?? "0"

        return "Income: \(incomeStr) | Savings: \(savingsStr) | Remaining: \(remainingStr)"
    }
}
