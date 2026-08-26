import Domain
import Foundation
import Utilities

/// Applies an onboarding payload, reproducing `OnboardingViewModel.save` step for step.
public enum OnboardingService {

    private static let pickers = PickerAssembler()

    /// Builds the Domain values the calculator needs from a payload.
    static func inputs(
        _ payload: OnboardingPayload
    ) -> (
        income: Decimal,
        accounts: [AccountEntry],
        expenses: [ExpenseEntry],
        allocation: SavingsAllocationEntry,
        destination: RemainingMoneyDestination,
        currency: Currency
    ) {
        let accounts = payload.accounts.map { $0.toEntry() }
        let expenses = payload.expenses.map { $0.toEntry() }
        let allocation = (payload.savings ?? SavingsPayload()).toRecord().toEntry()
        let destination = payload.remainingMoneyDestination ?? .primarySavings
        let currency = payload.currencyCode.flatMap(Currency.init(rawValue:)) ?? .fromLocale()
        return (payload.monthlyIncome.value, accounts, expenses, allocation, destination, currency)
    }

    static func plan(for payload: OnboardingPayload) -> TransferPlan {
        let input = inputs(payload)
        // Onboarding entries are all `.monthly`, so raw `amount` is already the monthly value —
        // which is what `TransferCalculator` sums. Same as `OnboardingViewModel.transferPlan`.
        return TransferCalculator.calculate(
            income: input.income,
            expenses: input.expenses,
            allocation: input.allocation,
            accounts: input.accounts,
            remainingDestination: input.destination
        )
    }

    /// Live numbers for onboarding steps 5–7. Persists nothing.
    public static func preview(
        _ payload: OnboardingPayload,
        assembler: StateAssembler
    ) -> OnboardingPreviewResponse {
        let input = inputs(payload)
        let plan = plan(for: payload)
        let money = MoneyFormatter(currency: input.currency)

        return OnboardingPreviewResponse(
            availableIncome: money(plan.availableIncome),
            // The number behind step 6's "That's 1,182 RON/month".
            savingsAmount: money(input.allocation.calculateSavings(availableIncome: plan.availableIncome)),
            totalExpenses: money(plan.totalExpenses),
            accounts: input.accounts.enumerated().map { index, entry in
                assembler.account(from: entry, sortOrder: index, income: input.income, money: money)
            },
            transferPlan: assembler.transferPlan(plan, money: money),
            savingsSliderPositions: pickers.savingsSliderPositions(
                allocation: input.allocation, availableIncome: plan.availableIncome, money: money
            ),
            splitSliderPositions: pickers.splitSliderPositions(
                availableIncome: plan.availableIncome, money: money
            ),
            split: pickers.split(
                allocation: input.allocation,
                availableIncome: plan.availableIncome,
                plan: plan,
                money: money
            ),
            boostedPercentDisplay: pickers.boostedPercentDisplay(input.allocation)
        )
    }

    /// Commits onboarding, mirroring `OnboardingViewModel.save`.
    ///
    /// One deliberate divergence: iOS's `Account(from:)` regenerates the account UUID on save,
    /// orphaning the ids onboarding used for `linkedAccountId`. We keep the ids the client sent.
    /// Observationally identical (iOS immediately re-reads from the store) and it avoids
    /// creating dangling references.
    public static func apply(_ payload: OnboardingPayload, to document: inout StoreDocument) {
        let input = inputs(payload)
        let plan = plan(for: payload)

        document.profile = ProfileRecord(
            name: payload.name.trimmingCharacters(in: .whitespacesAndNewlines),
            currencyCode: input.currency.rawValue,
            remainingMoneyDestination: input.destination
        )

        document.income = IncomeRecord(amount: input.income, frequency: .monthly)
        document.savings = (payload.savings ?? SavingsPayload()).toRecord()

        // `for expense in expenses where expense.amount > 0` — zero rows are dropped, not saved.
        document.expenses = input.expenses
            .filter { $0.amount > 0 }
            .enumerated()
            .map { ExpenseRecord($1, sortOrder: $0) }

        // Balances assume the user made the transfers the plan describes.
        var accounts = input.accounts
        for allocation in plan.accountAllocations {
            if let index = accounts.firstIndex(where: { $0.id == allocation.accountId }) {
                accounts[index].currentBalance += allocation.amount
            }
        }
        for transfer in plan.accountExpenseTransfers {
            if let index = accounts.firstIndex(where: { $0.id == transfer.accountId }) {
                accounts[index].currentBalance += transfer.amount
            }
        }
        if let index = accounts.firstIndex(where: { $0.isPrimary }) {
            accounts[index].currentBalance = plan.remainsInPrimary
        }
        if plan.remainingMoney > 0 {
            switch input.destination {
            case .primarySavings:
                if let index = accounts.firstIndex(where: { $0.isPrimarySavings }) {
                    accounts[index].currentBalance += plan.remainingMoney
                }
            case .personal:
                if let index = accounts.firstIndex(where: { $0.accountType == .personal }) {
                    accounts[index].currentBalance += plan.remainingMoney
                }
            case .primary:
                // Note: onboarding *adds* to primary here, unlike the New Month flow which
                // leaves it at remainsInPrimary. Faithful to `OnboardingViewModel.save`.
                if let index = accounts.firstIndex(where: { $0.isPrimary }) {
                    accounts[index].currentBalance += plan.remainingMoney
                }
            }
        }

        document.accounts = accounts.enumerated().map { AccountRecord($1, sortOrder: $0) }
    }
}
