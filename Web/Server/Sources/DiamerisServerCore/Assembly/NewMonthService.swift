import Domain
import Foundation

/// The New Month flow: recompute the plan against the user's reconciled balances, then apply it.
///
/// Both the balance projection and the plan come from `Domain` — `BalanceReconciler` and
/// `TransferCalculator` respectively. Nothing is recomputed here.
public enum NewMonthService {

    private static func planAndBalances(
        _ payload: NewMonthPayload,
        document: StoreDocument
    ) -> (plan: TransferPlan, accounts: [AccountEntry], reconciliation: BalanceReconciler.Reconciliation) {
        let reconciled = payload.balances()

        // Substitute the balances the user confirmed; untouched accounts keep the stored value.
        // Same as `DashboardViewModel.makeAccountEntries(reconciledBalances:)`.
        let accounts: [AccountEntry] = document.accounts.map { record in
            var entry = record.toEntry()
            if let balance = reconciled[record.id] {
                entry.currentBalance = balance
            }
            return entry
        }

        let expenses = document.expenses
            .filter(\.isEnabled)
            .map { record in
                ExpenseEntry(
                    name: record.name,
                    amount: record.toEntry().monthlyAmount,
                    icon: record.icon,
                    linkedAccountId: record.linkedAccountId
                )
            }

        let plan = TransferCalculator.calculate(
            income: payload.income.value,
            expenses: expenses,
            allocation: document.savings.toEntry(),
            accounts: accounts,
            remainingDestination: document.profile?.remainingMoneyDestination ?? .primarySavings
        )

        // `BalanceReconciler` seeds any un-reconciled account from its own `currentBalance`, so
        // a partial `reconciledBalances` is safe — an account the user never saw (a Joint account
        // receiving an expense transfer, say) keeps its balance instead of restarting at zero.
        let reconciliation = BalanceReconciler.reconcile(
            plan: plan,
            accounts: accounts,
            reconciledBalances: reconciled
        )

        return (plan, accounts, reconciliation)
    }

    /// Step 3 of the flow: the plan and the balances committing would produce. Persists nothing.
    public static func preview(
        _ payload: NewMonthPayload,
        document: StoreDocument,
        assembler: StateAssembler
    ) -> NewMonthPreviewResponse {
        let result = planAndBalances(payload, document: document)
        let money = MoneyFormatter(currency: document.currency)

        return NewMonthPreviewResponse(
            transferPlan: assembler.transferPlan(result.plan, money: money),
            // Non-nil only when `remainingDestination` names a role no account fills, so the
            // money genuinely lands nowhere. The client should warn rather than show the
            // "All amounts add up correctly" banner.
            unallocatedRemainingMoney: result.reconciliation.unallocatedRemainingMoney > 0
                ? money(result.reconciliation.unallocatedRemainingMoney)
                : nil,
            projectedBalances: document.accounts
                .sorted { ($0.sortOrder, $0.createdAt) < ($1.sortOrder, $1.createdAt) }
                .map { record in
                    ProjectedBalanceDTO(
                        accountId: record.id,
                        accountName: record.name,
                        before: money(record.currentBalance.value),
                        after: money(result.reconciliation.balances[record.id] ?? record.currentBalance.value)
                    )
                }
        )
    }

    /// Commits the month: writes income, then the projected balances.
    /// Mirrors `MainTabView.handleNewMonthCompletion`.
    public static func commit(_ payload: NewMonthPayload, to document: inout StoreDocument) {
        let result = planAndBalances(payload, document: document)

        if document.income == nil {
            document.income = IncomeRecord(amount: payload.income.value)
        } else {
            document.income?.amount = payload.income
        }

        for index in document.accounts.indices {
            if let balance = result.reconciliation.balances[document.accounts[index].id] {
                document.accounts[index].currentBalance = DecimalString(balance)
            }
        }
    }
}
