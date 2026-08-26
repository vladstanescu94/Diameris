import Foundation

/// Applies a `TransferPlan` to a set of account balances.
///
/// This is the "the user says they made the transfers — what are the balances now?" rule. It is
/// business logic, so per the project's *Business Logic Lives in Domain Only* rule it belongs
/// here, with every other layer delegating: `DashboardViewModel.computeUpdatedBalances` (the New
/// Month flow) and the web server both call this rather than each keeping a copy.
public enum BalanceReconciler {

    /// The outcome of applying a plan, including anything the plan could **not** place.
    public struct Reconciliation: Sendable, Equatable {
        /// Updated balance per account id. Covers every account passed in.
        public let balances: [UUID: Decimal]

        /// Remaining money that had nowhere to go.
        ///
        /// `remainingDestination` names a *role* (primary savings / personal), and the user may
        /// simply not have an account in that role — in which case the money is not added to any
        /// balance. Surfacing it here means a caller can warn instead of silently dropping it.
        /// Zero in the normal case, and always zero for `.primary`, where "remains in primary"
        /// is the intended destination and is assigned directly.
        public let unallocatedRemainingMoney: Decimal

        /// Account ids referenced by the plan that were not in `accounts`. Non-empty means the
        /// caller passed an incomplete account list — a dangling `linkedAccountId`, most likely,
        /// since those are loose UUIDs with no referential integrity.
        public let unknownAccountIds: Set<UUID>

        public init(
            balances: [UUID: Decimal],
            unallocatedRemainingMoney: Decimal = 0,
            unknownAccountIds: Set<UUID> = []
        ) {
            self.balances = balances
            self.unallocatedRemainingMoney = unallocatedRemainingMoney
            self.unknownAccountIds = unknownAccountIds
        }
    }

    /// Computes each account's balance after a transfer plan is executed.
    ///
    /// Order matters and is load-bearing:
    /// 1. Start from each account's **own** balance, overridden by `reconciledBalances` where the
    ///    user supplied one. An account the caller did not reconcile keeps what it already had —
    ///    it does not restart from zero.
    /// 2. Add every savings allocation (emergency, then savings).
    /// 3. Add every expense-linked transfer (e.g. Food paid from a Joint account).
    /// 4. Add the remaining money to whichever account the destination names.
    /// 5. **Overwrite** the primary account with `remainsInPrimary` — it is set, not added,
    ///    because what stays in primary is the month's expense float, not an accumulation.
    ///
    /// - Parameters:
    ///   - plan: The plan being executed.
    ///   - accounts: **Every** account in play. Their `currentBalance` seeds step 1 and their
    ///     `isPrimary` / `isPrimarySavings` / `accountType` flags resolve the roles that
    ///     `remainingDestination` refers to. Omitting an account the plan touches is a caller
    ///     error, reported back via `unknownAccountIds`.
    ///   - reconciledBalances: Balances the user confirmed, by account id. May be partial.
    public static func reconcile(
        plan: TransferPlan,
        accounts: [AccountEntry],
        reconciledBalances: [UUID: Decimal]
    ) -> Reconciliation {
        // Step 1 — seed from each account's real balance, not from zero. Defaulting an
        // un-reconciled account to 0 would silently wipe it the moment the plan touched it
        // (a Joint account receiving an expense transfer, for instance, is never part of the
        // New Month reconcile step and would otherwise lose its balance).
        var balances: [UUID: Decimal] = [:]
        for account in accounts {
            balances[account.id] = reconciledBalances[account.id] ?? account.currentBalance
        }

        let knownIds = Set(accounts.map(\.id))
        var unknownAccountIds: Set<UUID> = []

        // Any reconciled id we were not given an account for is also worth reporting.
        for id in reconciledBalances.keys where !knownIds.contains(id) {
            unknownAccountIds.insert(id)
            balances[id] = reconciledBalances[id]
        }

        // Step 2 — savings allocations (emergency, savings accounts)
        for allocation in plan.accountAllocations {
            if !knownIds.contains(allocation.accountId) {
                unknownAccountIds.insert(allocation.accountId)
            }
            balances[allocation.accountId, default: 0] += allocation.amount
        }

        // Step 3 — expense-linked transfers (e.g., Food → Joint)
        for expenseTransfer in plan.accountExpenseTransfers {
            if !knownIds.contains(expenseTransfer.accountId) {
                unknownAccountIds.insert(expenseTransfer.accountId)
            }
            balances[expenseTransfer.accountId, default: 0] += expenseTransfer.amount
        }

        // Step 4 — remaining money goes to the designated role, if an account fills it.
        var unallocated: Decimal = 0
        if plan.remainingMoney > 0 {
            switch plan.remainingDestination {
            case .primarySavings:
                if let savingsAccount = accounts.first(where: { $0.isPrimarySavings }) {
                    balances[savingsAccount.id, default: 0] += plan.remainingMoney
                } else {
                    // No primary-savings account exists, so this money lands nowhere. Reported
                    // rather than dropped on the floor.
                    unallocated = plan.remainingMoney
                }
            case .personal:
                if let personalAccount = accounts.first(where: { $0.accountType == .personal }) {
                    balances[personalAccount.id, default: 0] += plan.remainingMoney
                } else {
                    unallocated = plan.remainingMoney
                }
            case .primary:
                // Intended: it stays in primary, which step 5 assigns outright.
                break
            }
        }

        // Step 5 — primary holds exactly what stays for expenses; assigned, not accumulated.
        if let primaryAccount = accounts.first(where: { $0.isPrimary }) {
            balances[primaryAccount.id] = plan.remainsInPrimary
        }

        return Reconciliation(
            balances: balances,
            unallocatedRemainingMoney: unallocated,
            unknownAccountIds: unknownAccountIds
        )
    }

    /// Convenience for callers that only need the balances.
    public static func updatedBalances(
        plan: TransferPlan,
        accounts: [AccountEntry],
        reconciledBalances: [UUID: Decimal]
    ) -> [UUID: Decimal] {
        reconcile(plan: plan, accounts: accounts, reconciledBalances: reconciledBalances).balances
    }
}
