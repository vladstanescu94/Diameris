import Foundation
import Testing
@testable import Dashboard
import Utilities
import Domain

/// Tests for DashboardAccount - validates emergency fund calculations
/// and account property behavior.
@Suite("DashboardAccount Tests")
struct DashboardAccountTests {

    // MARK: - Test Helpers

    static func makeAccount(
        accountType: AccountType = .primary,
        isPrimary: Bool = false,
        isPrimarySavings: Bool = false,
        emergencyMultiplier: Double? = nil,
        currentBalance: Decimal = 0
    ) -> DashboardAccount {
        DashboardAccount(
            id: UUID(),
            name: "Test Account",
            accountType: accountType,
            isPrimary: isPrimary,
            isPrimarySavings: isPrimarySavings,
            emergencyMultiplier: emergencyMultiplier,
            currentBalance: currentBalance
        )
    }

    // MARK: - Emergency Target

    @Suite("Emergency Target Calculation")
    struct EmergencyTarget {

        @Test("Emergency account returns target based on multiplier")
        func emergencyTargetCalculation() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: 3.0,
                currentBalance: 5000
            )

            let target = account.emergencyTarget(monthlyIncome: 10000)

            #expect(target == 30000)
        }

        @Test("Non-emergency account returns nil target")
        func nonEmergencyReturnsNil() {
            let primaryAccount = DashboardAccountTests.makeAccount(accountType: .primary)
            let savingsAccount = DashboardAccountTests.makeAccount(accountType: .savings)
            let personalAccount = DashboardAccountTests.makeAccount(accountType: .personal)
            let jointAccount = DashboardAccountTests.makeAccount(accountType: .joint)

            #expect(primaryAccount.emergencyTarget(monthlyIncome: 10000) == nil)
            #expect(savingsAccount.emergencyTarget(monthlyIncome: 10000) == nil)
            #expect(personalAccount.emergencyTarget(monthlyIncome: 10000) == nil)
            #expect(jointAccount.emergencyTarget(monthlyIncome: 10000) == nil)
        }

        @Test("Emergency account without multiplier returns nil")
        func emergencyWithoutMultiplierReturnsNil() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: nil
            )

            #expect(account.emergencyTarget(monthlyIncome: 10000) == nil)
        }

        @Test("Emergency target with various multipliers",
              arguments: [
                (multiplier: 1.0, income: Decimal(10000), expected: Decimal(10000)),
                (multiplier: 3.0, income: Decimal(10000), expected: Decimal(30000)),
                (multiplier: 6.0, income: Decimal(5000), expected: Decimal(30000)),
                (multiplier: 12.0, income: Decimal(8000), expected: Decimal(96000))
              ])
        func emergencyTargetWithMultipliers(multiplier: Double, income: Decimal, expected: Decimal) {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: multiplier
            )

            let target = account.emergencyTarget(monthlyIncome: income)

            #expect(target == expected)
        }

        @Test("Emergency target with zero income is zero")
        func emergencyTargetZeroIncome() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: 3.0
            )

            let target = account.emergencyTarget(monthlyIncome: 0)

            #expect(target == 0)
        }
    }

    // MARK: - Emergency Progress

    @Suite("Emergency Progress Calculation")
    struct EmergencyProgress {

        @Test("Progress is 0 when balance is 0")
        func progressZeroBalance() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: 3.0,
                currentBalance: 0
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)

            #expect(progress == 0.0)
        }

        @Test("Progress is 1.0 when target is met")
        func progressAtTarget() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: 3.0,
                currentBalance: 30000
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)

            #expect(progress == 1.0)
        }

        @Test("Progress is capped at 1.0 when exceeding target")
        func progressCappedAtOne() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: 3.0,
                currentBalance: 50000 // More than 30000 target
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)

            #expect(progress == 1.0)
        }

        @Test("Progress is 0.5 at halfway point")
        func progressHalfway() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: 3.0,
                currentBalance: 15000 // Half of 30000 target
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)

            // Use tolerance for floating point comparison
            #expect(progress != nil)
            #expect(abs(progress! - 0.5) < 0.001)
        }

        @Test("Progress returns nil for non-emergency accounts")
        func progressNilForNonEmergency() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .savings,
                currentBalance: 5000
            )

            #expect(account.emergencyProgress(monthlyIncome: 10000) == nil)
        }

        @Test("Progress returns nil when target is zero (zero income)")
        func progressNilWhenTargetZero() {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: 3.0,
                currentBalance: 5000
            )

            #expect(account.emergencyProgress(monthlyIncome: 0) == nil)
        }

        @Test("Progress with various balances",
              arguments: [
                (balance: Decimal(0), expected: 0.0),
                (balance: Decimal(7500), expected: 0.25),
                (balance: Decimal(15000), expected: 0.5),
                (balance: Decimal(22500), expected: 0.75),
                (balance: Decimal(30000), expected: 1.0),
                (balance: Decimal(45000), expected: 1.0)  // Capped
              ])
        func progressWithBalances(balance: Decimal, expected: Double) {
            let account = DashboardAccountTests.makeAccount(
                accountType: .emergency,
                emergencyMultiplier: 3.0,
                currentBalance: balance
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)

            #expect(progress != nil)
            #expect(abs(progress! - expected) < 0.001)
        }
    }

    // MARK: - Account Properties

    @Suite("Account Properties")
    struct AccountProperties {

        @Test("Account stores all properties correctly")
        func accountStoresProperties() {
            let id = UUID()
            let account = DashboardAccount(
                id: id,
                name: "My Savings",
                accountType: .savings,
                isPrimary: false,
                isPrimarySavings: true,
                emergencyMultiplier: nil,
                currentBalance: 5000
            )

            #expect(account.id == id)
            #expect(account.name == "My Savings")
            #expect(account.accountType == .savings)
            #expect(account.isPrimary == false)
            #expect(account.isPrimarySavings == true)
            #expect(account.emergencyMultiplier == nil)
            #expect(account.currentBalance == 5000)
        }

        @Test("Account conforms to Identifiable")
        func accountIsIdentifiable() {
            let account1 = DashboardAccountTests.makeAccount()
            let account2 = DashboardAccountTests.makeAccount()

            #expect(account1.id != account2.id)
        }

        @Test("Account conforms to Sendable")
        func accountIsSendable() async {
            let account = DashboardAccountTests.makeAccount(currentBalance: 1000)

            let balance = await Task.detached {
                return account.currentBalance
            }.value

            #expect(balance == 1000)
        }
    }
}
