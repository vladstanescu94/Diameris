import Foundation

/// Builds the month's transfer plan.
///
/// **Prioritized**: the savings pool fills the emergency account up to its target, the rest goes
/// to savings. **Split**: emergency and savings get independent amounts; emergency overflow past
/// its target goes to savings. Either way, what's left is `remainingMoney` for the chosen
/// destination, and all amounts are whole cents that add up exactly to income.
public enum TransferCalculator {

    public static func calculate(
        income: Decimal,
        expenses: [ExpenseEntry],
        allocation: SavingsAllocationEntry,
        accounts: [AccountEntry],
        remainingDestination: RemainingMoneyDestination
    ) -> TransferPlan {
        // Enabled, positive expenses at their monthly equivalent, whatever frequency is passed.
        let plannedExpenses = expenses.filter { $0.isEnabled && $0.monthlyAmount > 0 }
        var (remainsInPrimary, accountExpenseTransfers) = distributeExpenses(
            expenses: plannedExpenses,
            accounts: accounts
        )
        let totalExpenses = remainsInPrimary + accountExpenseTransfers.reduce(0) { $0 + $1.amount }

        // A short month can only move the salary that exists; `shortfall` reports the rest.
        if totalExpenses > income {
            (remainsInPrimary, accountExpenseTransfers) = payWithinIncome(
                max(0, income),
                transfers: accountExpenseTransfers
            )
        }

        let availableIncome = max(0, income - totalExpenses)

        let accountAllocations: [TransferPlan.AccountAllocation]
        let allocatedSavings: Decimal

        switch allocation.allocationMode {
        case .prioritized:
            let savingsPool = allocation.calculateSavings(availableIncome: availableIncome)
            let result = distributeToAccounts(
                totalSavings: savingsPool,
                accounts: accounts,
                monthlyIncome: income
            )
            accountAllocations = result.0
            allocatedSavings = result.1

        case .split:
            let result = distributeSplitToAccounts(
                allocation: allocation,
                availableIncome: availableIncome,
                accounts: accounts,
                monthlyIncome: income
            )
            accountAllocations = result.0
            allocatedSavings = result.1
        }

        let remainingMoney = availableIncome - allocatedSavings

        let totalAllocated = accountAllocations.reduce(0) { $0 + $1.amount }
        let totalExpenseTransfers = accountExpenseTransfers.reduce(0) { $0 + $1.amount }
        let total = remainsInPrimary + totalExpenseTransfers + totalAllocated + remainingMoney
        let isBalanced = abs(total - income) < 0.01 && totalExpenses <= income  // Allow small rounding error

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

// MARK: - Prioritized Mode (Emergency First)

private extension TransferCalculator {

    /// Returns: (allocations, totalAllocated)
    static func distributeToAccounts(
        totalSavings: Decimal,
        accounts: [AccountEntry],
        monthlyIncome: Decimal
    ) -> ([TransferPlan.AccountAllocation], Decimal) {
        var remainingSavings = totalSavings
        var allocations: [TransferPlan.AccountAllocation] = []

        if let emergencyAccount = accounts.emergencyAccount {
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

        if let savingsAccount = accounts.savingsDestination, remainingSavings > 0 {
            allocations.append(TransferPlan.AccountAllocation(account: savingsAccount, amount: remainingSavings))
            remainingSavings = 0
        }

        let totalAllocated = totalSavings - remainingSavings
        return (allocations, totalAllocated)
    }
}

// MARK: - Split Mode (Independent Amounts)

private extension TransferCalculator {

    /// Returns: (allocations, totalAllocated)
    static func distributeSplitToAccounts(
        allocation: SavingsAllocationEntry,
        availableIncome: Decimal,
        accounts: [AccountEntry],
        monthlyIncome: Decimal
    ) -> ([TransferPlan.AccountAllocation], Decimal) {
        var allocations: [TransferPlan.AccountAllocation] = []
        var totalAllocated: Decimal = 0

        var requestedEmergency = allocation.resolvedSplitEmergencyAmount(availableIncome: availableIncome)
        var requestedSavings = allocation.resolvedSplitSavingsAmount(availableIncome: availableIncome)
        let requestedTotal = requestedEmergency + requestedSavings
        guard requestedTotal > 0 else { return (allocations, totalAllocated) }

        // Proportional reduction if total exceeds available income. Emergency's share is rounded to
        // cents and savings takes the exact remainder, so the two still add up to what's available
        // (a raw ratio leaves 666.66…67 + 333.33…33 = 999.99…99).
        if requestedTotal > availableIncome {
            requestedEmergency = (availableIncome * requestedEmergency / requestedTotal).roundedToCents
            requestedSavings = availableIncome - requestedEmergency
        }

        var emergencyOverflow: Decimal = 0

        if let emergencyAccount = accounts.emergencyAccount {
            let requestedAmount = requestedEmergency

            if requestedAmount > 0 {
                if let target = emergencyAccount.emergencyTarget(monthlyIncome: monthlyIncome) {
                    let remaining = max(0, target - emergencyAccount.currentBalance)

                    if remaining <= 0 {
                        emergencyOverflow = requestedAmount
                    } else {
                        let actualAmount = min(requestedAmount, remaining)
                        emergencyOverflow = requestedAmount - actualAmount

                        let emergencyAlloc = calculateEmergencyAllocation(
                            account: emergencyAccount,
                            availableSavings: actualAmount,
                            monthlyIncome: monthlyIncome
                        )
                        if emergencyAlloc.amount > 0 || emergencyAlloc.targetAmount != nil {
                            allocations.append(emergencyAlloc)
                            totalAllocated += emergencyAlloc.amount
                        }
                    }
                } else {
                    // No target set — allocate fully
                    let emergencyAlloc = TransferPlan.AccountAllocation(
                        account: emergencyAccount,
                        amount: requestedAmount
                    )
                    allocations.append(emergencyAlloc)
                    totalAllocated += requestedAmount
                }
            }
        }

        if let savingsAccount = accounts.savingsDestination {
            let savingsTotal = requestedSavings + emergencyOverflow

            if savingsTotal > 0 {
                let savingsAlloc = TransferPlan.AccountAllocation(
                    account: savingsAccount,
                    amount: savingsTotal
                )
                allocations.append(savingsAlloc)
                totalAllocated += savingsTotal
            }
        }

        return (allocations, totalAllocated)
    }
}

// MARK: - Shared Helpers

private extension TransferCalculator {

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

        let currentBalance = account.currentBalance
        let remaining = max(0, target - currentBalance)

        let amountToAllocate = min(remaining, availableSavings)

        let progressBefore = account.emergencyProgress(monthlyIncome: monthlyIncome) ?? 0
        let newBalance = currentBalance + amountToAllocate
        let progressAfter = target > 0 ? min(1.0, Double(truncating: (newBalance / target) as NSNumber)) : 0

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

    /// Linked-account transfers are paid first (the bills are due there), scaled proportionally if
    /// they alone exceed `income`; primary keeps what is left. Cents-rounded, remainder to the last.
    /// Returns: (remainsInPrimary, accountExpenseTransfers)
    static func payWithinIncome(
        _ income: Decimal,
        transfers: [TransferPlan.AccountExpenseTransfer]
    ) -> (Decimal, [TransferPlan.AccountExpenseTransfer]) {
        let transferTotal = transfers.reduce(0) { $0 + $1.amount }
        guard transferTotal > income else { return (income - transferTotal, transfers) }

        var paidSoFar: Decimal = 0
        let scaled = transfers.enumerated().map { index, transfer in
            let amount = index == transfers.count - 1
                ? income - paidSoFar
                : (income * transfer.amount / transferTotal).roundedToCents
            paidSoFar += amount
            return TransferPlan.AccountExpenseTransfer(
                accountId: transfer.accountId,
                accountName: transfer.accountName,
                amount: amount,
                expenseNames: transfer.expenseNames
            )
        }
        return (0, scaled)
    }

    /// An expense stays in primary when it is unlinked, linked to the primary account itself, or
    /// linked to an account that no longer exists (links are loose UUIDs with no referential
    /// integrity). Moving money to a missing account would make it vanish; moving it to primary
    /// would be wiped when the reconciler resets primary to `remainsInPrimary`.
    ///
    /// Transfers are ordered like `accounts`, so the plan reads the same on every launch.
    /// Returns: (remainsInPrimary, accountExpenseTransfers)
    static func distributeExpenses(
        expenses: [ExpenseEntry],
        accounts: [AccountEntry]
    ) -> (Decimal, [TransferPlan.AccountExpenseTransfer]) {
        let transferTargets = accounts.filter { !$0.isPrimary }
        let transferTargetIds = Set(transferTargets.map(\.id))

        var remainsInPrimary: Decimal = 0
        var expensesByAccount: [UUID: [ExpenseEntry]] = [:]
        for expense in expenses {
            if let accountId = expense.linkedAccountId, transferTargetIds.contains(accountId) {
                expensesByAccount[accountId, default: []].append(expense)
            } else {
                remainsInPrimary += expense.monthlyAmount
            }
        }

        let transfers = transferTargets.compactMap { account -> TransferPlan.AccountExpenseTransfer? in
            guard let linkedExpenses = expensesByAccount.removeValue(forKey: account.id) else { return nil }
            return TransferPlan.AccountExpenseTransfer(
                accountId: account.id,
                accountName: account.name,
                amount: linkedExpenses.reduce(0) { $0 + $1.monthlyAmount }.roundedToCents,
                expenseNames: linkedExpenses.map(\.name)
            )
        }

        return (remainsInPrimary.roundedToCents, transfers)
    }
}
