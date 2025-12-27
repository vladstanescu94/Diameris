import Foundation

/// The result of a transfer plan calculation.
public struct TransferPlan: Sendable {
    /// Monthly income
    public let income: Decimal

    /// Total expenses
    public let totalExpenses: Decimal

    /// Available income after expenses
    public let availableIncome: Decimal

    /// Total amount going to savings (before distribution to goals)
    public let totalSavings: Decimal

    /// Allocations to each goal in priority order
    public let goalAllocations: [GoalAllocation]

    /// Amount that stays in primary account for automatic payments
    public let remainsInPrimary: Decimal

    /// Amount for flexible/personal spending
    public let flexibleSpending: Decimal

    /// Whether all amounts add up correctly
    public let isBalanced: Bool
}

// MARK: - Goal Allocation

extension TransferPlan {
    /// A single goal allocation with progress information.
    public struct GoalAllocation: Identifiable, Sendable {
        public let id: UUID
        public let goalName: String
        public let goalIcon: String
        public let amount: Decimal
        public let progressBefore: Double      // 0.0 - 1.0
        public let progressAfter: Double       // 0.0 - 1.0
        public let targetAmount: Decimal?      // Nil for unlimited
        public let currentBalance: Decimal
        public let isComplete: Bool            // Will this fill the goal?
        public let accountType: AccountType?   // Where this money goes

        public init(
            goal: SavingsGoalEntry,
            amount: Decimal,
            progressBefore: Double,
            progressAfter: Double,
            targetAmount: Decimal?,
            isComplete: Bool,
            accountType: AccountType? = nil
        ) {
            self.id = goal.id
            self.goalName = goal.name
            self.goalIcon = goal.icon
            self.amount = amount
            self.progressBefore = progressBefore
            self.progressAfter = progressAfter
            self.targetAmount = targetAmount
            self.currentBalance = goal.currentBalance
            self.isComplete = isComplete
            self.accountType = accountType
        }

        /// Format progress change for display (e.g., "86% → 92%")
        public var progressChangeDisplay: String? {
            guard targetAmount != nil else { return nil }
            let before = Int(progressBefore * 100)
            let after = Int(progressAfter * 100)
            return "\(before)% → \(after)%"
        }
    }
}

// MARK: - Progress Info (used by TransferCard)

extension TransferPlan.GoalAllocation {
    /// Progress information for display in transfer cards.
    public struct ProgressInfo: Sendable {
        public let currentPercent: Double
        public let afterPercent: Double

        public init(currentPercent: Double, afterPercent: Double) {
            self.currentPercent = currentPercent
            self.afterPercent = afterPercent
        }
    }
}

// MARK: - Convenience Properties

extension TransferPlan {
    /// Check if there are any goal allocations
    public var hasGoalAllocations: Bool {
        !goalAllocations.isEmpty && goalAllocations.contains { $0.amount > 0 }
    }

    /// Get the total amount allocated to goals
    public var totalGoalAllocations: Decimal {
        goalAllocations.reduce(0) { $0 + $1.amount }
    }

    /// Get summary for display
    public var summary: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0

        let incomeStr = formatter.string(from: income as NSNumber) ?? "0"
        let savingsStr = formatter.string(from: totalSavings as NSNumber) ?? "0"
        let flexibleStr = formatter.string(from: flexibleSpending as NSNumber) ?? "0"

        return "Income: \(incomeStr) | Savings: \(savingsStr) | Flexible: \(flexibleStr)"
    }
}
