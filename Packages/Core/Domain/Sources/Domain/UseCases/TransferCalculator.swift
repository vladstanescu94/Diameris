import Foundation

/// Calculator for generating transfer plans based on account types.
///
/// Transfer priority:
/// 1. Emergency account fills first (until target reached)
/// 2. Primary Savings account fills with remaining savings
/// 3. Remaining money goes to user's chosen destination
public enum TransferCalculator {

    /// Calculate the transfer plan based on income, expenses, accounts, and allocation settings.
    public static func calculate(
        income: Decimal,
        expenses: [ExpenseEntry],
        allocation: SavingsAllocationEntry,
        accounts: [AccountEntry],
        remainingDestination: RemainingMoneyDestination
    ) -> TransferPlan {
        // 1. Calculate total expenses
        let totalExpenses = expenses.reduce(0) { $0 + $1.amount }

        // 2. Calculate available income after expenses
        let availableIncome = max(0, income - totalExpenses)

        // 3. Calculate total savings amount (based on percentage + boost)
        let totalSavings = allocation.calculateSavings(availableIncome: availableIncome)

        // 4. Distribute savings to accounts by type (emergency first, then savings)
        let (accountAllocations, allocatedSavings) = distributeToAccounts(
            totalSavings: totalSavings,
            accounts: accounts,
            monthlyIncome: income
        )

        // 5. Calculate remaining money after expenses and savings
        let remainingMoney = availableIncome - allocatedSavings

        // 6. Distribute expenses to accounts
        let (remainsInPrimary, accountExpenseTransfers) = distributeExpenses(
            expenses: expenses,
            accounts: accounts
        )

        // 7. Verify balance
        let totalAllocated = accountAllocations.reduce(0) { $0 + $1.amount }
        let totalExpenseTransfers = accountExpenseTransfers.reduce(0) { $0 + $1.amount }
        let total = remainsInPrimary + totalExpenseTransfers + totalAllocated + remainingMoney
        let isBalanced = abs(total - income) < 0.01  // Allow small rounding error

        return TransferPlan(
            income: income,
            totalExpenses: totalExpenses,
            availableIncome: availableIncome,
            totalSavings: allocatedSavings,
            accountAllocations: accountAllocations,
            remainsInPrimary: remainsInPrimary,
            accountExpenseTransfers: accountExpenseTransfers,
            remainingMoney: remainingMoney,
            remainingDestination: remainingDestination,
            isBalanced: isBalanced
        )
    }
}

// MARK: - Private Helpers

private extension TransferCalculator {

    /// Distribute savings to accounts based on type priority.
    /// Returns: (allocations, totalAllocated)
    static func distributeToAccounts(
        totalSavings: Decimal,
        accounts: [AccountEntry],
        monthlyIncome: Decimal
    ) -> ([TransferPlan.AccountAllocation], Decimal) {
        var remainingSavings = totalSavings
        var allocations: [TransferPlan.AccountAllocation] = []

        // Step 1: Fill Emergency account first (if exists and not complete)
        if let emergencyAccount = accounts.first(where: { $0.accountType == .emergency }) {
            let allocation = calculateEmergencyAllocation(
                account: emergencyAccount,
                availableSavings: remainingSavings,
                monthlyIncome: monthlyIncome
            )
            if allocation.amount > 0 || allocation.targetAmount != nil {
                allocations.append(allocation)
                remainingSavings -= allocation.amount
            }
        }

        // Step 2: Fill Primary Savings account with remaining savings
        if let savingsAccount = accounts.first(where: { $0.isPrimarySavings }) {
            if remainingSavings > 0 {
                let allocation = TransferPlan.AccountAllocation(
                    account: savingsAccount,
                    amount: remainingSavings
                )
                allocations.append(allocation)
                remainingSavings = 0
            }
        } else if let savingsAccount = accounts.first(where: { $0.accountType == .savings }) {
            // Fallback: use first savings-type account if no primary savings
            if remainingSavings > 0 {
                let allocation = TransferPlan.AccountAllocation(
                    account: savingsAccount,
                    amount: remainingSavings
                )
                allocations.append(allocation)
                remainingSavings = 0
            }
        }

        let totalAllocated = totalSavings - remainingSavings
        return (allocations, totalAllocated)
    }

    /// Calculate allocation for an emergency account with progress tracking.
    static func calculateEmergencyAllocation(
        account: AccountEntry,
        availableSavings: Decimal,
        monthlyIncome: Decimal
    ) -> TransferPlan.AccountAllocation {
        guard let target = account.emergencyTarget(monthlyIncome: monthlyIncome) else {
            // No target set, treat as unlimited
            return TransferPlan.AccountAllocation(
                account: account,
                amount: availableSavings
            )
        }

        // Calculate how much is still needed
        let currentBalance = account.currentBalance
        let remaining = max(0, target - currentBalance)

        // Allocate the minimum of what's needed and what's available
        let amountToAllocate = min(remaining, availableSavings)

        // Calculate progress before and after
        let progressBefore = account.emergencyProgress(monthlyIncome: monthlyIncome) ?? 0
        let newBalance = currentBalance + amountToAllocate
        let progressAfter = target > 0 ? min(1.0, Double(truncating: (newBalance / target) as NSNumber)) : 0

        // Check if this allocation completes the target
        let isComplete = newBalance >= target

        return TransferPlan.AccountAllocation(
            account: account,
            amount: amountToAllocate,
            progressBefore: progressBefore,
            progressAfter: progressAfter,
            targetAmount: target,
            isComplete: isComplete
        )
    }

    /// Distribute expenses to accounts based on linkedAccountId.
    /// Returns: (remainsInPrimary, accountExpenseTransfers)
    static func distributeExpenses(
        expenses: [ExpenseEntry],
        accounts: [AccountEntry]
    ) -> (Decimal, [TransferPlan.AccountExpenseTransfer]) {
        // Group expenses by linkedAccountId (nil = primary account)
        let expensesByAccount = Dictionary(grouping: expenses.filter { $0.amount > 0 }) { expense in
            expense.linkedAccountId
        }

        // Calculate what stays in primary (nil linkedAccountId)
        let primaryExpenses = expensesByAccount[nil] ?? []
        let remainsInPrimary = primaryExpenses.reduce(0) { $0 + $1.amount }

        // Create transfers for linked accounts
        var transfers: [TransferPlan.AccountExpenseTransfer] = []

        for (accountId, linkedExpenses) in expensesByAccount {
            // Skip primary account (nil)
            guard let accountId = accountId else { continue }

            // Find the account name
            let accountName = accounts.first { $0.id == accountId }?.name ?? "Unknown"

            let amount = linkedExpenses.reduce(0) { $0 + $1.amount }
            let expenseNames = linkedExpenses.map { $0.name }

            if amount > 0 {
                transfers.append(
                    TransferPlan.AccountExpenseTransfer(
                        accountId: accountId,
                        accountName: accountName,
                        amount: amount,
                        expenseNames: expenseNames
                    )
                )
            }
        }

        return (remainsInPrimary, transfers)
    }
}
