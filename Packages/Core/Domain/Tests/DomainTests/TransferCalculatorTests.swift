import Foundation
import Testing
@testable import Domain

/// Tests for TransferCalculator - the core business logic that determines
/// how money flows from income through accounts based on account types.
@Suite("TransferCalculator Tests")
struct TransferCalculatorTests {

    // MARK: - Test Fixtures

    /// Standard test income for consistent calculations
    static let testIncome: Decimal = 10000

    /// Creates a standard allocation with given percentage
    static func allocation(percentage: Double = 0.25, boost: Bool = false) -> SavingsAllocationEntry {
        SavingsAllocationEntry(percentage: percentage, boostEnabled: boost, boostMultiplier: 3.0)
    }

    /// Creates a basic set of accounts for testing
    static func basicAccounts() -> [AccountEntry] {
        [
            .primary(name: "Main"),
            .emergency(name: "Emergency", multiplier: 3.0, currentBalance: 0),
            .savings(name: "Savings", isPrimarySavings: true)
        ]
    }

    // MARK: - Basic Calculations

    @Suite("Basic Calculations")
    struct BasicCalculations {

        @Test("Income minus expenses equals available income")
        func availableIncomeCalculation() {
            let expenses = [
                ExpenseEntry(name: "Rent", amount: 2000, icon: "house"),
                ExpenseEntry(name: "Food", amount: 1000, icon: "cart")
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: expenses,
                allocation: allocation(),
                accounts: [.primary()],
                remainingDestination: .primary
            )

            #expect(plan.totalExpenses == 3000)
            #expect(plan.availableIncome == 7000) // 10000 - 3000
        }

        @Test("Savings calculated from available income, not total income")
        func savingsFromAvailableIncome() {
            let expenses = [ExpenseEntry(name: "Rent", amount: 5000, icon: "house")]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: expenses,
                allocation: allocation(percentage: 0.20), // 20%
                accounts: [.primary(), .savings()],
                remainingDestination: .primary
            )

            // Available: 10000 - 5000 = 5000
            // Savings: 5000 * 0.20 = 1000
            #expect(plan.totalSavings == 1000)
        }

