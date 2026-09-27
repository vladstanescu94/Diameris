import Foundation
import Testing
@testable import Onboarding
import Domain

/// A view model that advances immediately and never touches UIKit.
@MainActor
private func makeViewModel() -> OnboardingViewModel {
    OnboardingViewModel(keyboardDismissDelay: .zero, keyboardDismisser: {})
}

/// Scenario tests for OnboardingViewModel: step gating, navigation guards,
/// account rules, and the savings/remaining-money choices the flow hands off.
/// Transfer math itself is covered by Domain's TransferCalculator tests.
@MainActor
struct OnboardingViewModelTests {

    // MARK: - Step Gating

    @MainActor
    struct StepGating {
        @Test(arguments: [
            ("", false),
            ("   ", false),
            ("A", true),
            ("  Vlad  ", true),
            ("Ștefan Ionescu", true),
            (String(repeating: "a", count: 50), true),
            (String(repeating: "a", count: 51), false),
        ])
        func `Name step requires 1–50 trimmed characters`(name: String, isValid: Bool) {
            let viewModel = makeViewModel()
            viewModel.currentStep = .name
            viewModel.name = name
            #expect(viewModel.canAdvance == isValid)
        }

        @Test(arguments: [(Decimal(-1), false), (0, false), (1, true), (14303, true)])
        func `Income step requires a positive amount`(income: Decimal, isValid: Bool) {
            let viewModel = makeViewModel()
            viewModel.currentStep = .income
            viewModel.monthlyIncome = income
            #expect(viewModel.canAdvance == isValid)
        }

        @Test func `Accounts step requires a primary account`() {
            let viewModel = makeViewModel()
            viewModel.currentStep = .accounts
            #expect(viewModel.canAdvance)

            viewModel.accounts = [.savings()]
            #expect(!viewModel.canAdvance)
        }

        @Test(arguments: [
            OnboardingViewModel.OnboardingStep.welcome, .expenses, .savings, .transferPlan,
        ])
        func `Optional steps never block`(step: OnboardingViewModel.OnboardingStep) {
            let viewModel = makeViewModel()
            viewModel.currentStep = step
            #expect(viewModel.canAdvance)
        }
    }

    // MARK: - Navigation

    @MainActor
    struct Navigation {
        @Test func `Valid input walks the whole flow in order`() async {
            let viewModel = makeViewModel()
            viewModel.name = "Vlad"
            viewModel.monthlyIncome = 14303

            var visited = [viewModel.currentStep]
            while let transition = viewModel.advance() {
                await transition.value
                visited.append(viewModel.currentStep)
            }

            #expect(visited == OnboardingViewModel.OnboardingStep.allCases)
        }

        @Test func `Advance is ignored while the current step is invalid`() {
            let viewModel = makeViewModel()
            viewModel.currentStep = .name
            viewModel.name = "  "

            #expect(viewModel.advance() == nil)
            #expect(viewModel.currentStep == .name)
        }

        @Test func `A double tap advances only one step`() async {
            let viewModel = makeViewModel()

            let first = viewModel.advance()
            let second = viewModel.advance()
            await first?.value

            #expect(second == nil)
            #expect(viewModel.currentStep == .name)
        }

        @Test func `Advance dismisses the keyboard`() async {
            let counter = DismissCounter()
            let viewModel = OnboardingViewModel(keyboardDismissDelay: .zero) { counter.count += 1 }

            await viewModel.advance()?.value

            #expect(counter.count == 1)
        }

        @MainActor
        final class DismissCounter {
            var count = 0
        }
    }

    // MARK: - Remaining Money Destination

    @MainActor
    struct RemainingMoneyDestinationTests {
        @Test(arguments: [
            ([AccountEntry.primary()], [RemainingMoneyDestination.primary]),
            ([.primary(), .savings()], [.primarySavings, .primary]),
            ([.primary(), .personal()], [.primary, .personal]),
            ([.primary(), .savings(), .personal()], [.primarySavings, .primary, .personal]),
        ])
        func `Only destinations backed by an account are offered`(
            accounts: [AccountEntry],
            expected: [RemainingMoneyDestination]
        ) {
            let viewModel = makeViewModel()
            viewModel.accounts = accounts
            #expect(viewModel.availableRemainingDestinations == expected)
        }

