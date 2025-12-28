import Foundation
import Testing
@testable import Onboarding
import Utilities

/// Tests for OnboardingViewModel - validates the 7-screen onboarding flow,
/// state management, and computed properties.
///
/// Note: All nested suites must be @MainActor since OnboardingViewModel is MainActor-isolated.
@Suite("OnboardingViewModel Tests")
@MainActor
struct OnboardingViewModelTests {

    // MARK: - Initial State

    @Suite("Initial State")
    @MainActor
    struct InitialState {

        @Test("Initial step is welcome")
        func initialStepIsWelcome() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.currentStep == .welcome)
        }

        @Test("Initial name is empty")
        func initialNameEmpty() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.name == "")
        }

        @Test("Initial income is zero")
        func initialIncomeZero() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.monthlyIncome == 0)
        }

        @Test("Initial expenses has 4 default categories")
        func initialExpensesHasDefaults() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.expenses.count == 4)
        }

        @Test("Initial accounts has primary account")
        func initialAccountsHasPrimary() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.accounts.count == 1)
            #expect(viewModel.primaryAccount != nil)
        }

        @Test("Initial savings allocation at 25%")
        func initialSavingsAt25Percent() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.savingsAllocation.percentage == 0.25)
        }

        @Test("Initial remaining destination is primary savings")
        func initialRemainingDestination() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.remainingMoneyDestination == .primarySavings)
        }

        @Test("Currency detects from locale")
        func currencyFromLocale() {
            let viewModel = OnboardingViewModel()
            #expect(Currency.allCases.contains(viewModel.currency))
        }
    }

    // MARK: - Step Navigation

    @Suite("Step Navigation")
    @MainActor
    struct StepNavigation {

        @Test("7 steps in onboarding flow")
        func sevenStepsInFlow() {
            #expect(OnboardingViewModel.OnboardingStep.allCases.count == 7)
        }

        @Test("Steps in correct order")
        func stepsInCorrectOrder() {
            let steps = OnboardingViewModel.OnboardingStep.allCases

            #expect(steps[0] == .welcome)
            #expect(steps[1] == .name)
            #expect(steps[2] == .income)
            #expect(steps[3] == .accounts)
            #expect(steps[4] == .expenses)
            #expect(steps[5] == .savings)
            #expect(steps[6] == .transferPlan)
        }

        @Test("Can always advance from welcome")
        func canAdvanceFromWelcome() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.currentStep == .welcome)
            #expect(viewModel.canAdvance == true)
        }
    }

    // MARK: - Name Step Validation

    @Suite("Name Step Validation")
    @MainActor
    struct NameStepValidation {

        @Test("Cannot advance with empty name")
        func cannotAdvanceEmptyName() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .name
            viewModel.name = ""

            #expect(viewModel.canAdvance == false)
        }

        @Test("Cannot advance with whitespace-only name")
        func cannotAdvanceWhitespaceName() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .name
            viewModel.name = "   "

            #expect(viewModel.canAdvance == false)
        }

        @Test("Can advance with valid name")
        func canAdvanceValidName() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .name
            viewModel.name = "Vlad"

            #expect(viewModel.canAdvance == true)
        }

        @Test("Trimmed name removes whitespace")
        func trimmedNameRemovesWhitespace() {
            let viewModel = OnboardingViewModel()
            viewModel.name = "  Vlad  "

            #expect(viewModel.trimmedName == "Vlad")
        }

        @Test("Name length limit of 50 characters")
        func nameLengthLimit() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .name
            viewModel.name = String(repeating: "a", count: 51)

            #expect(viewModel.canAdvance == false)

            viewModel.name = String(repeating: "a", count: 50)
            #expect(viewModel.canAdvance == true)
        }

        @Test("Single character name is valid")
        func singleCharNameValid() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .name
            viewModel.name = "A"

            #expect(viewModel.canAdvance == true)
        }

        @Test("Romanian diacritics in name")
        func romanianDiacriticsHandling() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .name
            viewModel.name = "Ștefan Ionescu"

            #expect(viewModel.canAdvance == true)
            #expect(viewModel.trimmedName == "Ștefan Ionescu")
        }
    }

    // MARK: - Income Step Validation

    @Suite("Income Step Validation")
    @MainActor
    struct IncomeStepValidation {

        @Test("Cannot advance with zero income")
        func cannotAdvanceZeroIncome() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .income
            viewModel.monthlyIncome = 0

            #expect(viewModel.canAdvance == false)
        }

        @Test("Can advance with positive income")
        func canAdvancePositiveIncome() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .income
            viewModel.monthlyIncome = 1

            #expect(viewModel.canAdvance == true)
        }

        @Test("Can advance with typical salary")
        func canAdvanceTypicalSalary() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .income
            viewModel.monthlyIncome = 14303

            #expect(viewModel.canAdvance == true)
        }
    }

    // MARK: - Accounts Step Validation

    @Suite("Accounts Step Validation")
    @MainActor
    struct AccountsStepValidation {

        @Test("Can advance when primary account exists")
        func canAdvanceWithPrimary() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .accounts

            // Default has primary account
            #expect(viewModel.canAdvance == true)
        }

        @Test("Cannot advance without primary account")
        func cannotAdvanceWithoutPrimary() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .accounts
            viewModel.accounts = [.savings()] // No primary

            #expect(viewModel.canAdvance == false)
        }
    }

    // MARK: - Optional Steps

    @Suite("Optional Steps")
    @MainActor
    struct OptionalSteps {

        @Test("Can always advance from expenses")
        func canAlwaysAdvanceFromExpenses() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .expenses
            #expect(viewModel.canAdvance == true)
        }

        @Test("Can always advance from savings")
        func canAlwaysAdvanceFromSavings() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .savings
            #expect(viewModel.canAdvance == true)
        }

        @Test("Can always advance from transfer plan")
        func canAlwaysAdvanceFromTransferPlan() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .transferPlan
            #expect(viewModel.canAdvance == true)
        }
    }

    // MARK: - Account Computed Properties

    @Suite("Account Computed Properties")
    @MainActor
    struct AccountComputedProperties {

        @Test("Primary account returns first primary")
        func primaryAccountReturnsFirst() {
            let viewModel = OnboardingViewModel()

            #expect(viewModel.primaryAccount != nil)
            #expect(viewModel.primaryAccount?.isPrimary == true)
        }

        @Test("Emergency account returns emergency type")
        func emergencyAccountReturnsCorrectType() {
            let viewModel = OnboardingViewModel()
            viewModel.accounts.append(.emergency())

            #expect(viewModel.emergencyAccount != nil)
            #expect(viewModel.emergencyAccount?.accountType == .emergency)
        }

        @Test("Has emergency account flag")
        func hasEmergencyAccountFlag() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.hasEmergencyAccount == false)

            viewModel.accounts.append(.emergency())
            #expect(viewModel.hasEmergencyAccount == true)
        }

        @Test("Primary savings account returns correct account")
        func primarySavingsAccountCorrect() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.primarySavingsAccount == nil)

            viewModel.accounts.append(.savings(isPrimarySavings: true))
            #expect(viewModel.primarySavingsAccount != nil)
            #expect(viewModel.primarySavingsAccount?.isPrimarySavings == true)
        }

        @Test("Has primary savings flag")
        func hasPrimarySavingsFlag() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.hasPrimarySavingsAccount == false)

            viewModel.accounts.append(.savings(isPrimarySavings: true))
            #expect(viewModel.hasPrimarySavingsAccount == true)
        }

        @Test("Personal account returns personal type")
        func personalAccountReturnsCorrectType() {
            let viewModel = OnboardingViewModel()
            viewModel.accounts.append(.personal())

            #expect(viewModel.personalAccount != nil)
            #expect(viewModel.personalAccount?.accountType == .personal)
        }

        @Test("All accounts returns accounts array")
        func allAccountsReturnsArray() {
            let viewModel = OnboardingViewModel()
            viewModel.accounts.append(.emergency())
            viewModel.accounts.append(.savings())

            #expect(viewModel.allAccounts.count == 3)
        }
    }

    // MARK: - Progress Tracking

    @Suite("Progress Tracking")
    @MainActor
    struct ProgressTracking {

        @Test("Total steps is 7")
        func totalStepsIs7() {
            let viewModel = OnboardingViewModel()
            #expect(viewModel.totalSteps == 7)
        }

        @Test("Current step index matches step")
        func currentStepIndexMatches() {
            let viewModel = OnboardingViewModel()

            viewModel.currentStep = .welcome
            #expect(viewModel.currentStepIndex == 0)

            viewModel.currentStep = .name
            #expect(viewModel.currentStepIndex == 1)

            viewModel.currentStep = .transferPlan
            #expect(viewModel.currentStepIndex == 6)
        }

        @Test("Progress at welcome is 0")
        func progressAtWelcome() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .welcome
            #expect(viewModel.progress == 0.0)
        }

        @Test("Progress at transfer plan is 1")
        func progressAtTransferPlan() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .transferPlan
            #expect(viewModel.progress == 1.0)
        }
    }

    // MARK: - Transfer Plan Integration

    @Suite("Transfer Plan Integration")
    @MainActor
    struct TransferPlanIntegration {

        @Test("Transfer plan uses current values")
        func transferPlanUsesCurrentValues() {
            let viewModel = OnboardingViewModel()
            viewModel.monthlyIncome = 10000
            viewModel.expenses = [ExpenseEntry(name: "Rent", amount: 3000, icon: "house")]
            viewModel.savingsAllocation.percentage = 0.20

            let plan = viewModel.transferPlan

            #expect(plan.income == 10000)
            #expect(plan.totalExpenses == 3000)
            #expect(plan.availableIncome == 7000)
        }

        @Test("Transfer plan reflects account changes")
        func transferPlanReflectsAccountChanges() {
            let viewModel = OnboardingViewModel()
            viewModel.monthlyIncome = 10000
            viewModel.accounts.append(.savings(isPrimarySavings: true))

            let plan = viewModel.transferPlan

            #expect(plan.savingsAllocation != nil)
        }

        @Test("Transfer plan uses remaining destination")
        func transferPlanUsesRemainingDestination() {
            let viewModel = OnboardingViewModel()
            viewModel.remainingMoneyDestination = .personal

            let plan = viewModel.transferPlan

            #expect(plan.remainingDestination == .personal)
        }
    }

    // MARK: - Default Expense Categories

    @Suite("Default Expense Categories")
    @MainActor
    struct DefaultExpenseCategories {

        @Test("Default expenses have zero amounts")
        func defaultExpensesZeroAmounts() {
            let viewModel = OnboardingViewModel()

            for expense in viewModel.expenses {
                #expect(expense.amount == 0)
            }
        }

        @Test("Default expenses have icons")
        func defaultExpensesHaveIcons() {
            let viewModel = OnboardingViewModel()

            for expense in viewModel.expenses {
                #expect(!expense.icon.isEmpty)
            }
        }

        @Test("Default expenses are unlinked")
        func defaultExpensesUnlinked() {
            let viewModel = OnboardingViewModel()

            for expense in viewModel.expenses {
                #expect(expense.linkedAccountId == nil)
            }
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    @MainActor
    struct EdgeCases {

        @Test("Multiple operations don't corrupt state")
        func multipleOperationsSafe() {
            let viewModel = OnboardingViewModel()

            // Simulate user flow
            viewModel.name = "Test User"
            viewModel.monthlyIncome = 5000
            viewModel.expenses[0].amount = 1000
            viewModel.accounts.append(.emergency())
            viewModel.accounts.append(.savings())
            viewModel.savingsAllocation.percentage = 0.30
            viewModel.savingsAllocation.boostEnabled = true
            viewModel.remainingMoneyDestination = .personal

            // Verify state is consistent
            #expect(viewModel.trimmedName == "Test User")
            #expect(viewModel.hasEmergencyAccount == true)
            #expect(viewModel.hasPrimarySavingsAccount == true)
            #expect(viewModel.transferPlan.isBalanced)
        }

        @Test("Empty accounts array handled")
        func emptyAccountsArrayHandled() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .accounts
            viewModel.accounts = []

            #expect(viewModel.primaryAccount == nil)
            #expect(viewModel.emergencyAccount == nil)
            #expect(viewModel.hasEmergencyAccount == false)
            #expect(viewModel.canAdvance == false)
        }

        @Test("Very large income values")
        func veryLargeIncomeValues() {
            let viewModel = OnboardingViewModel()
            viewModel.currentStep = .income
            viewModel.monthlyIncome = Decimal(string: "999999999999")!

            #expect(viewModel.canAdvance == true)
            #expect(viewModel.transferPlan.isBalanced)
        }
    }
}