        @Test("Zero expenses means full income available")
        func zeroExpenses() {
            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.10),
                accounts: [.primary(), .savings()],
                remainingDestination: .primary
            )

            #expect(plan.totalExpenses == 0)
            #expect(plan.availableIncome == testIncome)
            #expect(plan.totalSavings == 1000) // 10000 * 0.10
        }

        @Test("Plan is always balanced")
        func planIsBalanced() {
            let expenses = [
                ExpenseEntry(name: "Rent", amount: 2500, icon: "house"),
                ExpenseEntry(name: "Food", amount: 800, icon: "cart"),
                ExpenseEntry(name: "Transport", amount: 300, icon: "car")
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: expenses,
                allocation: allocation(percentage: 0.25),
                accounts: basicAccounts(),
                remainingDestination: .primarySavings
            )

            #expect(plan.isBalanced)
        }

        @Test("Expenses exceeding income result in zero available",
              arguments: [11000, 15000, 20000] as [Decimal])
        func expensesExceedIncome(expenseAmount: Decimal) {
            let expenses = [ExpenseEntry(name: "Huge Expense", amount: expenseAmount, icon: "exclamationmark")]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: expenses,
                allocation: allocation(),
                accounts: [.primary()],
                remainingDestination: .primary
            )

            #expect(plan.availableIncome == 0)
            #expect(plan.totalSavings == 0)
            #expect(plan.remainingMoney == 0)
        }
    }

    // MARK: - Emergency Account Priority

    @Suite("Emergency Account Priority")
    struct EmergencyAccountPriority {

        @Test("Emergency account fills before savings account")
        func emergencyFillsFirst() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                AccountEntry.emergency(name: "Emergency", multiplier: 3.0, currentBalance: 0),
                AccountEntry.savings(name: "Savings", isPrimarySavings: true)
            ]

            // With 10000 income, 3x target = 30000
            // 25% savings = 2500 per month
            // All 2500 should go to emergency first
            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25),
                accounts: accounts,
                remainingDestination: .primary
            )

            let emergencyAlloc = plan.emergencyAllocation
            let savingsAlloc = plan.savingsAllocation

            #expect(emergencyAlloc != nil)
            #expect(emergencyAlloc?.amount == 2500)
            #expect(savingsAlloc == nil) // No overflow to savings yet
        }

        @Test("Savings receives overflow when emergency is full")
        func savingsGetsOverflow() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                // Emergency already at target (30000)
                AccountEntry.emergency(name: "Emergency", multiplier: 3.0, currentBalance: 30000),
                AccountEntry.savings(name: "Savings", isPrimarySavings: true)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25),
                accounts: accounts,
                remainingDestination: .primary
            )

            let emergencyAlloc = plan.emergencyAllocation
            let savingsAlloc = plan.savingsAllocation

            // Emergency is full, should get 0
            #expect(emergencyAlloc?.amount == 0)
            #expect(emergencyAlloc?.isComplete == true)

            // All savings go to savings account
            #expect(savingsAlloc?.amount == 2500)
        }

        @Test("Partial emergency fill with remainder to savings")
        func partialEmergencyFill() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                // Emergency needs 1000 more to reach 30000 target
                AccountEntry.emergency(name: "Emergency", multiplier: 3.0, currentBalance: 29000),
                AccountEntry.savings(name: "Savings", isPrimarySavings: true)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25), // 2500 total savings
                accounts: accounts,
                remainingDestination: .primary
            )

            let emergencyAlloc = plan.emergencyAllocation
            let savingsAlloc = plan.savingsAllocation

            // Emergency gets only what it needs (1000)
            #expect(emergencyAlloc?.amount == 1000)
            #expect(emergencyAlloc?.isComplete == true)

            // Savings gets remainder (1500)
            #expect(savingsAlloc?.amount == 1500)
        }

        @Test("Emergency multiplier affects target",
              arguments: [3.0, 4.0, 5.0, 6.0])
        func emergencyMultiplierAffectsTarget(multiplier: Double) {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                AccountEntry.emergency(name: "Emergency", multiplier: multiplier, currentBalance: 0)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.50), // Max savings
                accounts: accounts,
                remainingDestination: .primary
            )

            let emergencyAlloc = try? #require(plan.emergencyAllocation)
            let expectedTarget = testIncome * Decimal(multiplier)

            #expect(emergencyAlloc?.targetAmount == expectedTarget)
        }

        @Test("Emergency progress tracking is accurate")
        func emergencyProgressTracking() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                // 15000 of 30000 = 50% progress
                AccountEntry.emergency(name: "Emergency", multiplier: 3.0, currentBalance: 15000),
                AccountEntry.savings(name: "Savings", isPrimarySavings: true)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25), // 2500 savings
                accounts: accounts,
                remainingDestination: .primary
            )

            let emergencyAlloc = plan.emergencyAllocation

            // Before: 15000/30000 = 50%
            #expect(emergencyAlloc?.progressBefore == 0.5)

            // After: (15000 + 2500) / 30000 = 58.33%
            let expectedProgressAfter = 17500.0 / 30000.0
            if let progressAfter = emergencyAlloc?.progressAfter {
                #expect(abs(progressAfter - expectedProgressAfter) < 0.01)
            }
        }

        @Test("Emergency with hard cap uses capped target")
        func emergencyWithHardCapUsesCappedTarget() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                // 3x income = 30000, but capped to 20000
                AccountEntry.emergency(name: "Emergency", multiplier: 3.0, hardCap: 20000, currentBalance: 0),
                AccountEntry.savings(name: "Savings", isPrimarySavings: true)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25), // 2500 savings
                accounts: accounts,
                remainingDestination: .primary
            )

            let emergencyAlloc = plan.emergencyAllocation

            // Target should be capped at 20000, not 30000
            #expect(emergencyAlloc?.targetAmount == 20000)
            #expect(emergencyAlloc?.amount == 2500)
        }

        @Test("Emergency hard cap overflow goes to savings")
        func emergencyHardCapOverflowGoesToSavings() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                // 3x income = 30000, capped to 20000, already has 19000 (needs only 1000)
                AccountEntry.emergency(name: "Emergency", multiplier: 3.0, hardCap: 20000, currentBalance: 19000),
                AccountEntry.savings(name: "Savings", isPrimarySavings: true)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25), // 2500 savings
                accounts: accounts,
                remainingDestination: .primary
            )

            let emergencyAlloc = plan.emergencyAllocation
            let savingsAlloc = plan.savingsAllocation

            // Emergency needs only 1000 to reach capped target of 20000
            #expect(emergencyAlloc?.amount == 1000)
            #expect(emergencyAlloc?.isComplete == true)

            // Remaining 1500 should go to savings
            #expect(savingsAlloc?.amount == 1500)
        }

        @Test("Emergency fully funded at hard cap")
        func emergencyFullyFundedAtHardCap() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                // 3x income = 30000, capped to 20000, already at cap
                AccountEntry.emergency(name: "Emergency", multiplier: 3.0, hardCap: 20000, currentBalance: 20000),
                AccountEntry.savings(name: "Savings", isPrimarySavings: true)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25), // 2500 savings
                accounts: accounts,
                remainingDestination: .primary
            )

            let emergencyAlloc = plan.emergencyAllocation
            let savingsAlloc = plan.savingsAllocation

            // Emergency is complete at capped target
            #expect(emergencyAlloc?.amount == 0)
            #expect(emergencyAlloc?.isComplete == true)

            // All savings go to savings account
            #expect(savingsAlloc?.amount == 2500)
        }
    }

    // MARK: - Savings Account Behavior

    @Suite("Savings Account Behavior")
    struct SavingsAccountBehavior {

        @Test("Primary savings account receives allocation")
        func primarySavingsReceivesAllocation() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                AccountEntry.savings(name: "My Savings", isPrimarySavings: true)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.30),
                accounts: accounts,
                remainingDestination: .primary
            )

            let savingsAlloc = plan.savingsAllocation
            #expect(savingsAlloc?.amount == 3000)
            #expect(savingsAlloc?.accountName == "My Savings")
        }

        @Test("Falls back to first savings-type account if no primary savings")
        func fallbackToFirstSavingsAccount() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                // Savings account but NOT marked as primary savings
                AccountEntry(name: "General Savings", accountType: .savings, isPrimarySavings: false)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.20),
                accounts: accounts,
                remainingDestination: .primary
            )

            let savingsAlloc = plan.savingsAllocation
            #expect(savingsAlloc?.amount == 2000)
            #expect(savingsAlloc?.accountName == "General Savings")
        }

        @Test("No savings allocation when no savings account exists")
        func noSavingsAccountMeansNoAllocation() {
            let accounts = [
                AccountEntry.primary(name: "Main"),
                AccountEntry.personal(name: "Personal")
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25),
                accounts: accounts,
                remainingDestination: .primary
            )

            #expect(plan.savingsAllocation == nil)
            #expect(plan.totalSavings == 0)
        }
    }

    // MARK: - Boost Mode

    @Suite("Boost Mode")
    struct BoostMode {

        @Test("Boost multiplies savings percentage")
        func boostMultipliesSavings() {
            let accounts: [AccountEntry] = [.primary(), .savings()]

            // 10% base * 3x boost = 30%
            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.10, boost: true),
                accounts: accounts,
                remainingDestination: .primary
            )

            #expect(abs(plan.totalSavings - 3000) < 0.01) // 10000 * 0.30
        }

        @Test("Boost disabled means base percentage",
              arguments: [0.10, 0.20, 0.30, 0.40, 0.50])
        func boostDisabledUsesBase(percentage: Double) {
            let accounts: [AccountEntry] = [.primary(), .savings()]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: percentage, boost: false),
                accounts: accounts,
                remainingDestination: .primary
            )

            let expectedSavings = testIncome * Decimal(percentage)
            #expect(abs(plan.totalSavings - expectedSavings) < 0.01)
        }
    }

    // MARK: - Expense Distribution

    @Suite("Expense Distribution")
    struct ExpenseDistribution {

        @Test("Unlinked expenses stay in primary account")
        func unlinkedExpensesStayInPrimary() {
            let expenses = [
                ExpenseEntry(name: "Rent", amount: 1500, icon: "house", linkedAccountId: nil),
                ExpenseEntry(name: "Food", amount: 500, icon: "cart", linkedAccountId: nil)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: expenses,
                allocation: allocation(),
                accounts: [.primary()],
                remainingDestination: .primary
            )

            #expect(plan.remainsInPrimary == 2000)
            #expect(plan.accountExpenseTransfers.isEmpty)
        }

        @Test("Linked expenses create transfers to target accounts")
        func linkedExpensesCreateTransfers() {
            let jointAccount = AccountEntry(
                name: "Joint Account",
                accountType: .joint,
                isPrimary: false
            )
            // Need to get the actual ID from the account we create
            let accounts = [AccountEntry.primary(), jointAccount]
            let actualJointId = accounts[1].id

            let expenses = [
                ExpenseEntry(name: "Rent", amount: 1500, icon: "house", linkedAccountId: nil),
                ExpenseEntry(name: "Utilities", amount: 300, icon: "bolt", linkedAccountId: actualJointId),
                ExpenseEntry(name: "Internet", amount: 100, icon: "wifi", linkedAccountId: actualJointId)
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: expenses,
                allocation: allocation(),
                accounts: accounts,
                remainingDestination: .primary
            )

            #expect(plan.remainsInPrimary == 1500) // Only unlinked rent
            #expect(plan.accountExpenseTransfers.count == 1)

            if let jointTransfer = plan.accountExpenseTransfers.first {
                #expect(jointTransfer.amount == 400) // 300 + 100
                #expect(jointTransfer.accountName == "Joint Account")
                #expect(jointTransfer.expenseNames.count == 2)
            }
        }

        @Test("Zero amount expenses are ignored")
        func zeroExpensesIgnored() {
            let expenses = [
                ExpenseEntry(name: "Rent", amount: 1000, icon: "house"),
                ExpenseEntry(name: "Unused", amount: 0, icon: "xmark"),
                ExpenseEntry(name: "Food", amount: 500, icon: "cart")
            ]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: expenses,
                allocation: allocation(),
                accounts: [.primary()],
                remainingDestination: .primary
            )

            #expect(plan.totalExpenses == 1500)
        }
    }

    // MARK: - Remaining Money

    @Suite("Remaining Money")
    struct RemainingMoney {

        @Test("Remaining money calculated correctly")
        func remainingMoneyCalculation() {
            let expenses = [ExpenseEntry(name: "Rent", amount: 3000, icon: "house")]

            // Income: 10000, Expenses: 3000, Available: 7000
            // Savings at 20%: 1400
            // Remaining: 7000 - 1400 = 5600
            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: expenses,
                allocation: allocation(percentage: 0.20),
                accounts: [.primary(), .savings()],
                remainingDestination: .primary
            )

            #expect(plan.remainingMoney == 5600)
        }

        @Test("Remaining destination is preserved in plan",
              arguments: RemainingMoneyDestination.allCases)
        func remainingDestinationPreserved(destination: RemainingMoneyDestination) {
            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(),
                accounts: [.primary(), .savings(), .personal()],
                remainingDestination: destination
            )

            #expect(plan.remainingDestination == destination)
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCases {

        @Test("Zero income produces zero everything")
        func zeroIncome() {
            let plan = TransferCalculator.calculate(
                income: 0,
                expenses: [],
                allocation: allocation(),
                accounts: basicAccounts(),
                remainingDestination: .primary
            )

            #expect(plan.income == 0)
            #expect(plan.availableIncome == 0)
            #expect(plan.totalSavings == 0)
            #expect(plan.remainingMoney == 0)
            #expect(plan.isBalanced)
        }

        @Test("Very small amounts don't cause rounding issues")
        func smallAmounts() {
            let plan = TransferCalculator.calculate(
                income: Decimal(string: "100.50")!,
                expenses: [ExpenseEntry(name: "Small", amount: Decimal(string: "33.33")!, icon: "minus")],
                allocation: allocation(percentage: 0.10),
                accounts: [.primary(), .savings()],
                remainingDestination: .primary
            )

            #expect(plan.isBalanced)
        }

        @Test("Large amounts don't overflow")
        func largeAmounts() {
            let largeIncome: Decimal = 1_000_000_000 // 1 billion

            let plan = TransferCalculator.calculate(
                income: largeIncome,
                expenses: [],
                allocation: allocation(percentage: 0.50),
                accounts: [.primary(), .savings()],
                remainingDestination: .primary
            )

            #expect(plan.totalSavings == 500_000_000)
            #expect(plan.isBalanced)
        }

        @Test("Only primary account still produces valid plan")
        func onlyPrimaryAccount() {
            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [ExpenseEntry(name: "Rent", amount: 2000, icon: "house")],
                allocation: allocation(percentage: 0.25),
                accounts: [.primary()],
                remainingDestination: .primary
            )

            // No savings accounts, so no savings allocated
            #expect(plan.totalSavings == 0)
            #expect(plan.accountAllocations.isEmpty)
            // All available income becomes remaining money
            #expect(plan.remainingMoney == 8000) // 10000 - 2000
            #expect(plan.isBalanced)
        }

        @Test("Emergency account without multiplier gets all savings")
        func emergencyWithoutMultiplier() {
            var emergency = AccountEntry.emergency(name: "Emergency", multiplier: 3.0)
            emergency.emergencyMultiplier = nil // Remove multiplier

            let accounts = [.primary(), emergency, .savings()]

            let plan = TransferCalculator.calculate(
                income: testIncome,
                expenses: [],
                allocation: allocation(percentage: 0.25),
                accounts: accounts,
                remainingDestination: .primary
            )

            // Without target, emergency should receive all savings
            let emergencyAlloc = plan.emergencyAllocation
            #expect(emergencyAlloc?.amount == 2500)
            #expect(emergencyAlloc?.targetAmount == nil)
        }
    }

    // MARK: - Real World Scenarios

    @Suite("Real World Scenarios")
    struct RealWorldScenarios {

        @Test("Typical salary with standard expenses")
        func typicalSalaryScenario() {
            let income: Decimal = 14303 // Typical Romanian salary
            let expenses = [
                ExpenseEntry(name: "Rent", amount: 3500, icon: "house"),
                ExpenseEntry(name: "Food", amount: 1800, icon: "cart"),
                ExpenseEntry(name: "Transport", amount: 600, icon: "car"),
                ExpenseEntry(name: "Subscriptions", amount: 200, icon: "repeat")
            ]

            let accounts = [
                AccountEntry.primary(name: "BT Checking"),
                AccountEntry.emergency(name: "Emergency Fund", multiplier: 3.0, currentBalance: 10000),
                AccountEntry.savings(name: "Savings", isPrimarySavings: true)
            ]

            let plan = TransferCalculator.calculate(
                income: income,
                expenses: expenses,
                allocation: SavingsAllocationEntry(percentage: 0.25, boostEnabled: false),
                accounts: accounts,
                remainingDestination: .primarySavings
            )

            // Income: 14303
            // Expenses: 6100
            // Available: 8203
            // Savings (25%): 2050.75
            // Remaining: 6152.25

            #expect(plan.totalExpenses == 6100)
            #expect(plan.isBalanced)
            #expect(plan.emergencyAllocation != nil)
        }

        @Test("User building emergency fund from scratch")
        func buildingEmergencyFund() {
            let income: Decimal = 8000
            let accounts = [
                AccountEntry.primary(),
                AccountEntry.emergency(name: "Emergency", multiplier: 6.0, currentBalance: 0), // 6 months target
                AccountEntry.savings(isPrimarySavings: true)
            ]

            // Target: 8000 * 6 = 48000
            // With aggressive 50% savings rate
            let plan = TransferCalculator.calculate(
                income: income,
                expenses: [],
                allocation: SavingsAllocationEntry(percentage: 0.50, boostEnabled: false),
                accounts: accounts,
                remainingDestination: .primary
            )

            // All 4000 savings should go to emergency (needs 48000)
            #expect(plan.emergencyAllocation?.amount == 4000)
            #expect(plan.savingsAllocation == nil) // Nothing left for regular savings
            #expect(plan.emergencyAllocation?.isComplete == false)
        }

        @Test("User with boost enabled to accelerate savings")
        func boostAcceleratedSavings() {
            let income: Decimal = 12000
            let expenses = [ExpenseEntry(name: "Living costs", amount: 4000, icon: "house")]

            let accounts = [
                AccountEntry.primary(),
                // Emergency almost complete
                AccountEntry.emergency(name: "Emergency", multiplier: 3.0, currentBalance: 35000),
                AccountEntry.savings(isPrimarySavings: true)
            ]

            // Available: 8000
            // Base savings 15% = 1200, but with 3x boost = 3600
            let plan = TransferCalculator.calculate(
                income: income,
                expenses: expenses,
                allocation: SavingsAllocationEntry(percentage: 0.15, boostEnabled: true, boostMultiplier: 3.0),
                accounts: accounts,
                remainingDestination: .personal
            )

            // 8000 * 0.45 (15% * 3) = 3600
            #expect(abs(plan.totalSavings - 3600) < 0.01)
            // Emergency target is 36000, has 35000, needs 1000
            #expect(plan.emergencyAllocation?.amount == 1000)
            #expect(plan.emergencyAllocation?.isComplete == true)
            // Remaining 2600 goes to savings (3600 - 1000)
            #expect(abs((plan.savingsAllocation?.amount ?? 0) - 2600) < 0.01)
        }
    }
}
