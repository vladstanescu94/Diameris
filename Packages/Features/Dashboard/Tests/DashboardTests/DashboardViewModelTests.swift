import Foundation
import Testing
@testable import Dashboard
import Utilities
import Domain

/// Plan math and balance application belong to Domain (`TransferCalculator`, `BalanceReconciler`);
/// these tests only check that the view model feeds them the right inputs.
@MainActor
struct DashboardViewModelTests {

    // MARK: - Emergency Fund

    @Test func `Emergency target and progress come from the emergency account and monthly income`() throws {
        let vm = DashboardViewModel()
        vm.monthlyIncome = 10000
        vm.accounts = [
            .fixture(name: "Primary", type: .primary, isPrimary: true, balance: 2000),
            .fixture(name: "Emergency", type: .emergency, emergencyMultiplier: 3.0, balance: 15000)
        ]

        #expect(vm.emergencyTarget == 30000)
        let progress = try #require(vm.emergencyProgress)
        #expect(abs(progress - 0.5) < 0.0001)
    }

    @Test func `No emergency account means no target or progress`() {
        let vm = DashboardViewModel()
        vm.monthlyIncome = 10000
        vm.accounts = [.fixture(name: "Primary", type: .primary, isPrimary: true)]

        #expect(vm.emergencyAccount == nil)
        #expect(vm.emergencyTarget == nil)
        #expect(vm.emergencyProgress == nil)
    }

    // MARK: - Transfer Plan Inputs

    @Test func `Custom income overrides monthly income`() {
        let vm = DashboardViewModel()
        vm.monthlyIncome = 10000
        vm.savingsPercentage = 0.25
        vm.accounts = [
            .fixture(name: "Primary", type: .primary, isPrimary: true),
            .fixture(name: "Savings", type: .savings, isPrimarySavings: true)
        ]

        let plan = vm.calculateTransferPlan(withIncome: 15000)

        #expect(plan.income == 15000)
        #expect(plan.savingsAllocation?.amount == 3750, "25% of 15000, not of the 10000 on record")
    }

    @Test func `Boost, linked expenses and remaining destination all reach the calculator`() {
        let jointId = UUID()
        let vm = DashboardViewModel()
        vm.monthlyIncome = 14000
        vm.savingsPercentage = 0.25
        vm.savingsBoostEnabled = true
        vm.savingsBoostMultiplier = 3.0
        vm.remainingMoneyDestination = .personal
        vm.accounts = [
            .fixture(name: "Primary", type: .primary, isPrimary: true),
            .fixture(name: "Emergency", type: .emergency, emergencyMultiplier: 3.0, balance: 42000),
            .fixture(name: "Savings", type: .savings, isPrimarySavings: true, balance: 5000),
            .fixture(id: jointId, name: "Joint", type: .joint),
            .fixture(name: "Personal", type: .personal, balance: 500)
        ]
        vm.expenses = [
            .fixture(name: "Rent", amount: 2000),
            .fixture(name: "Food", amount: 1500, linkedAccountId: jointId),
            .fixture(name: "Utilities", amount: 500)
        ]

        let plan = vm.transferPlan

        #expect(plan.totalExpenses == 4000)
        #expect(plan.availableIncome == 10000)
        #expect(plan.savingsAllocation?.amount == 7500, "Boosted 25% × 3 = 75% of 10000; emergency is full")
        #expect(plan.accountExpenseTransfers.first { $0.accountId == jointId }?.amount == 1500)
        #expect(plan.remainsInPrimary == 2500)
        #expect(plan.remainingDestination == .personal)
        #expect(plan.isBalanced)
    }

    @Test func `Split mode settings reach the calculator`() {
        let vm = DashboardViewModel()
        vm.monthlyIncome = 10000
        vm.allocationMode = .split
        vm.splitEmergencyAmount = 500
        vm.splitSavingsAmount = 700
        vm.accounts = [
            .fixture(name: "Primary", type: .primary, isPrimary: true),
            .fixture(name: "Emergency", type: .emergency, emergencyMultiplier: 3.0),
            .fixture(name: "Savings", type: .savings, isPrimarySavings: true)
        ]

        let plan = vm.transferPlan

        #expect(plan.emergencyAllocation?.amount == 500)
        #expect(plan.savingsAllocation?.amount == 700)
        #expect(plan.isBalanced)
    }

