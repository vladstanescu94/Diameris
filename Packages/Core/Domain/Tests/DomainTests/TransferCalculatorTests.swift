import Foundation
import Testing
@testable import Domain

struct TransferCalculatorTests {

    // MARK: - Prioritized mode

    @Test func `8500 RON salary with Joint rent and annual insurance fills emergency first, then savings`() throws {
        let primary = AccountEntry.primary(name: "Main")
        let joint = AccountEntry.joint(name: "Joint")
        let emergency = AccountEntry.emergency(name: "Emergency", multiplier: 3, currentBalance: 24_900)
        let savings = AccountEntry.savings(name: "Savings")

        let plan = Fixture.plan(
            income: 8500,
            expenses: [
                Fixture.expense("Rent", 2500, linkedTo: joint),
                Fixture.expense("Insurance", 1200, .annual),
                Fixture.expense("Food", 1400)
            ],
            allocation: Fixture.prioritized(0.25),
            accounts: [primary, joint, emergency, savings]
        )

        // 2500 + 1200/12 + 1400 = 4000 → 4500 available → 25% = 1125 to save
        #expect(plan.totalExpenses == 4000)
        #expect(plan.availableIncome == 4500)
        #expect(plan.totalSavings == 1125)

        // Emergency target 3 × 8500 = 25 500; it only needs 600 more, the rest overflows to savings
        let emergencyAllocation = try #require(plan.emergencyAllocation)
        #expect(emergencyAllocation.amount == 600)
        #expect(emergencyAllocation.targetAmount == 25_500)
        #expect(emergencyAllocation.isComplete)
        #expect(plan.savingsAllocation?.amount == 525)

        #expect(plan.remainsInPrimary == 1500)
        #expect(plan.accountExpenseTransfers.map(\.accountId) == [joint.id])
        #expect(plan.accountExpenseTransfers.first?.amount == 2500)
        #expect(plan.remainingMoney == 3375)
        #expect(plan.sumOfParts == 8500)
        #expect(plan.isBalanced)
    }

    @Test func `Emergency fund built from scratch takes the whole savings pool`() throws {
        let plan = Fixture.plan(
            income: 10_000,
            accounts: [.primary(), .emergency(multiplier: 3), .savings()]
        )

        let emergencyAllocation = try #require(plan.emergencyAllocation)
        #expect(emergencyAllocation.amount == 2500)
        #expect(emergencyAllocation.isComplete == false)
        #expect(emergencyAllocation.progressBefore == 0)
        #expect(emergencyAllocation.progressChangeDisplay == "0% → 8%")
        #expect(plan.savingsAllocation == nil)
    }

    @Test func `Hard cap reached mid-month sends only the gap to emergency`() throws {
        let plan = Fixture.plan(
            income: 10_000,
            accounts: [
                .primary(),
                .emergency(multiplier: 3, hardCap: 10_000, currentBalance: 9800),
                .savings()
            ]
        )

        let emergencyAllocation = try #require(plan.emergencyAllocation)
        #expect(emergencyAllocation.targetAmount == 10_000, "Cap beats 3 × income = 30 000")
        #expect(emergencyAllocation.amount == 200)
        #expect(emergencyAllocation.isComplete)
        #expect(plan.savingsAllocation?.amount == 2300)
    }

    @Test func `Progress text rounds to nearest like the progress ring`() throws {
        let plan = Fixture.plan(
            income: 8500,
            allocation: Fixture.prioritized(0.29),
            accounts: [.primary(), .emergency(multiplier: 3, currentBalance: 5000)]
        )

        // 5000 / 25 500 = 19.6% → 20%; + 2465 = 7465 / 25 500 = 29.27% → 29%
        let emergencyAllocation = try #require(plan.emergencyAllocation)
        #expect(emergencyAllocation.progressChangeDisplay == "20% → 29%")
    }

