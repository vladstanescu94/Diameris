import Foundation
import Testing
@testable import Onboarding
import Domain

/// What onboarding hands the app to persist (`OnboardingViewModel.makeResult()`).
@MainActor
struct OnboardingResultTests {
    let viewModel = OnboardingViewModel(keyboardDismissDelay: .zero, keyboardDismisser: {})

    @Test func `Only expenses with an amount are handed off`() {
        viewModel.expenses[0].amount = 800
        // The remaining default expenses stay at 0.

        let result = viewModel.makeResult()

        #expect(result.expenses.map(\.id) == [viewModel.expenses[0].id])
    }

    @Test func `Profile fields are trimmed and carried over`() {
        viewModel.name = "  Ana  "
        viewModel.currency = .eur
        viewModel.monthlyIncome = 6000
        viewModel.remainingMoneyDestination = .primary

        let result = viewModel.makeResult()

        #expect(result.name == "Ana")
        #expect(result.currencyCode == "EUR")
        #expect(result.monthlyIncome == 6000)
        #expect(result.remainingMoneyDestination == .primary)
    }

    @Test func `A double tap on Start hands the result off only once`() {
        viewModel.name = "Ana"

        let first = viewModel.complete()
        let second = viewModel.complete()

        #expect(first?.name == "Ana")
        #expect(second == nil)
        #expect(viewModel.hasCompleted)
    }

    @Test func `A failed save lets the user tap Start again`() {
        viewModel.name = "Ana"
        _ = viewModel.complete()

        viewModel.completionFailed()

        #expect(!viewModel.hasCompleted)
        #expect(viewModel.complete()?.name == "Ana")
    }

    /// Account ids must survive so linked expenses still point at them once stored, and
    /// balances must be the ones Domain's reconciler computes from the plan.
    @Test func `Accounts keep their ids and get the reconciled balances`() throws {
        viewModel.monthlyIncome = 10_000
        viewModel.expenses[0].amount = 2000
        let expected = BalanceReconciler.updatedBalances(
            plan: viewModel.transferPlan,
            accounts: viewModel.accounts,
            reconciledBalances: [:]
        )

        let result = viewModel.makeResult()

        #expect(result.accounts.map(\.id) == viewModel.accounts.map(\.id))
        for account in result.accounts {
            #expect(account.currentBalance == expected[account.id], "\(account.name)")
        }
    }
}