    @Test func `Reconciled balances replace stored balances in the plan`() {
        let emergencyId = UUID()
        let vm = DashboardViewModel()
        vm.monthlyIncome = 10000
        vm.savingsPercentage = 0.20
        vm.accounts = [
            .fixture(name: "Primary", type: .primary, isPrimary: true),
            .fixture(id: emergencyId, name: "Emergency", type: .emergency, emergencyMultiplier: 3.0, balance: 30000),
            .fixture(name: "Savings", type: .savings, isPrimarySavings: true)
        ]

        // Stored balance: emergency is exactly at its 30000 target, so savings get everything.
        let baseline = vm.calculateTransferPlan(withIncome: 10000)
        #expect((baseline.emergencyAllocation?.amount ?? 0) == 0)
        #expect(baseline.savingsAllocation?.amount == 2000)

        // The user spent 500 from the emergency fund; the plan tops it back up first.
        let reconciled = vm.calculateTransferPlan(withIncome: 10000, reconciledBalances: [emergencyId: 29500])
        #expect(reconciled.emergencyAllocation?.amount == 500)
        #expect(reconciled.savingsAllocation?.amount == 1500)
    }

    // MARK: - Summary

    @Test(arguments: [
        (RemainingMoneyDestination.personal, "Personal Spending"),
        (.primarySavings, "Extra Savings"),
        (.primary, "Stays in Primary")
    ])
    func `The summary's last row is named after the remaining-money destination`(
        destination: RemainingMoneyDestination, label: String
    ) {
        #expect(SummaryCard.remainingLabel(for: destination) == label)
    }

    // MARK: - Data Loading

    @Test(arguments: [
        ("Vlad", Decimal(10000), true),
        ("", Decimal(10000), false),
        ("Vlad", Decimal(0), false)
    ])
    func `Loading data marks onboarding complete only with a name and income`(
        name: String, income: Decimal, expected: Bool
    ) {
        let vm = DashboardViewModel()
        let provider = StubProvider(userName: name, monthlyIncome: income)

        vm.loadData(from: provider)

        #expect(vm.hasCompletedOnboarding == expected)
        #expect(vm.userName == name)
        #expect(vm.monthlyIncome == income)
        #expect(vm.accounts == provider.accounts)
        #expect(vm.allocationMode == provider.allocationMode)
        #expect(vm.splitSavingsAmount == provider.splitSavingsAmount)
    }
}

// MARK: - Fixtures

extension DashboardAccount {
    static func fixture(
        id: UUID = UUID(),
        name: String,
        type: AccountType,
        isPrimary: Bool = false,
        isPrimarySavings: Bool = false,
        emergencyMultiplier: Double? = nil,
        balance: Decimal = 0
    ) -> DashboardAccount {
        DashboardAccount(
            id: id,
            name: name,
            accountType: type,
            isPrimary: isPrimary,
            isPrimarySavings: isPrimarySavings,
            emergencyMultiplier: emergencyMultiplier,
            currentBalance: balance
        )
    }
}

extension DashboardExpense {
    static func fixture(name: String, amount: Decimal, linkedAccountId: UUID? = nil) -> DashboardExpense {
        DashboardExpense(id: UUID(), name: name, amount: amount, icon: "circle", linkedAccountId: linkedAccountId)
    }
}

private struct StubProvider: DashboardDataProvider {
    var userName: String
    var monthlyIncome: Decimal
    var currency: Currency = .eur
    var accounts: [DashboardAccount] = [.fixture(name: "Primary", type: .primary, isPrimary: true, balance: 100)]
    var expenses: [DashboardExpense] = [.fixture(name: "Rent", amount: 2000)]
    var savingsPercentage: Double = 0.3
    var savingsBoostEnabled: Bool = true
    var savingsBoostMultiplier: Double = 2
    var remainingMoneyDestination: RemainingMoneyDestination = .personal
    var allocationMode: AllocationMode = .split
    var savingsInputMode: SavingsInputMode = .fixedAmount
    var savingsFixedAmount: Decimal = 1000
    var splitEmergencyInputMode: SavingsInputMode = .percentage
    var splitEmergencyAmount: Decimal = 300
    var splitEmergencyPercentage: Double = 0.05
    var splitSavingsInputMode: SavingsInputMode = .percentage
    var splitSavingsAmount: Decimal = 400
    var splitSavingsPercentage: Double = 0.07
}
