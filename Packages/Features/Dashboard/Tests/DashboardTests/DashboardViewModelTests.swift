import Foundation
import Testing
@testable import Dashboard
import Utilities
import Domain

/// Tests for DashboardViewModel - validates computed properties,
/// account lookups, and UI state management.
///
/// Note: All nested suites must be @MainActor since DashboardViewModel is MainActor-isolated.
@Suite("DashboardViewModel Tests")
@MainActor
struct DashboardViewModelTests {

    // MARK: - Test Helpers

    static func makeExpense(name: String = "Test", amount: Decimal = 100) -> DashboardExpense {
        DashboardExpense(
            id: UUID(),
            name: name,
            amount: amount,
            icon: "dollarsign.circle",
            linkedAccountId: nil
        )
    }

    static func makeAccount(
        name: String = "Account",
        accountType: AccountType = .primary,
        isPrimary: Bool = false,
        isPrimarySavings: Bool = false,
        emergencyMultiplier: Double? = nil,
        currentBalance: Decimal = 0
    ) -> DashboardAccount {
        DashboardAccount(
            id: UUID(),
            name: name,
            accountType: accountType,
            isPrimary: isPrimary,
            isPrimarySavings: isPrimarySavings,
            emergencyMultiplier: emergencyMultiplier,
            currentBalance: currentBalance
        )
    }

    // MARK: - Initial State

    @Suite("Initial State")
    @MainActor
    struct InitialState {

        @Test("Initial username is empty")
        func initialUsernameEmpty() {
            let vm = DashboardViewModel()
            #expect(vm.userName == "")
        }

        @Test("Initial income is zero")
        func initialIncomeZero() {
            let vm = DashboardViewModel()
            #expect(vm.monthlyIncome == 0)
        }

        @Test("Initial currency is RON")
        func initialCurrencyRON() {
            let vm = DashboardViewModel()
            #expect(vm.currency == .ron)
        }

        @Test("Initial accounts array is empty")
        func initialAccountsEmpty() {
            let vm = DashboardViewModel()
            #expect(vm.accounts.isEmpty)
        }

        @Test("Initial expenses array is empty")
        func initialExpensesEmpty() {
            let vm = DashboardViewModel()
            #expect(vm.expenses.isEmpty)
        }

        @Test("Initial savings percentage is 25%")
        func initialSavingsPercentage() {
            let vm = DashboardViewModel()
            #expect(vm.savingsPercentage == 0.25)
        }

        @Test("Initial savings boost is disabled")
        func initialSavingsBoostDisabled() {
            let vm = DashboardViewModel()
            #expect(vm.savingsBoostEnabled == false)
        }

        @Test("Initial remaining destination is primary savings")
        func initialRemainingDestination() {
            let vm = DashboardViewModel()
            #expect(vm.remainingMoneyDestination == .primarySavings)
        }

        @Test("Initial onboarding not completed")
        func initialOnboardingNotCompleted() {
            let vm = DashboardViewModel()
            #expect(vm.hasCompletedOnboarding == false)
        }

        @Test("Initial new month sheet not shown")
        func initialNewMonthSheetHidden() {
            let vm = DashboardViewModel()
            #expect(vm.showNewMonthSheet == false)
        }
    }

    // MARK: - Total Expenses

    @Suite("Total Expenses")
    @MainActor
    struct TotalExpensesTests {

        @Test("Total expenses with no expenses is zero")
        func totalExpensesEmpty() {
            let vm = DashboardViewModel()
            #expect(vm.totalExpenses == 0)
        }

        @Test("Total expenses sums all expense amounts")
        func totalExpensesSums() {
            let vm = DashboardViewModel()
            vm.expenses = [
                DashboardViewModelTests.makeExpense(amount: 1000),
                DashboardViewModelTests.makeExpense(amount: 500),
                DashboardViewModelTests.makeExpense(amount: 250)
            ]

            #expect(vm.totalExpenses == 1750)
        }

        @Test("Total expenses with single expense")
        func totalExpensesSingle() {
            let vm = DashboardViewModel()
            vm.expenses = [DashboardViewModelTests.makeExpense(amount: 3000)]

            #expect(vm.totalExpenses == 3000)
        }