    @Test func `Full emergency fund still shows its progress row but everything goes to savings`() {
        let plan = Fixture.plan(
            income: 10_000,
            accounts: [.primary(), .emergency(multiplier: 3, currentBalance: 30_000), .savings()]
        )

        #expect(plan.emergencyAllocation?.amount == 0)
        #expect(plan.emergencyAllocation?.isComplete == true)
        #expect(plan.savingsAllocation?.amount == 2500)
    }

    @Test func `Emergency account without a multiplier has no target and absorbs all savings`() {
        let emergency = AccountEntry(name: "Emergency", accountType: .emergency)
        let plan = Fixture.plan(income: 10_000, accounts: [.primary(), emergency, .savings()])

        #expect(plan.emergencyAllocation?.amount == 2500)
        #expect(plan.savingsAllocation == nil)
    }

    @Test func `Savings fall back to the first savings account when none is flagged primary`() {
        let fallback = AccountEntry.savings(name: "Broker", isPrimarySavings: false)
        let plan = Fixture.plan(
            income: 10_000,
            accounts: [.primary(), fallback, .savings(name: "Other", isPrimarySavings: false)]
        )

        #expect(plan.savingsAllocation?.accountId == fallback.id)
        #expect(plan.savingsAllocation?.amount == 2500)
    }

    @Test func `Savings with no account to receive them stay as remaining money`() {
        let plan = Fixture.plan(income: 10_000, accounts: [.primary()])

        #expect(plan.accountAllocations.isEmpty)
        #expect(plan.totalSavings == 0)
        #expect(plan.remainingMoney == 10_000)
        #expect(plan.isBalanced)
    }

    @Test func `Boosted 10 percent saves exactly 30 percent`() {
        let plan = Fixture.plan(
            income: 10_000,
            allocation: Fixture.prioritized(0.10, boost: true),
            accounts: [.primary(), .savings()]
        )

        // 0.1 × 3 in Double is 0.30000000000000004 — must not leak into money.
        #expect(plan.totalSavings == 3000)
    }

    @Test(arguments: zip([0.07, 0.13, 0.29, 0.1 + 0.2], [Decimal(595), 1105, 2465, 2550]))
    func `Slider percentages produce whole-cent savings`(percentage: Double, expected: Decimal) {
        let plan = Fixture.plan(
            income: 8500,
            allocation: Fixture.prioritized(percentage),
            accounts: [.primary(), .savings()]
        )

        #expect(plan.totalSavings == expected)
    }

    @Test func `Fixed savings amount is capped at what is left after expenses`() {
        let plan = Fixture.plan(
            income: 10_000,
            expenses: [Fixture.expense("Rent", 9500)],
            allocation: SavingsAllocationEntry(savingsInputMode: .fixedAmount, fixedAmount: 2000),
            accounts: [.primary(), .savings()]
        )

        #expect(plan.totalSavings == 500)
        #expect(plan.remainingMoney == 0)
        #expect(plan.isBalanced)
    }

    @Test func `Negative fixed savings amount saves nothing instead of inventing money`() {
        let plan = Fixture.plan(
            income: 10_000,
            allocation: SavingsAllocationEntry(savingsInputMode: .fixedAmount, fixedAmount: -500),
            accounts: [.primary(), .savings()]
        )

        #expect(plan.totalSavings == 0)
        #expect(plan.remainingMoney == 10_000)
    }

    // MARK: - Split mode

    @Test func `Split amounts exceeding available income are scaled down to exactly what is available`() {
        let plan = Fixture.plan(
            income: 1000,
            allocation: Fixture.split(emergency: 2000, savings: 1000),
            accounts: [.primary(), .emergency(multiplier: 3), .savings()]
        )

        // 1000 split 2:1 is 666.666…/333.333… — must round to cents and still add up.
        #expect(plan.emergencyAllocation?.amount == Decimal(string: "666.67"))
        #expect(plan.savingsAllocation?.amount == Decimal(string: "333.33"))
        #expect(plan.totalSavings == 1000)
        #expect(plan.remainingMoney == 0)
        #expect(plan.sumOfParts == 1000)
    }

