import Foundation
import Testing
@testable import Dashboard
import Domain

@MainActor
struct NewMonthFlowModelTests {

    private let primaryId = UUID()
    private let emergencyId = UUID()
    private let savingsId = UUID()
    private let jointId = UUID()
    private let personalId = UUID()

    /// 10000 income, 25% savings (prioritized), remaining → personal.
    /// Rent 2000 stays in primary; Food 1500 is paid from the joint account.
    private func makeDashboard() -> DashboardViewModel {
        let vm = DashboardViewModel()
        vm.monthlyIncome = 10000
        vm.savingsPercentage = 0.25
        vm.remainingMoneyDestination = .personal
        vm.accounts = [
            .fixture(id: primaryId, name: "Primary", type: .primary, isPrimary: true, balance: 1000),
            .fixture(id: emergencyId, name: "Emergency", type: .emergency, emergencyMultiplier: 3.0, balance: 30000),
            .fixture(id: savingsId, name: "Savings", type: .savings, isPrimarySavings: true, balance: 5000),
            .fixture(id: jointId, name: "Joint", type: .joint, balance: 200),
            .fixture(id: personalId, name: "Personal", type: .personal, balance: 800)
        ]
        vm.expenses = [
            .fixture(name: "Rent", amount: 2000),
            .fixture(name: "Food", amount: 1500, linkedAccountId: jointId)
        ]
        return vm
    }

    @Test func `Starts on salary entry seeded with last month's income and balances`() {
        let dashboard = makeDashboard()
        let flow = NewMonthFlowModel(dashboard: dashboard)

        #expect(flow.step == .salaryEntry)
        #expect(flow.isFirstStep)
        #expect(flow.income == 10000)
        #expect(flow.lastMonthIncome == 10000)
        #expect(flow.balances == Dictionary(uniqueKeysWithValues: dashboard.accounts.map { ($0.id, $0.currentBalance) }))
    }

    @Test func `Every account except primary is reconciled`() {
        let flow = NewMonthFlowModel(dashboard: makeDashboard())

        #expect(flow.reconcilableAccounts.map(\.id) == [emergencyId, savingsId, jointId, personalId])
    }

    @Test(arguments: [
        (Decimal(0), false),
        (Decimal(-100), false),
        (Decimal(string: "0.01")!, true),
        (Decimal(12000), true)
    ])
    func `Salary must be positive to continue`(salary: Decimal, canContinue: Bool) {
        let flow = NewMonthFlowModel(dashboard: makeDashboard())
        flow.income = salary

        flow.advance()

        #expect(flow.canContinue == canContinue)
        #expect(flow.step == (canContinue ? .reconcileAccounts : .salaryEntry))
    }

    @Test func `Going back keeps entered salary and balances`() {
        let flow = NewMonthFlowModel(dashboard: makeDashboard())
        flow.income = 12000
        flow.advance()
        flow[balanceFor: emergencyId] = 28000
        flow.advance()
        #expect(flow.step == .transferPlan)

        flow.goBack()
        flow.goBack()

        #expect(flow.step == .salaryEntry)
        #expect(flow.income == 12000)
        #expect(flow[balanceFor: emergencyId] == 28000)
    }

    @Test func `Navigation stops at the first and last steps`() {
        let flow = NewMonthFlowModel(dashboard: makeDashboard())
        flow.goBack()
        #expect(flow.step == .salaryEntry)

        flow.advance()
        flow.advance()
        flow.advance()
        #expect(flow.step == .transferPlan)
    }

    @Test func `Changed salary and reconciled balances flow through to the updated balances`() throws {
        let dashboard = makeDashboard()
        let flow = NewMonthFlowModel(dashboard: dashboard)

        // Step 1: a raise. Step 2: 2000 spent from the emergency fund, 300 from personal,
        // and last month's food bought from Joint left 50 there.
        flow.income = 12000
        flow.advance()
        flow[balanceFor: emergencyId] = 28000
        flow[balanceFor: personalId] = 500
        flow[balanceFor: jointId] = 50
        flow.advance()

        let data = flow.completionData
        #expect(data.income == 12000)
        #expect(data.reconciledBalances[emergencyId] == 28000)

        // Available = 12000 - 3500 = 8500; savings 25% = 2125, all needed by the emergency fund
        // (target 3 × 12000 = 36000, balance 28000). Remaining 6375 goes to personal.
        let plan = data.transferPlan
        #expect(plan.income == 12000)
        #expect(plan.availableIncome == 8500)
        #expect(plan.emergencyAllocation?.amount == 2125)
        #expect(plan.remainingMoney == 6375)
        #expect(plan.isBalanced)

        let balances = dashboard.computeUpdatedBalances(from: data)
        #expect(balances[emergencyId] == 30125, "28000 reconciled + 2125")
        #expect(balances[savingsId] == 5000, "Untouched: emergency took all savings")
        #expect(balances[jointId] == 1550, "50 reconciled + 1500 food transfer, not 200 + 1500")
        #expect(balances[personalId] == 6875, "500 reconciled + 6375 remaining")
        #expect(balances[primaryId] == 2000, "Set to what stays for rent, not accumulated")
    }
}
