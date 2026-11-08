import Foundation

/// How one month's income flows through the accounts.
public struct TransferPlan: Equatable, Sendable {
    public let income: Decimal

    public let totalExpenses: Decimal

    public let availableIncome: Decimal

    public let totalSavings: Decimal

    /// Allocations to accounts in priority order (emergency first, then savings)
    public let accountAllocations: [AccountAllocation]

    /// Amount that stays in primary account for automatic expense payments
    public let remainsInPrimary: Decimal

    /// Expense transfers to non-primary accounts
    public let accountExpenseTransfers: [AccountExpenseTransfer]

    public let remainingMoney: Decimal

    public let remainingDestination: RemainingMoneyDestination

    /// Whether the parts add up to income and the month's bills fit in it. The parts always add up
    /// (a short month pays linked transfers first, within the income), so this is false exactly
    /// when there is a `shortfall`.
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
    /// Money allocated to one account. `id` is the account id: a plan allocates to each account
    /// at most once, so it is unique and stable across recalculations (no ForEach churn).
    public struct AccountAllocation: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let accountId: UUID
        public let accountName: String
        public let accountType: AccountType
        public let amount: Decimal

        // Progress tracking (for emergency accounts)
        public let progressBefore: Double?     // 0.0 - 1.0
        public let progressAfter: Double?      // 0.0 - 1.0
        public let targetAmount: Decimal?
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
            self.id = account.id
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
            return "\(before.wholePercentText) → \(after.wholePercentText)"
        }

        public var icon: String {
            accountType.icon
        }
    }
}

// MARK: - Account Expense Transfer

extension TransferPlan {
    /// Expenses moved to one account. `id` is the account id (expenses are grouped per account).
    public struct AccountExpenseTransfer: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let accountId: UUID
        public let accountName: String
        public let amount: Decimal
        public let expenseNames: [String]

        public init(accountId: UUID, accountName: String, amount: Decimal, expenseNames: [String]) {
            self.id = accountId
            self.accountId = accountId
            self.accountName = accountName
            self.amount = amount
            self.expenseNames = expenseNames
        }
    }
}

// MARK: - Convenience Properties

extension TransferPlan {
    public var hasAccountAllocations: Bool {
        !accountAllocations.isEmpty && accountAllocations.contains { $0.amount > 0 }
    }

    public var totalAccountAllocations: Decimal {
        accountAllocations.reduce(0) { $0 + $1.amount }
    }

    /// How much the month's expenses exceed income (zero when income covers them). `totalExpenses`
    /// stays the full bill; the transfers only move money that exists.
    public var shortfall: Decimal {
        max(0, totalExpenses - income)
    }

    public var emergencyAllocation: AccountAllocation? {
        accountAllocations.first { $0.accountType == .emergency }
    }

    public var savingsAllocation: AccountAllocation? {
        accountAllocations.first { $0.accountType == .savings }
    }

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