    @Test func `Split mode redirects emergency overflow to savings once the gap is closed`() throws {
        let plan = Fixture.plan(
            income: 10_000,
            allocation: Fixture.split(emergency: 500, savings: 500),
            accounts: [.primary(), .emergency(multiplier: 3, currentBalance: 29_800), .savings()]
        )

        let emergencyAllocation = try #require(plan.emergencyAllocation)
        #expect(emergencyAllocation.amount == 200)
        #expect(emergencyAllocation.isComplete)
        #expect(plan.savingsAllocation?.amount == 800)
        #expect(plan.totalSavings == 1000)
    }

    @Test func `Split mode with a full emergency fund sends both amounts to savings`() {
        let plan = Fixture.plan(
            income: 10_000,
            allocation: Fixture.split(emergency: 500, savings: 500),
            accounts: [.primary(), .emergency(multiplier: 3, currentBalance: 30_000), .savings()]
        )

        #expect(plan.savingsAllocation?.amount == 1000)
    }

    @Test func `Split percentages resolve against available income`() {
        let allocation = SavingsAllocationEntry(
            allocationMode: .split,
            splitEmergencyInputMode: .percentage,
            splitEmergencyPercentage: 0.07,
            splitSavingsInputMode: .fixedAmount,
            splitSavingsAmount: 500
        )
        let plan = Fixture.plan(
            income: 10_000,
            expenses: [Fixture.expense("Rent", 1500)],
            allocation: allocation,
            accounts: [.primary(), .emergency(multiplier: 3), .savings()]
        )

        #expect(plan.emergencyAllocation?.amount == 595)
        #expect(plan.savingsAllocation?.amount == 500)
    }

    // MARK: - Expenses

    @Test func `Expenses exceeding income report the shortfall instead of negative savings`() {
        let plan = Fixture.plan(
            income: 3000,
            expenses: [Fixture.expense("Rent", 3500)],
            accounts: [.primary(), .emergency(multiplier: 3), .savings()]
        )

        #expect(plan.availableIncome == 0)
        #expect(plan.totalSavings == 0)
        #expect(plan.remainingMoney == 0)
        #expect(plan.shortfall == 500)
        #expect(plan.remainsInPrimary == 3000, "Only the salary that exists can stay in primary")
        #expect(plan.sumOfParts == 3000)
        #expect(plan.isBalanced == false, "Nothing can make 3500 of bills fit in 3000")
    }

    @Test func `Salary below bills pays the linked Joint rent first and never invents money`() {
        let primary = AccountEntry.primary()
        let joint = AccountEntry.joint()
        let accounts = [primary, joint]
        let plan = Fixture.plan(
            income: 4000,
            expenses: [Fixture.expense("Rent", 2500, linkedTo: joint), Fixture.expense("Bills", 2400)],
            accounts: accounts
        )

        #expect(plan.accountExpenseTransfers.map(\.amount) == [2500])
        #expect(plan.remainsInPrimary == 1500)
        #expect(plan.shortfall == 900)
        #expect(plan.sumOfParts == 4000)

        let balances = BalanceReconciler.updatedBalances(plan: plan, accounts: accounts, reconciledBalances: [:])
        #expect(balances[primary.id] == 1500)
        #expect(balances[joint.id] == 2500)
    }

    @Test func `Linked transfers alone above income are scaled down to exactly the income`() {
        let joint = AccountEntry.joint()
        let personal = AccountEntry.personal()
        let plan = Fixture.plan(
            income: 1000,
            expenses: [
                Fixture.expense("Rent", 2000, linkedTo: joint),
                Fixture.expense("Phone", 1000, linkedTo: personal),
                Fixture.expense("Bills", 500)
            ],
            accounts: [.primary(), joint, personal]
        )

        // 3000 of transfers into 1000: 2:1 → 666.67 + 333.33, nothing left for primary
        #expect(plan.accountExpenseTransfers.map(\.amount) == [Decimal(string: "666.67")!, Decimal(string: "333.33")!])
        #expect(plan.remainsInPrimary == 0)
        #expect(plan.shortfall == 2500)
        #expect(plan.sumOfParts == 1000)
    }