        @Test func `Reaching the plan without a savings account keeps leftovers in Primary`() async {
            let viewModel = makeViewModel()
            viewModel.currentStep = .savings
            #expect(viewModel.remainingMoneyDestination == .primarySavings)

            await viewModel.advance()?.value

            #expect(viewModel.currentStep == .transferPlan)
            #expect(viewModel.remainingMoneyDestination == .primary)
        }

        @Test func `A valid destination choice is kept`() async {
            let viewModel = makeViewModel()
            viewModel.accounts.append(.personal())
            viewModel.remainingMoneyDestination = .personal
            viewModel.currentStep = .savings

            await viewModel.advance()?.value

            #expect(viewModel.remainingMoneyDestination == .personal)
            #expect(viewModel.transferPlan.remainingDestination == .personal)
        }
    }

    // MARK: - Adding Accounts

    @MainActor
    struct AddingAccounts {
        @Test func `Only one emergency account can exist`() {
            let viewModel = makeViewModel()

            viewModel.addEmergencyAccount()
            viewModel.addEmergencyAccount()
            #expect(viewModel.addAccount(name: "Backup", type: .emergency) == false)

            #expect(viewModel.accounts.count(where: { $0.accountType == .emergency }) == 1)
        }

        @Test func `The primary role can't be added a second time`() {
            let viewModel = makeViewModel()

            #expect(viewModel.addAccount(name: "Second salary", type: .primary) == false)
            #expect(viewModel.accounts.count == 1)
        }

        @Test func `Blank names are rejected and names are trimmed`() throws {
            let viewModel = makeViewModel()

            #expect(viewModel.addAccount(name: "   ", type: .joint) == false)
            #expect(viewModel.addAccount(name: "  Joint  ", type: .joint))

            let added = try #require(viewModel.accounts.last)
            #expect(added.name == "Joint")
        }

        @Test func `A new emergency account gets a default target multiplier`() throws {
            let viewModel = makeViewModel()
            viewModel.addAccount(name: "Rainy day", type: .emergency)

            let emergency = try #require(viewModel.emergencyAccount)
            #expect(emergency.emergencyMultiplier != nil)
        }

        @Test func `The Emergency suggestion creates an emergency account and is hidden once one exists`() {
            let offered = AddAccountSheet.suggestions(canAddEmergency: true)
            #expect(offered.first { $0.name == "Emergency" }?.type == .emergency)

            let afterEmergency = AddAccountSheet.suggestions(canAddEmergency: false)
            #expect(!afterEmergency.contains { $0.type == .emergency })
        }

        @Test func `Only the first savings account becomes auto-save`() {
            let viewModel = makeViewModel()
            viewModel.addAccount(name: "Savings", type: .savings)
            viewModel.addAccount(name: "Travel", type: .savings)

            #expect(viewModel.accounts.filter(\.isPrimarySavings).map(\.name) == ["Savings"])
        }
    }

    // MARK: - Editing Accounts

    @MainActor
    struct EditingAccounts {
        @Test func `The primary account can't be deleted or retyped`() throws {
            let viewModel = makeViewModel()
            let primary = try #require(viewModel.primaryAccount)

            viewModel.deleteAccount(id: primary.id)
            viewModel.changeAccountType(id: primary.id, to: .savings)

            #expect(viewModel.accounts.count == 1)
            #expect(viewModel.primaryAccount?.accountType == .primary)
            #expect(viewModel.primaryAccount?.isPrimarySavings == false)
        }

        @Test func `Other accounts can't be retyped to Primary or a second Emergency`() throws {
            let viewModel = makeViewModel()
            viewModel.addEmergencyAccount()
            viewModel.addAccount(name: "Joint", type: .joint)
            let joint = try #require(viewModel.accounts.last)

            viewModel.changeAccountType(id: joint.id, to: .primary)
            viewModel.changeAccountType(id: joint.id, to: .emergency)

            #expect(viewModel.accounts.last?.accountType == .joint)
        }

