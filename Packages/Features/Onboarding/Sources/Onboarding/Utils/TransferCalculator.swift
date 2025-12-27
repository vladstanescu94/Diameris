import Foundation

/// Calculator for generating transfer plans.
public enum TransferCalculator {

    /// Calculate the transfer plan based on income, expenses, goals, and allocation settings.
    public static func calculate(
        income: Decimal,
        expenses: [ExpenseEntry],
        goals: [SavingsGoalEntry],
        allocation: SavingsAllocationEntry,
        accounts: [AccountEntry] = []
    ) -> TransferPlan {
        // 1. Calculate total expenses
        let totalExpenses = expenses.reduce(0) { $0 + $1.amount }

        // 2. Calculate available income after expenses
        let availableIncome = max(0, income - totalExpenses)

        // 3. Calculate total savings amount
        let totalSavings = allocation.calculateSavings(availableIncome: availableIncome)

        // 4. Distribute savings to goals in priority order
        let goalAllocations = distributeToGoals(
            totalSavings: totalSavings,
            goals: goals,
            monthlyIncome: income,
            accounts: accounts
        )

        // 5. Calculate flexible spending (what's left after savings)
        let flexibleSpending = availableIncome - totalSavings

        // 6. What stays in primary = expenses (for automatic payments)
        let remainsInPrimary = totalExpenses

        // 7. Verify balance
        let totalAllocated = goalAllocations.reduce(0) { $0 + $1.amount }
        let total = remainsInPrimary + totalAllocated + flexibleSpending
        let isBalanced = abs(total - income) < 0.01  // Allow small rounding error

        return TransferPlan(
            income: income,
            totalExpenses: totalExpenses,
            availableIncome: availableIncome,
            totalSavings: totalSavings,
            goalAllocations: goalAllocations,
            remainsInPrimary: remainsInPrimary,
            flexibleSpending: flexibleSpending,
            isBalanced: isBalanced
        )
    }
}

// MARK: - Private Helpers

private extension TransferCalculator {

    /// Distribute savings to goals in priority order.
    static func distributeToGoals(
        totalSavings: Decimal,
        goals: [SavingsGoalEntry],
        monthlyIncome: Decimal,
        accounts: [AccountEntry]
    ) -> [TransferPlan.GoalAllocation] {
        var remainingSavings = totalSavings
        var allocations: [TransferPlan.GoalAllocation] = []

        // Sort goals by priority (1 = highest)
        let sortedGoals = goals
            .filter { $0.isActive }
            .sorted { $0.priority < $1.priority }

        for goal in sortedGoals {
            guard remainingSavings > 0 else { break }

            let allocation = calculateAllocation(
                for: goal,
                remainingSavings: remainingSavings,
                monthlyIncome: monthlyIncome,
                accounts: accounts
            )

            if allocation.amount > 0 || goal.targetType != .unlimited {
                allocations.append(allocation)
            }

            remainingSavings -= allocation.amount
        }

        return allocations
    }

    /// Calculate allocation for a single goal.
    static func calculateAllocation(
        for goal: SavingsGoalEntry,
        remainingSavings: Decimal,
        monthlyIncome: Decimal,
        accounts: [AccountEntry]
    ) -> TransferPlan.GoalAllocation {
        let targetAmount = goal.calculateTarget(monthlyIncome: monthlyIncome)
        let progressBefore = goal.progressPercentage(monthlyIncome: monthlyIncome) ?? 0

        // Calculate how much this goal needs
        let amountNeeded: Decimal
        if let remaining = goal.remainingAmount(monthlyIncome: monthlyIncome) {
            amountNeeded = remaining
        } else {
            // Unlimited goal - takes all remaining savings
            amountNeeded = remainingSavings
        }

        // Allocate the minimum of what's needed and what's available
        let amountToAllocate = min(amountNeeded, remainingSavings)

        // Calculate new progress after this allocation
        let progressAfter = calculateProgressAfter(
            goal: goal,
            allocation: amountToAllocate,
            targetAmount: targetAmount
        )

        // Check if goal will be complete after this allocation
        let isComplete = checkIsComplete(
            goal: goal,
            allocation: amountToAllocate,
            targetAmount: targetAmount
        )

        // Find matching account type for this goal
        let accountType = findAccountType(for: goal, in: accounts)

        return TransferPlan.GoalAllocation(
            goal: goal,
            amount: amountToAllocate,
            progressBefore: progressBefore,
            progressAfter: progressAfter,
            targetAmount: targetAmount,
            isComplete: isComplete,
            accountType: accountType
        )
    }

    /// Calculate progress after allocation.
    static func calculateProgressAfter(
        goal: SavingsGoalEntry,
        allocation: Decimal,
        targetAmount: Decimal?
    ) -> Double {
        let newBalance = goal.currentBalance + allocation
        guard let target = targetAmount, target > 0 else {
            return 0 // Unlimited goals have no progress
        }
        return min(1.0, Double(truncating: (newBalance / target) as NSNumber))
    }

    /// Check if goal will be complete after allocation.
    static func checkIsComplete(
        goal: SavingsGoalEntry,
        allocation: Decimal,
        targetAmount: Decimal?
    ) -> Bool {
        guard goal.targetType != .unlimited,
              let target = targetAmount else {
            return false
        }
        let newBalance = goal.currentBalance + allocation
        return newBalance >= target
    }

    /// Find the appropriate account type for a goal based on its characteristics.
    static func findAccountType(
        for goal: SavingsGoalEntry,
        in accounts: [AccountEntry]
    ) -> AccountType? {
        let goalNameLower = goal.name.lowercased()

        if goalNameLower.contains("emergency") || goalNameLower.contains("saving") {
            return .savings
        }

        // Default to savings for other goals
        return .savings
    }
}