    @Test func `Disabled, zero and negative expenses are left out of the plan`() {
        let plan = Fixture.plan(
            income: 5000,
            expenses: [
                Fixture.expense("Gym", 200, enabled: false),
                Fixture.expense("Placeholder", 0),
                Fixture.expense("Refund", -300),
                Fixture.expense("Rent", 2000)
            ],
            accounts: [.primary()]
        )

        #expect(plan.totalExpenses == 2000)
        #expect(plan.remainsInPrimary == 2000)
        #expect(plan.isBalanced)
    }

    @Test func `Expense linked to a deleted account stays in primary`() {
        let ghost = AccountEntry.joint(name: "Deleted")
        let plan = Fixture.plan(
            income: 5000,
            expenses: [Fixture.expense("Food", 800, linkedTo: ghost)],
            accounts: [.primary()]
        )

        #expect(plan.accountExpenseTransfers.isEmpty)
        #expect(plan.remainsInPrimary == 800)
    }

    @Test func `Expense linked to the primary account itself is not a transfer`() {
        let primary = AccountEntry.primary()
        let plan = Fixture.plan(
            income: 5000,
            expenses: [Fixture.expense("Utilities", 400, linkedTo: primary)],
            accounts: [primary]
        )

        #expect(plan.accountExpenseTransfers.isEmpty)
        #expect(plan.remainsInPrimary == 400)
    }

    @Test func `Expense transfers follow account order and group expenses per account`() {
        let joint = AccountEntry.joint(name: "Joint")
        let personal = AccountEntry.personal(name: "Personal")
        let kids = AccountEntry(name: "Kids", accountType: .other)
        let car = AccountEntry(name: "Car", accountType: .other)
        let partner = AccountEntry.personal(name: "Partner")
        let holiday = AccountEntry(name: "Holiday", accountType: .other)
        let linked = [joint, personal, kids, car, partner, holiday]
        let plan = Fixture.plan(
            income: 10_000,
            expenses: [
                Fixture.expense("Trip", 400, linkedTo: holiday),
                Fixture.expense("School", 300, linkedTo: kids),
                Fixture.expense("Rent", 2000, linkedTo: joint),
                Fixture.expense("Gift", 100, linkedTo: partner),
                Fixture.expense("Hobby", 150, linkedTo: personal),
                Fixture.expense("Fuel", 250, linkedTo: car),
                Fixture.expense("Food", 900, linkedTo: joint)
            ],
            accounts: [.primary()] + linked
        )

        // Six accounts: a Dictionary-ordered plan matches by luck 1 time in 720.
        #expect(plan.accountExpenseTransfers.map(\.accountId) == linked.map(\.id))
        #expect(plan.accountExpenseTransfers.map(\.amount) == [2900, 150, 300, 250, 100, 400])
        #expect(plan.accountExpenseTransfers.first?.expenseNames == ["Rent", "Food"])
    }

    // MARK: - Identity

    @Test func `Plan rows keep their ids across recalculation`() {
        let joint = AccountEntry.joint()
        let accounts = [AccountEntry.primary(), joint, .emergency(multiplier: 3), .savings()]
        let expenses = [Fixture.expense("Rent", 2000, linkedTo: joint)]

        let first = Fixture.plan(income: 8500, expenses: expenses, accounts: accounts)
        let second = Fixture.plan(income: 9000, expenses: expenses, accounts: accounts)

        #expect(first.accountAllocations.map(\.id) == second.accountAllocations.map(\.id))
        #expect(first.accountExpenseTransfers.map(\.id) == [joint.id])
        #expect(second.accountExpenseTransfers.map(\.id) == [joint.id])
    }