        @Test func `Deleting an account sends its linked expenses back to Primary`() throws {
            let viewModel = makeViewModel()
            viewModel.addAccount(name: "Joint", type: .joint)
            let joint = try #require(viewModel.accounts.last)
            viewModel.expenses[1].amount = 2000
            viewModel.expenses[1].linkedAccountId = joint.id

            viewModel.deleteAccount(id: joint.id)

            #expect(viewModel.expenses.allSatisfy { $0.linkedAccountId == nil })
            #expect(viewModel.transferPlan.accountExpenseTransfers.isEmpty)
        }

        @Test func `Losing the auto-save account hands the role to another savings account`() throws {
            let viewModel = makeViewModel()
            viewModel.addAccount(name: "Savings", type: .savings)
            viewModel.addAccount(name: "Travel", type: .savings)
            let savings = try #require(viewModel.primarySavingsAccount)

            viewModel.deleteAccount(id: savings.id)

            #expect(viewModel.primarySavingsAccount?.name == "Travel")
        }

        @Test func `Retyping the auto-save account hands the role on`() throws {
            let viewModel = makeViewModel()
            viewModel.addAccount(name: "Savings", type: .savings)
            viewModel.addAccount(name: "Travel", type: .savings)
            let savings = try #require(viewModel.primarySavingsAccount)

            viewModel.changeAccountType(id: savings.id, to: .joint)

            #expect(viewModel.primarySavingsAccount?.name == "Travel")
        }

        @Test func `Retyping an account to Savings makes it auto-save when none exists`() throws {
            let viewModel = makeViewModel()
            viewModel.addAccount(name: "Joint", type: .joint)
            let joint = try #require(viewModel.accounts.last)

            viewModel.changeAccountType(id: joint.id, to: .savings)

            #expect(viewModel.primarySavingsAccount?.id == joint.id)
        }

        @Test func `Leaving the emergency type clears its target settings`() throws {
            let viewModel = makeViewModel()
            viewModel.accounts.append(.emergency(multiplier: 6, hardCap: 50_000))
            let emergency = try #require(viewModel.emergencyAccount)

            viewModel.changeAccountType(id: emergency.id, to: .other)

            let account = try #require(viewModel.accounts.last)
            #expect(account.emergencyMultiplier == nil)
            #expect(account.emergencyHardCap == nil)
        }

        @Test func `Auto-save moves between savings accounts and never to other types`() throws {
            let viewModel = makeViewModel()
            viewModel.addAccount(name: "Savings", type: .savings)
            viewModel.addAccount(name: "Travel", type: .savings)
            viewModel.addAccount(name: "Joint", type: .joint)
            let travel = viewModel.accounts[2]
            let joint = viewModel.accounts[3]

            viewModel.setPrimarySavings(id: travel.id)
            viewModel.setPrimarySavings(id: joint.id)

            #expect(viewModel.accounts.filter(\.isPrimarySavings).map(\.name) == ["Travel"])
        }

        @Test func `Renaming trims and ignores blank names`() throws {
            let viewModel = makeViewModel()
            let primary = try #require(viewModel.primaryAccount)

            viewModel.renameAccount(id: primary.id, to: "  ING  ")
            viewModel.renameAccount(id: primary.id, to: "  ")

            #expect(viewModel.primaryAccount?.name == "ING")
        }
    }

    // MARK: - Savings Boost

    @MainActor
    struct SavingsBoost {
        @Test(arguments: [(0.25, true), (0.33, true), (0.34, false), (0.50, false)])
        func `Boost is allowed only while the boosted rate stays within income`(
            percentage: Double,
            canEnable: Bool
        ) {
            let viewModel = makeViewModel()
            viewModel.savingsAllocation.percentage = percentage

            viewModel.isBoostEnabled = true

            #expect(viewModel.canEnableBoost == canEnable)
            #expect(viewModel.isBoostEnabled == canEnable)
        }