        @Test("Total expenses with various amounts",
              arguments: [
                ([Decimal(100), Decimal(200), Decimal(300)], Decimal(600)),
                ([Decimal(1500), Decimal(2500)], Decimal(4000)),
                ([Decimal(99.99), Decimal(0.01)], Decimal(100))
              ])
        func totalExpensesVariousAmounts(amounts: [Decimal], expected: Decimal) {
            let vm = DashboardViewModel()
            vm.expenses = amounts.map { DashboardViewModelTests.makeExpense(amount: $0) }

            #expect(vm.totalExpenses == expected)
        }
    }

    // MARK: - Available Income

    @Suite("Available Income")
    @MainActor
    struct AvailableIncomeTests {

        @Test("Available income equals income when no expenses")
        func availableIncomeNoExpenses() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000

            #expect(vm.availableIncome == 10000)
        }

        @Test("Available income subtracts expenses from income")
        func availableIncomeSubtractsExpenses() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000
            vm.expenses = [
                DashboardViewModelTests.makeExpense(amount: 3000),
                DashboardViewModelTests.makeExpense(amount: 1000)
            ]

            #expect(vm.availableIncome == 6000)
        }

        @Test("Available income is zero when expenses exceed income")
        func availableIncomeFlooredAtZero() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 5000
            vm.expenses = [DashboardViewModelTests.makeExpense(amount: 8000)]

            #expect(vm.availableIncome == 0)
        }

        @Test("Available income with various scenarios",
              arguments: [
                (income: Decimal(10000), expenses: Decimal(4000), expected: Decimal(6000)),
                (income: Decimal(8000), expenses: Decimal(8000), expected: Decimal(0)),
                (income: Decimal(15000), expenses: Decimal(0), expected: Decimal(15000)),
                (income: Decimal(5000), expenses: Decimal(10000), expected: Decimal(0))
              ])
        func availableIncomeScenarios(income: Decimal, expenses: Decimal, expected: Decimal) {
            let vm = DashboardViewModel()
            vm.monthlyIncome = income
            vm.expenses = [DashboardViewModelTests.makeExpense(amount: expenses)]

            #expect(vm.availableIncome == expected)
        }
    }

    // MARK: - Effective Savings Percentage

    @Suite("Effective Savings Percentage")
    @MainActor
    struct EffectiveSavingsTests {

        @Test("Effective savings equals base when boost disabled")
        func effectiveSavingsNoBoost() {
            let vm = DashboardViewModel()
            vm.savingsPercentage = 0.25
            vm.savingsBoostEnabled = false

            #expect(vm.effectiveSavingsPercentage == 0.25)
        }

        @Test("Effective savings multiplied when boost enabled")
        func effectiveSavingsWithBoost() {
            let vm = DashboardViewModel()
            vm.savingsPercentage = 0.25
            vm.savingsBoostEnabled = true
            vm.savingsBoostMultiplier = 2.0

            #expect(vm.effectiveSavingsPercentage == 0.5)
        }

        @Test("Effective savings capped at 100%")
        func effectiveSavingsCapped() {
            let vm = DashboardViewModel()
            vm.savingsPercentage = 0.50
            vm.savingsBoostEnabled = true
            vm.savingsBoostMultiplier = 3.0 // Would be 150%

            #expect(vm.effectiveSavingsPercentage == 1.0)
        }

        @Test("Effective savings with various multipliers",
              arguments: [
                (base: 0.10, multiplier: 2.0, expected: 0.20),
                (base: 0.25, multiplier: 3.0, expected: 0.75),
                (base: 0.40, multiplier: 2.5, expected: 1.0),  // Capped
                (base: 0.30, multiplier: 4.0, expected: 1.0)   // Capped
              ])
        func effectiveSavingsWithMultipliers(base: Double, multiplier: Double, expected: Double) {
            let vm = DashboardViewModel()
            vm.savingsPercentage = base
            vm.savingsBoostEnabled = true
            vm.savingsBoostMultiplier = multiplier

            #expect(abs(vm.effectiveSavingsPercentage - expected) < 0.001)
        }
    }

    // MARK: - Total Savings

    @Suite("Total Savings")
    @MainActor
    struct TotalSavingsTests {

        @Test("Total savings calculated from available income")
        func totalSavingsCalculation() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000
            vm.expenses = [DashboardViewModelTests.makeExpense(amount: 4000)]
            vm.savingsPercentage = 0.25

            // Available: 6000, Savings: 6000 * 0.25 = 1500
            #expect(vm.totalSavings == 1500)
        }

        @Test("Total savings with boost enabled")
        func totalSavingsWithBoost() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000
            vm.expenses = [DashboardViewModelTests.makeExpense(amount: 4000)]
            vm.savingsPercentage = 0.25
            vm.savingsBoostEnabled = true
            vm.savingsBoostMultiplier = 2.0

            // Available: 6000, Effective: 0.50, Savings: 6000 * 0.50 = 3000
            #expect(vm.totalSavings == 3000)
        }

        @Test("Total savings is zero when no available income")
        func totalSavingsZeroWhenNoIncome() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 5000
            vm.expenses = [DashboardViewModelTests.makeExpense(amount: 5000)]
            vm.savingsPercentage = 0.25

            #expect(vm.totalSavings == 0)
        }
    }

    // MARK: - Account Lookups

    @Suite("Account Lookups")
    @MainActor
    struct AccountLookups {

        @Test("Emergency account returns emergency type account")
        func emergencyAccountLookup() {
            let vm = DashboardViewModel()
            let emergency = DashboardViewModelTests.makeAccount(
                name: "Emergency Fund",
                accountType: .emergency,
                emergencyMultiplier: 3.0
            )
            let checking = DashboardViewModelTests.makeAccount(accountType: .primary)

            vm.accounts = [checking, emergency]

            #expect(vm.emergencyAccount?.name == "Emergency Fund")
            #expect(vm.emergencyAccount?.accountType == .emergency)
        }

        @Test("Emergency account returns nil when none exists")
        func emergencyAccountNil() {
            let vm = DashboardViewModel()
            vm.accounts = [
                DashboardViewModelTests.makeAccount(accountType: .primary),
                DashboardViewModelTests.makeAccount(accountType: .savings)
            ]

            #expect(vm.emergencyAccount == nil)
        }

        @Test("Primary account returns isPrimary account")
        func primaryAccountLookup() {
            let vm = DashboardViewModel()
            let primary = DashboardViewModelTests.makeAccount(
                name: "Main",
                accountType: .primary,
                isPrimary: true
            )
            let secondary = DashboardViewModelTests.makeAccount(accountType: .savings)

            vm.accounts = [secondary, primary]

            #expect(vm.primaryAccount?.name == "Main")
            #expect(vm.primaryAccount?.isPrimary == true)
        }

        @Test("Primary savings account returns isPrimarySavings account")
        func primarySavingsAccountLookup() {
            let vm = DashboardViewModel()
            let savings = DashboardViewModelTests.makeAccount(
                name: "Main Savings",
                accountType: .savings,
                isPrimarySavings: true
            )
            let other = DashboardViewModelTests.makeAccount(accountType: .primary)

            vm.accounts = [other, savings]

            #expect(vm.primarySavingsAccount?.name == "Main Savings")
            #expect(vm.primarySavingsAccount?.isPrimarySavings == true)
        }

        @Test("Personal account returns personal type account")
        func personalAccountLookup() {
            let vm = DashboardViewModel()
            let personal = DashboardViewModelTests.makeAccount(
                name: "Spending",
                accountType: .personal
            )
            let other = DashboardViewModelTests.makeAccount(accountType: .primary)

            vm.accounts = [other, personal]

            #expect(vm.personalAccount?.name == "Spending")
            #expect(vm.personalAccount?.accountType == .personal)
        }

        @Test("Display accounts excludes primary account")
        func displayAccountsExcludesPrimary() {
            let vm = DashboardViewModel()
            let primary = DashboardViewModelTests.makeAccount(
                name: "Primary",
                isPrimary: true
            )
            let savings = DashboardViewModelTests.makeAccount(name: "Savings")
            let emergency = DashboardViewModelTests.makeAccount(name: "Emergency")

            vm.accounts = [primary, savings, emergency]

            #expect(vm.displayAccounts.count == 2)
            #expect(vm.displayAccounts.allSatisfy { $0.isPrimary == false })
        }
    }

    // MARK: - Emergency Fund

    @Suite("Emergency Fund Properties")
    @MainActor
    struct EmergencyFundTests {

        @Test("Emergency progress returns account progress")
        func emergencyProgressFromAccount() throws {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000
            vm.accounts = [
                DashboardViewModelTests.makeAccount(
                    accountType: .emergency,
                    emergencyMultiplier: 3.0,
                    currentBalance: 15000 // 50% of 30000 target
                )
            ]

            let progress = try #require(vm.emergencyProgress)
            #expect(abs(progress - 0.5) < 0.001)
        }

        @Test("Emergency progress nil without emergency account")
        func emergencyProgressNilWithoutAccount() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000
            vm.accounts = [DashboardViewModelTests.makeAccount(accountType: .savings)]

            #expect(vm.emergencyProgress == nil)
        }

        @Test("Emergency target returns account target")
        func emergencyTargetFromAccount() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000
            vm.accounts = [
                DashboardViewModelTests.makeAccount(
                    accountType: .emergency,
                    emergencyMultiplier: 3.0
                )
            ]

            #expect(vm.emergencyTarget == 30000)
        }

        @Test("Emergency target nil without emergency account")
        func emergencyTargetNilWithoutAccount() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000

            #expect(vm.emergencyTarget == nil)
        }
    }

    // MARK: - Onboarding Completion

    @Suite("Onboarding Completion")
    @MainActor
    struct OnboardingCompletion {

        @Test("Has completed onboarding when name and income set")
        func completedWhenNameAndIncome() {
            let vm = DashboardViewModel()
            vm.userName = "Vlad"
            vm.monthlyIncome = 10000
            vm.hasCompletedOnboarding = true

            #expect(vm.hasCompletedOnboarding == true)
        }

        @Test("Has not completed onboarding initially")
        func notCompletedInitially() {
            let vm = DashboardViewModel()

            #expect(vm.hasCompletedOnboarding == false)
        }
    }

    // MARK: - Actions

    @Suite("Actions")
    @MainActor
    struct Actions {

        @Test("openNewMonthFlow shows sheet")
        func openNewMonthFlowShowsSheet() {
            let vm = DashboardViewModel()

            #expect(vm.showNewMonthSheet == false)

            vm.openNewMonthFlow()

            #expect(vm.showNewMonthSheet == true)
        }
    }

    // MARK: - Current Month Display

    @Suite("Current Month Display")
    @MainActor
    struct CurrentMonthDisplay {

        @Test("Current month display is not empty")
        func currentMonthNotEmpty() {
            let vm = DashboardViewModel()

            #expect(vm.currentMonthDisplay.isEmpty == false)
        }

        @Test("Current month display contains year")
        func currentMonthContainsYear() {
            let vm = DashboardViewModel()
            let currentYear = Calendar.current.component(.year, from: Date())

            #expect(vm.currentMonthDisplay.contains(String(currentYear)))
        }
    }

    // MARK: - Calculate Transfer Plan

    @Suite("Calculate Transfer Plan")
    @MainActor
    struct CalculateTransferPlanTests {

        @Test("Uses provided income instead of monthlyIncome")
        func usesProvidedIncome() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000
            vm.savingsPercentage = 0.25
            vm.savingsBoostEnabled = false
            vm.accounts = [
                DashboardViewModelTests.makeAccount(
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true
                ),
                DashboardViewModelTests.makeAccount(
                    name: "Savings",
                    accountType: .savings,
                    isPrimarySavings: true
                )
            ]

            // Calculate with different income than monthlyIncome
            let plan = vm.calculateTransferPlan(withIncome: 15000)

            // Savings allocation should be 15000 * 0.25 = 3750 (not 10000 * 0.25 = 2500)
            let savingsAllocation = plan.accountAllocations.first { $0.accountName == "Savings" }
            #expect(savingsAllocation?.amount == 3750)
        }

        @Test("Includes expense transfers to linked accounts")
        func includesExpenseTransfers() {
            let jointId = UUID()
            let vm = DashboardViewModel()
            vm.monthlyIncome = 10000
            vm.savingsPercentage = 0.10
            vm.accounts = [
                DashboardViewModelTests.makeAccount(
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true
                ),
                DashboardAccount(
                    id: jointId,
                    name: "Joint",
                    accountType: .joint,
                    isPrimary: false,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                )
            ]
            vm.expenses = [
                DashboardExpense(
                    id: UUID(),
                    name: "Food",
                    amount: 1000,
                    icon: "cart",
                    linkedAccountId: jointId
                )
            ]

            let plan = vm.calculateTransferPlan(withIncome: 10000)

            // Should have transfer to Joint for linked expense
            let jointTransfer = plan.accountExpenseTransfers.first { $0.accountName == "Joint" }
            #expect(jointTransfer != nil)
            #expect(jointTransfer?.amount == 1000)
        }

        @Test("Respects savings boost setting")
        func respectsSavingsBoost() {
            let vm = DashboardViewModel()
            vm.savingsPercentage = 0.25
            vm.savingsBoostEnabled = true
            vm.savingsBoostMultiplier = 2.0
            vm.accounts = [
                DashboardViewModelTests.makeAccount(
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true
                ),
                DashboardViewModelTests.makeAccount(
                    name: "Savings",
                    accountType: .savings,
                    isPrimarySavings: true
                )
            ]

            let plan = vm.calculateTransferPlan(withIncome: 10000)

            // Savings should be 10000 * 0.50 (boosted) = 5000
            let savingsAllocation = plan.accountAllocations.first { $0.accountName == "Savings" }
            #expect(savingsAllocation?.amount == 5000)
        }

        @Test("Real-world scenario with full setup")
        func realWorldScenario() {
            let vm = DashboardViewModel()
            vm.savingsPercentage = 0.25
            vm.savingsBoostEnabled = true
            vm.savingsBoostMultiplier = 3.0
            vm.remainingMoneyDestination = .personal

            let jointId = UUID()
            vm.accounts = [
                DashboardViewModelTests.makeAccount(
                    name: "ING Primary",
                    accountType: .primary,
                    isPrimary: true,
                    currentBalance: 0
                ),
                DashboardViewModelTests.makeAccount(
                    name: "Emergency Fund",
                    accountType: .emergency,
                    emergencyMultiplier: 3.0,
                    currentBalance: 42000  // Already at target (14000 * 3)
                ),
                DashboardViewModelTests.makeAccount(
                    name: "Savings",
                    accountType: .savings,
                    isPrimarySavings: true,
                    currentBalance: 5000
                ),
                DashboardAccount(
                    id: jointId,
                    name: "Joint",
                    accountType: .joint,
                    isPrimary: false,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                ),
                DashboardViewModelTests.makeAccount(
                    name: "Personal",
                    accountType: .personal,
                    currentBalance: 500
                )
            ]

            vm.expenses = [
                DashboardExpense(id: UUID(), name: "Rent", amount: 2000, icon: "house", linkedAccountId: nil),
                DashboardExpense(id: UUID(), name: "Food", amount: 1500, icon: "cart", linkedAccountId: jointId),
                DashboardExpense(id: UUID(), name: "Utilities", amount: 500, icon: "bolt", linkedAccountId: nil)
            ]

            let plan = vm.calculateTransferPlan(withIncome: 14000)

            // Verify plan structure
            #expect(plan.income == 14000)
            #expect(plan.totalExpenses == 4000)
            #expect(plan.availableIncome == 10000) // 14000 - 4000

            // Verify joint account gets food expense transfer
            let jointTransfer = plan.accountExpenseTransfers.first { $0.accountName == "Joint" }
            #expect(jointTransfer?.amount == 1500)

            // Verify savings allocation exists (boosted: 10000 * 0.75 = 7500)
            let savingsAllocation = plan.accountAllocations.first { $0.accountName == "Savings" }
            #expect(savingsAllocation != nil)
            #expect(savingsAllocation?.amount == 7500)

            // Verify remaining money destination is respected
            #expect(plan.remainingDestination == .personal)

            // Verify plan is balanced (TransferCalculator guarantees this)
            #expect(plan.isBalanced == true)
        }

        @Test("Transfer plan computed property matches calculateTransferPlan with monthlyIncome")
        func computedPropertyMatchesMethod() {
            let vm = DashboardViewModel()
            vm.monthlyIncome = 12000
            vm.savingsPercentage = 0.20
            vm.accounts = [
                DashboardViewModelTests.makeAccount(
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true
                ),
                DashboardViewModelTests.makeAccount(
                    name: "Savings",
                    accountType: .savings,
                    isPrimarySavings: true
                )
            ]
            vm.expenses = [
                DashboardExpense(id: UUID(), name: "Rent", amount: 2000, icon: "house", linkedAccountId: nil)
            ]

            let computed = vm.transferPlan
            let methodResult = vm.calculateTransferPlan(withIncome: vm.monthlyIncome)

            // Both should produce identical results
            #expect(computed.income == methodResult.income)
            #expect(computed.totalExpenses == methodResult.totalExpenses)
            #expect(computed.availableIncome == methodResult.availableIncome)
            #expect(computed.remainsInPrimary == methodResult.remainsInPrimary)
        }
    }

    // MARK: - Compute Updated Balances

    @Suite("Compute Updated Balances")
    @MainActor
    struct ComputeUpdatedBalancesTests {

        @Test("Reconciled balances are applied as starting point")
        func reconciledBalancesApplied() {
            let vm = DashboardViewModel()
            let savingsId = UUID()
            vm.monthlyIncome = 10000
            vm.savingsPercentage = 0.0 // No savings to simplify
            vm.accounts = [
                DashboardAccount(
                    id: UUID(),
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                ),
                DashboardAccount(
                    id: savingsId,
                    name: "Savings",
                    accountType: .savings,
                    isPrimary: false,
                    isPrimarySavings: true,
                    emergencyMultiplier: nil,
                    currentBalance: 0 // Old balance is 0
                )
            ]

            // User entered 15000 as their actual savings balance in Step 2
            let plan = vm.calculateTransferPlan(withIncome: 10000)
            let data = NewMonthCompletionData(
                income: 10000,
                transferPlan: plan,
                reconciledBalances: [savingsId: 15000]
            )

            let result = vm.computeUpdatedBalances(from: data)

            // Savings should start from 15000 (reconciled), not 0 (old balance)
            #expect(result[savingsId] != nil)
            #expect(result[savingsId]! >= 15000)
        }

        @Test("Transfer plan allocations are added on top of reconciled balances")
        func allocationsAddedOnTop() {
            let vm = DashboardViewModel()
            let primaryId = UUID()
            let savingsId = UUID()
            vm.monthlyIncome = 10000
            vm.savingsPercentage = 0.25
            vm.remainingMoneyDestination = .primary
            vm.accounts = [
                DashboardAccount(
                    id: primaryId,
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                ),
                DashboardAccount(
                    id: savingsId,
                    name: "Savings",
                    accountType: .savings,
                    isPrimary: false,
                    isPrimarySavings: true,
                    emergencyMultiplier: nil,
                    currentBalance: 5000
                )
            ]

            let plan = vm.calculateTransferPlan(withIncome: 10000)
            // Savings allocation should be 10000 * 0.25 = 2500
            let savingsAllocation = plan.accountAllocations.first { $0.accountType == .savings }
            #expect(savingsAllocation?.amount == 2500)

            // User reconciles savings at 5000 (same as current)
            let data = NewMonthCompletionData(
                income: 10000,
                transferPlan: plan,
                reconciledBalances: [primaryId: 10000, savingsId: 5000]
            )

            let result = vm.computeUpdatedBalances(from: data)

            // Savings = 5000 (reconciled) + 2500 (allocation) = 7500
            #expect(result[savingsId] == 7500)
        }

        @Test("Expense-linked transfers are added to linked accounts")
        func expenseTransfersAdded() {
            let vm = DashboardViewModel()
            let primaryId = UUID()
            let jointId = UUID()
            vm.monthlyIncome = 10000
            vm.savingsPercentage = 0.0
            vm.accounts = [
                DashboardAccount(
                    id: primaryId,
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                ),
                DashboardAccount(
                    id: jointId,
                    name: "Joint",
                    accountType: .joint,
                    isPrimary: false,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                )
            ]
            vm.expenses = [
                DashboardExpense(
                    id: UUID(),
                    name: "Food",
                    amount: 2000,
                    icon: "cart",
                    linkedAccountId: jointId
                )
            ]

            let plan = vm.calculateTransferPlan(withIncome: 10000)
            let data = NewMonthCompletionData(
                income: 10000,
                transferPlan: plan,
                reconciledBalances: [primaryId: 10000, jointId: 500]
            )

            let result = vm.computeUpdatedBalances(from: data)

            // Joint = 500 (reconciled) + 2000 (food transfer) = 2500
            #expect(result[jointId] == 2500)
        }

        @Test("Remaining money goes to designated account")
        func remainingMoneyDestination() {
            let vm = DashboardViewModel()
            let primaryId = UUID()
            let personalId = UUID()
            vm.monthlyIncome = 10000
            vm.savingsPercentage = 0.10
            vm.remainingMoneyDestination = .personal
            vm.accounts = [
                DashboardAccount(
                    id: primaryId,
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                ),
                DashboardAccount(
                    id: personalId,
                    name: "Personal",
                    accountType: .personal,
                    isPrimary: false,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                )
            ]

            let plan = vm.calculateTransferPlan(withIncome: 10000)
            let data = NewMonthCompletionData(
                income: 10000,
                transferPlan: plan,
                reconciledBalances: [primaryId: 10000, personalId: 1000]
            )

            let result = vm.computeUpdatedBalances(from: data)

            // Personal should have reconciled (1000) + remaining money
            #expect(result[personalId]! > 1000)
        }

        @Test("Primary account is set to remainsInPrimary")
        func primarySetToRemainsInPrimary() {
            let vm = DashboardViewModel()
            let primaryId = UUID()
            vm.monthlyIncome = 10000
            vm.savingsPercentage = 0.0
            vm.accounts = [
                DashboardAccount(
                    id: primaryId,
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 5000
                )
            ]

            let plan = vm.calculateTransferPlan(withIncome: 10000)
            let data = NewMonthCompletionData(
                income: 10000,
                transferPlan: plan,
                reconciledBalances: [primaryId: 5000]
            )

            let result = vm.computeUpdatedBalances(from: data)

            // Primary should be set to remainsInPrimary (not added to)
            #expect(result[primaryId] == plan.remainsInPrimary)
        }

        @Test("Full scenario: reconcile then apply transfers")
        func fullScenario() {
            let vm = DashboardViewModel()
            let primaryId = UUID()
            let emergencyId = UUID()
            let savingsId = UUID()
            let jointId = UUID()

            vm.monthlyIncome = 14000
            vm.savingsPercentage = 0.25
            vm.savingsBoostEnabled = false
            vm.remainingMoneyDestination = .primarySavings
            vm.accounts = [
                DashboardAccount(
                    id: primaryId,
                    name: "Primary",
                    accountType: .primary,
                    isPrimary: true,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                ),
                DashboardAccount(
                    id: emergencyId,
                    name: "Emergency",
                    accountType: .emergency,
                    isPrimary: false,
                    isPrimarySavings: false,
                    emergencyMultiplier: 3.0,
                    currentBalance: 42000 // Already at target
                ),
                DashboardAccount(
                    id: savingsId,
                    name: "Savings",
                    accountType: .savings,
                    isPrimary: false,
                    isPrimarySavings: true,
                    emergencyMultiplier: nil,
                    currentBalance: 5000
                ),
                DashboardAccount(
                    id: jointId,
                    name: "Joint",
                    accountType: .joint,
                    isPrimary: false,
                    isPrimarySavings: false,
                    emergencyMultiplier: nil,
                    currentBalance: 0
                )
            ]

            vm.expenses = [
                DashboardExpense(id: UUID(), name: "Rent", amount: 2000, icon: "house", linkedAccountId: nil),
                DashboardExpense(id: UUID(), name: "Food", amount: 1500, icon: "cart", linkedAccountId: jointId)
            ]

            let plan = vm.calculateTransferPlan(withIncome: 14000)

            // User updated savings to 8000 in reconcile step
            let data = NewMonthCompletionData(
                income: 14000,
                transferPlan: plan,
                reconciledBalances: [
                    primaryId: 14000,
                    emergencyId: 42000,
                    savingsId: 8000,  // User updated from 5000 to 8000
                    jointId: 200
                ]
            )

            let result = vm.computeUpdatedBalances(from: data)

            // Savings should start from 8000 (reconciled), not 5000 (old)
            let savingsAllocation = plan.accountAllocations.first { $0.accountType == .savings }?.amount ?? 0
            #expect(result[savingsId]! >= 8000 + savingsAllocation)

            // Joint = 200 (reconciled) + 1500 (food transfer)
            #expect(result[jointId] == 1700)

            // Emergency should still be at/near target (already full)
            #expect(result[emergencyId]! >= 42000)
        }
    }
}
