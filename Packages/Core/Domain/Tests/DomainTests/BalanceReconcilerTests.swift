import Foundation
import Testing
@testable import Domain

struct BalanceReconcilerTests {

    @Test func `Full New Month: reconciled balances plus allocations, Joint keeps its own balance`() {
        let primary = AccountEntry.primary()
        let joint = AccountEntry(name: "Joint", accountType: .joint, currentBalance: 900)
        let emergency = AccountEntry.emergency(multiplier: 3, currentBalance: 1000)
        let savings = AccountEntry.savings()
        let accounts = [primary, joint, emergency, savings]

        let plan = Fixture.plan(
            income: 8000,
            expenses: [Fixture.expense("Rent", 2000, linkedTo: joint), Fixture.expense("Food", 1000)],
            accounts: accounts,
            destination: .primarySavings
        )
        // Only emergency is reconciled; Joint must keep its stored balance, not restart at 0.
        let result = BalanceReconciler.reconcile(
            plan: plan,
            accounts: accounts,
            reconciledBalances: [emergency.id: 1200]
        )

        // 5000 available → 1250 saved (all to emergency, target 24 000), 3750 remaining
        #expect(result.balances[joint.id] == 2900, "900 kept + 2000 rent transfer")
        #expect(result.balances[emergency.id] == 2450, "1200 reconciled + 1250 allocation")
        #expect(result.balances[savings.id] == 3750, "Remaining money")
        #expect(result.balances[primary.id] == 1000, "Primary holds the expense float")
        #expect(result.unallocatedRemainingMoney == 0)
        #expect(result.unknownAccountIds.isEmpty)
    }

    @Test func `Keep in Primary: 8500 salary, 3000 of bills paid from primary`() {
        let primary = AccountEntry.primary()
        let emergency = AccountEntry.emergency(multiplier: 3, currentBalance: 2000)
        let accounts = [primary, emergency]
        let plan = Fixture.plan(
            income: 8500,
            expenses: [Fixture.expense("Rent", 2000), Fixture.expense("Utilities", 1000)],
            accounts: accounts,
            destination: .primary
        )

        let balances = BalanceReconciler.updatedBalances(plan: plan, accounts: accounts, reconciledBalances: [:])

        // 5500 available → 1375 to emergency, 4125 remaining stays with the 3000 of bills
        #expect(plan.remainingMoney == 4125)
        #expect(balances[primary.id] == 3000 + plan.remainingMoney)
        #expect(balances[emergency.id] == 3375)
        let deltas = accounts.reduce(Decimal(0)) { $0 + (balances[$1.id] ?? 0) - $1.currentBalance }
        #expect(deltas == 8500, "Every unit of income ends up in exactly one account")
    }

    @Test(arguments: [RemainingMoneyDestination.primarySavings, .personal, .primary])
    func `Remaining money lands in the account its destination names`(destination: RemainingMoneyDestination) {
        let primary = AccountEntry.primary()
        let savings = AccountEntry.savings()
        let personal = AccountEntry(name: "Personal", accountType: .personal, currentBalance: 100)
        let accounts = [primary, savings, personal]
        let plan = Fixture.plan(income: 4000, accounts: accounts, destination: destination)

        let balances = BalanceReconciler.updatedBalances(plan: plan, accounts: accounts, reconciledBalances: [:])

        // 1000 always goes to savings; the 3000 remaining follows the destination
        let expected: [UUID: Decimal] = switch destination {
        case .primarySavings: [primary.id: 0, savings.id: 4000, personal.id: 100]
        case .personal: [primary.id: 0, savings.id: 1000, personal.id: 3100]
        case .primary: [primary.id: 3000, savings.id: 1000, personal.id: 100]
        }
        #expect(balances == expected)
    }