    @Test func `An emergency account flagged as primary savings is never allocated twice`() {
        let emergency = AccountEntry(
            name: "Emergency", accountType: .emergency, isPrimarySavings: true, emergencyMultiplier: 3,
            currentBalance: 30_000
        )
        let savings = AccountEntry.savings(isPrimarySavings: false)
        let plan = Fixture.plan(income: 10_000, accounts: [.primary(), emergency, savings])

        #expect(Set(plan.accountAllocations.map(\.id)).count == plan.accountAllocations.count)
        #expect(plan.savingsAllocation?.accountId == savings.id)
        #expect(plan.savingsAllocation?.amount == 2500)
    }

    // MARK: - Invariant

    static let awkwardIncomes: [Decimal] = [
        Decimal(string: "0.01")!, Decimal(string: "0.03")!, Decimal(string: "0.10")!,
        Decimal(string: "100.01")!, 8500
    ]

    static let awkwardAllocations: [SavingsAllocationEntry] = [
        Fixture.prioritized(0.07),
        Fixture.prioritized(0.13, boost: true),
        Fixture.split(emergency: 1, savings: 2),                    // 1/3 : 2/3 once over-subscribed
        Fixture.split(emergency: Decimal(string: "333.33")!, savings: Decimal(string: "666.67")!),
        SavingsAllocationEntry(savingsInputMode: .fixedAmount, fixedAmount: Decimal(string: "0.02")!)
    ]

    /// Rounding residue must land in one defined place (remaining money), never drift.
    @Test(arguments: awkwardIncomes, awkwardAllocations)
    func `Awkward incomes and thirds still add up to the cent`(
        income: Decimal,
        allocation: SavingsAllocationEntry
    ) {
        let plan = Fixture.plan(
            income: income,
            allocation: allocation,
            accounts: [.primary(), .emergency(multiplier: 3), .savings()]
        )

        #expect(plan.sumOfParts == income)
        #expect(plan.totalSavings <= plan.availableIncome)
        #expect(plan.allAmounts.allSatisfy { $0 >= 0 && $0.isWholeCents }, "\(plan.allAmounts)")
    }

    static let incomes: [Decimal] = [0, 1, Decimal(string: "999.99")!, Decimal(string: "4321.57")!, 8500, 123_456]

    static let allocations: [SavingsAllocationEntry] = [
        Fixture.prioritized(0.07),
        Fixture.prioritized(0.13, boost: true),
        SavingsAllocationEntry(savingsInputMode: .fixedAmount, fixedAmount: Decimal(string: "777.77")!),
        Fixture.split(emergency: Decimal(string: "333.33")!, savings: Decimal(string: "1111.11")!),
        SavingsAllocationEntry(
            allocationMode: .split,
            splitEmergencyInputMode: .percentage,
            splitEmergencyPercentage: 0.07,
            splitSavingsInputMode: .percentage,
            splitSavingsPercentage: 0.11
        )
    ]

    @Test(arguments: incomes, allocations)
    func `Every unit of income is accounted for in whole cents`(
        income: Decimal,
        allocation: SavingsAllocationEntry
    ) {
        let joint = AccountEntry.joint()
        let plan = Fixture.plan(
            income: income,
            expenses: [
                Fixture.expense("Rent", Decimal(string: "1234.56")!, linkedTo: joint),
                Fixture.expense("Insurance", 1000, .annual),
                Fixture.expense("Food", 500)
            ],
            allocation: allocation,
            accounts: [
                .primary(),
                joint,
                .emergency(multiplier: 3.5, hardCap: 20_000, currentBalance: 1000),
                .savings()
            ]
        )

        #expect(plan.allAmounts.allSatisfy { $0 >= 0 && $0.isWholeCents }, "\(plan.allAmounts)")
        #expect(plan.totalSavings == plan.totalAccountAllocations)
        #expect(plan.sumOfParts == income, "Even short months never plan more money than there is")
        #expect(plan.shortfall == max(0, plan.totalExpenses - income))
        #expect(plan.isBalanced == (plan.shortfall == 0))
    }
}
