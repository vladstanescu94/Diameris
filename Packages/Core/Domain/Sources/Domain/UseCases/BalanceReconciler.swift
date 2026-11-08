import Foundation

/// Applies a `TransferPlan` to account balances: "the user made the transfers — what are the
/// balances now?" Every caller (New Month, onboarding completion) delegates here.
public enum BalanceReconciler {

    /// The outcome of applying a plan, including anything the plan could **not** place.
    public struct Reconciliation: Sendable, Equatable {
        /// Covers every account passed in.
        public let balances: [UUID: Decimal]

        /// Remaining money whose destination role (primary savings / personal) no account fills.
        /// It stays in — and is included in — the primary balance; reported so callers can warn.
        /// Always zero for `.primary`, where staying in primary is intended.
        public let unallocatedRemainingMoney: Decimal

        /// Ids referenced by the plan or `reconciledBalances` but missing from `accounts` — the
        /// caller passed an incomplete account list.
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

    /// Order is load-bearing:
    /// 1. Seed each account from `reconciledBalances`, else its **own** `currentBalance` — an
    ///    account the user did not reconcile (e.g. Joint) keeps its balance, never restarts at 0.
    /// 2. Add savings allocations, then 3. expense-linked transfers, then 4. remaining money to the
    ///    account its destination names.
    /// 5. **Set** (not add) primary to `remainsInPrimary` — the month's expense float — plus any
    ///    remaining money that never left primary (`.primary`, or a destination nobody fills).
    ///
    /// - Parameters:
    ///   - accounts: **Every** account in play; omitting one the plan touches is reported via
    ///     `unknownAccountIds`.
    ///   - reconciledBalances: Balances the user confirmed, by account id. May be partial.
    public static func reconcile(
        plan: TransferPlan,
        accounts: [AccountEntry],
        reconciledBalances: [UUID: Decimal]
    ) -> Reconciliation {
        var balances: [UUID: Decimal] = [:]
        for account in accounts {
            balances[account.id] = reconciledBalances[account.id] ?? account.currentBalance
        }

        let knownIds = Set(accounts.map(\.id))
        var unknownAccountIds: Set<UUID> = []

        for id in reconciledBalances.keys where !knownIds.contains(id) {
            unknownAccountIds.insert(id)
            balances[id] = reconciledBalances[id]
        }

        for allocation in plan.accountAllocations {
            if !knownIds.contains(allocation.accountId) {
                unknownAccountIds.insert(allocation.accountId)
            }
            balances[allocation.accountId, default: 0] += allocation.amount
        }

        for expenseTransfer in plan.accountExpenseTransfers {
            if !knownIds.contains(expenseTransfer.accountId) {
                unknownAccountIds.insert(expenseTransfer.accountId)
            }
            balances[expenseTransfer.accountId, default: 0] += expenseTransfer.amount
        }

        var unallocated: Decimal = 0
        var keptInPrimary: Decimal = 0
        if plan.remainingMoney > 0 {
            switch plan.remainingDestination {
            case .primarySavings:
                if let savingsAccount = accounts.savingsDestination {
                    balances[savingsAccount.id, default: 0] += plan.remainingMoney
                } else {
                    unallocated = plan.remainingMoney
                }
            case .personal:
                if let personalAccount = accounts.first(where: { $0.accountType == .personal }) {
                    balances[personalAccount.id, default: 0] += plan.remainingMoney
                } else {
                    unallocated = plan.remainingMoney
                }
            case .primary:
                keptInPrimary = plan.remainingMoney
            }
        }

        if let primaryAccount = accounts.first(where: { $0.isPrimary }) {
            balances[primaryAccount.id] = plan.remainsInPrimary + keptInPrimary + unallocated
        }

        return Reconciliation(
            balances: balances,
            unallocatedRemainingMoney: unallocated,
            unknownAccountIds: unknownAccountIds
        )
    }

    public static func updatedBalances(
        plan: TransferPlan,
        accounts: [AccountEntry],
        reconciledBalances: [UUID: Decimal]
    ) -> [UUID: Decimal] {
        reconcile(plan: plan, accounts: accounts, reconciledBalances: reconciledBalances).balances
    }
}