    @Test func `A plan account missing from the reconcile list is reported, not silently dropped`() {
        let primary = AccountEntry.primary()
        let joint = AccountEntry.joint()
        let plan = Fixture.plan(
            income: 3000,
            expenses: [Fixture.expense("Rent", 1200, linkedTo: joint)],
            accounts: [primary, joint]
        )

        // The caller forgot Joint — e.g. it was deleted between planning and completing.
        let result = BalanceReconciler.reconcile(plan: plan, accounts: [primary], reconciledBalances: [:])

        #expect(result.unknownAccountIds == [joint.id])
        #expect(result.balances[joint.id] == 1200)
    }

    @Test func `Keep in Primary leaves the remaining money in the primary balance`() {
        let primary = AccountEntry.primary()
        let accounts = [primary, AccountEntry.savings()]
        let plan = Fixture.plan(
            income: 5000,
            expenses: [Fixture.expense("Rent", 1000)],
            accounts: accounts,
            destination: .primary
        )

        let balances = BalanceReconciler.updatedBalances(plan: plan, accounts: accounts, reconciledBalances: [:])

        // 1000 float + (4000 − 1000 saved) remaining
        #expect(balances[primary.id] == 4000)
    }

    @Test func `Primary Savings destination uses the same fallback savings account as the calculator`() {
        let fallback = AccountEntry.savings(isPrimarySavings: false)
        let accounts = [AccountEntry.primary(), fallback]
        let plan = Fixture.plan(income: 4000, accounts: accounts, destination: .primarySavings)

        let result = BalanceReconciler.reconcile(plan: plan, accounts: accounts, reconciledBalances: [:])

        #expect(result.balances[fallback.id] == 4000, "1000 allocation + 3000 remaining")
        #expect(result.unallocatedRemainingMoney == 0)
    }

    @Test(arguments: [RemainingMoneyDestination.primarySavings, .personal])
    func `Remaining money with no destination account stays in primary and is reported`(
        destination: RemainingMoneyDestination
    ) {
        let primary = AccountEntry.primary()
        let plan = Fixture.plan(
            income: 1000,
            expenses: [Fixture.expense("Phone", 100)],
            accounts: [primary],
            destination: destination
        )

        let result = BalanceReconciler.reconcile(plan: plan, accounts: [primary], reconciledBalances: [:])

        #expect(result.unallocatedRemainingMoney == 900)
        #expect(result.balances[primary.id] == 1000, "Nothing was transferred out, so nothing vanished")
    }

    @Test func `Balances never lose or invent money relative to what was there plus income`() {
        let primary = AccountEntry(name: "Main", accountType: .primary, isPrimary: true, currentBalance: 0)
        let joint = AccountEntry(name: "Joint", accountType: .joint, currentBalance: 300)
        let emergency = AccountEntry.emergency(multiplier: 3, currentBalance: 500)
        let personal = AccountEntry(name: "Personal", accountType: .personal, currentBalance: 50)
        let accounts = [primary, joint, emergency, personal]
        let plan = Fixture.plan(
            income: Decimal(string: "7321.45")!,
            expenses: [
                Fixture.expense("Rent", Decimal(string: "1999.99")!, linkedTo: joint),
                Fixture.expense("Insurance", 1000, .annual)
            ],
            allocation: Fixture.prioritized(0.07),
            accounts: accounts,
            destination: .personal
        )

        let balances = BalanceReconciler.updatedBalances(plan: plan, accounts: accounts, reconciledBalances: [:])

        let before = accounts.reduce(Decimal(0)) { $0 + $1.currentBalance }
        let after = balances.values.reduce(Decimal(0), +)
        #expect(after == before + plan.income)
    }

    @Test func `Reconciled id for an account we were not given is reported, not dropped`() {
        let primary = AccountEntry.primary()
        let strayId = UUID()
        let plan = Fixture.plan(income: 1000, accounts: [primary])

        let result = BalanceReconciler.reconcile(
            plan: plan,
            accounts: [primary],
            reconciledBalances: [strayId: 250]
        )

        #expect(result.unknownAccountIds == [strayId])
        #expect(result.balances[strayId] == 250)
    }
}
