import Foundation
import Observation
import Domain

/// State for the three-step New Month flow (salary → reconcile → transfer plan).
///
/// Seeded from the dashboard at creation so the first step's amount field has its
/// value before any `onAppear` runs. The transfer plan is always derived from the
/// current inputs, so the plan shown in step 3 and the one handed back on completion
/// are the same by construction.
@MainActor
@Observable
final class NewMonthFlowModel {
    enum Step: Int, CaseIterable {
        case salaryEntry = 1
        case reconcileAccounts
        case transferPlan
    }

    private(set) var step: Step = .salaryEntry

    /// Income on record when the flow started, shown as a hint in step 1.
    let lastMonthIncome: Decimal

    /// Salary entered in step 1. Defaults to last month's income.
    var income: Decimal

    /// Balances entered in step 2, keyed by account ID. Seeded with current balances.
    var balances: [UUID: Decimal]

    @ObservationIgnored private let dashboard: DashboardViewModel

    init(dashboard: DashboardViewModel) {
        self.dashboard = dashboard
        self.lastMonthIncome = dashboard.monthlyIncome
        self.income = dashboard.monthlyIncome
        self.balances = Dictionary(
            dashboard.accounts.map { ($0.id, $0.currentBalance) },
            uniquingKeysWith: { first, _ in first }
        )
    }

    /// Every non-primary account: money may have been spent from any of them (rent out of
    /// Joint, for example), and an unreconciled balance would only ever grow. Primary is
    /// excluded because the plan sets it.
    var reconcilableAccounts: [DashboardAccount] {
        dashboard.accounts.filter { !$0.isPrimary }
    }

    /// Reconciled balance for an account; falls back to its balance on record.
    /// Exposed as a subscript so views can bind to it with `$flow[balanceFor: id]`.
    subscript(balanceFor accountID: UUID) -> Decimal {
        get {
            balances[accountID]
                ?? dashboard.accounts.first { $0.id == accountID }?.currentBalance
                ?? 0
        }
        set { balances[accountID] = newValue }
    }

    var plan: TransferPlan {
        dashboard.calculateTransferPlan(withIncome: income, reconciledBalances: balances)
    }

    var canContinue: Bool {
        switch step {
        case .salaryEntry: income > 0
        case .reconcileAccounts, .transferPlan: true
        }
    }

    var isFirstStep: Bool { step == .salaryEntry }

    func advance() {
        guard canContinue, let next = Step(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    /// Data handed back to the app when the user confirms the transfers.
    var completionData: NewMonthCompletionData {
        NewMonthCompletionData(income: income, transferPlan: plan, reconciledBalances: balances)
    }
}