        /// 0.1627 along the 5–50% track is 12.32%, 0.9067 is 45.8%.
        @Test(arguments: [(0.0, 5), (0.1627, 12), (0.9067, 46), (1.0, 50)])
        func `Dragging stores whole percents`(fraction: Double, percent: Int) {
            #expect(SavingsSlider.percentage(atFraction: fraction) == Double(percent) / 100)
        }

        @Test(arguments: 5...50)
        func `Only rates one point from a snap value snap to it`(percent: Int) {
            let snapped = [10, 15, 20, 25, 30, 35, 40].first { abs($0 - percent) <= 1 } ?? percent
            let minimum = SavingsAllocationEntry.minimumPercentage
            let fraction = (Double(percent) / 100 - minimum) / (SavingsAllocationEntry.maximumPercentage - minimum)

            #expect(SavingsSlider.percentage(atFraction: fraction) == Double(snapped) / 100)
        }

        @Test func `Raising the rate past the threshold switches boost off`() {
            let viewModel = makeViewModel()
            viewModel.savingsAllocation.percentage = 0.30
            viewModel.isBoostEnabled = true

            viewModel.savingsAllocation.percentage = 0.40
            viewModel.disableBoostIfUnsafe()

            #expect(!viewModel.isBoostEnabled)
        }
    }

    // MARK: - Transfer Plan Inputs

    @Test func `The transfer plan reflects what the user entered`() {
        let viewModel = makeViewModel()
        viewModel.monthlyIncome = 10_000
        viewModel.expenses[0].amount = 3000
        viewModel.addSavingsAccount()

        let plan = viewModel.transferPlan

        #expect(plan.income == 10_000)
        #expect(plan.totalExpenses == 3000)
        #expect(viewModel.availableIncome == 7000)
        #expect(plan.savingsAllocation != nil)
        #expect(plan.isBalanced)
    }

    /// The plan is stored, not computed, so every input must refresh it — including edits made
    /// in place, the way bindings and the slider write them.
    @Test func `The stored transfer plan follows every input change`() throws {
        let viewModel = makeViewModel()
        func expectFreshPlan(_ comment: Comment, sourceLocation: SourceLocation = #_sourceLocation) {
            let fresh = TransferCalculator.calculate(
                income: viewModel.monthlyIncome,
                expenses: viewModel.expenses,
                allocation: viewModel.savingsAllocation,
                accounts: viewModel.accounts,
                remainingDestination: viewModel.remainingMoneyDestination
            )
            #expect(viewModel.transferPlan == fresh, comment, sourceLocation: sourceLocation)
        }

        expectFreshPlan("initial")
        viewModel.monthlyIncome = 10_000
        expectFreshPlan("income")
        viewModel.expenses[1].amount = 2500
        expectFreshPlan("expense edited in place")
        viewModel.expenses.append(ExpenseEntry(name: "Gym", amount: 1200, frequency: .annual, icon: "figure.run"))
        expectFreshPlan("expense added")
        viewModel.addEmergencyAccount()
        viewModel.addSavingsAccount()
        expectFreshPlan("accounts added")
        let emergencyId = try #require(viewModel.emergencyAccount?.id)
        viewModel.updateAccount(id: emergencyId) { $0.currentBalance = 4000 }
        expectFreshPlan("account edited")
        viewModel.expenses[1].linkedAccountId = emergencyId
        expectFreshPlan("expense linked")
        viewModel.savingsAllocation.percentage = 0.3
        expectFreshPlan("savings rate")
        viewModel.isBoostEnabled = true
        expectFreshPlan("boost")
        viewModel.savingsAllocation.allocationMode = .split
        viewModel.savingsAllocation.splitSavingsAmount = 900
        expectFreshPlan("split mode")
        viewModel.remainingMoneyDestination = .primary
        expectFreshPlan("remaining money destination")
        viewModel.deleteAccount(id: emergencyId)
        expectFreshPlan("account deleted")
        #expect(viewModel.availableIncome == viewModel.transferPlan.availableIncome)
    }
}
