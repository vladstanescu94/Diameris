import Foundation
import Testing
@testable import Domain

/// Tests for AccountEntry model - validates computed properties,
/// factory methods, and emergency fund calculations.
@Suite("AccountEntry Tests")
struct AccountEntryTests {

    // MARK: - Emergency Target Calculations

    @Suite("Emergency Target")
    struct EmergencyTarget {

        @Test("Emergency target calculated from income and multiplier",
              arguments: [
                (income: Decimal(10000), multiplier: 3.0, expected: Decimal(30000)),
                (income: Decimal(10000), multiplier: 6.0, expected: Decimal(60000)),
                (income: Decimal(5000), multiplier: 4.0, expected: Decimal(20000)),
                (income: Decimal(15000), multiplier: 3.0, expected: Decimal(45000))
              ])
        func emergencyTargetCalculation(income: Decimal, multiplier: Double, expected: Decimal) {
            let account = AccountEntry.emergency(name: "Emergency", multiplier: multiplier)
            let target = account.emergencyTarget(monthlyIncome: income)

            #expect(target == expected)
        }

        @Test("Non-emergency accounts return nil target")
        func nonEmergencyReturnsNil() {
            let accounts = [
                AccountEntry.primary(),
                AccountEntry.savings(),
                AccountEntry.personal(),
                AccountEntry.joint()
            ]

            for account in accounts {
                let target = account.emergencyTarget(monthlyIncome: 10000)
                #expect(target == nil, "Account type \(account.accountType) should not have emergency target")
            }
        }

        @Test("Emergency without multiplier returns nil target")
        func emergencyWithoutMultiplier() {
            var account = AccountEntry.emergency(name: "Emergency", multiplier: 3.0)
            account.emergencyMultiplier = nil

            let target = account.emergencyTarget(monthlyIncome: 10000)
            #expect(target == nil)
        }

        @Test("Zero income produces zero target")
        func zeroIncomeTarget() {
            let account = AccountEntry.emergency(name: "Emergency", multiplier: 3.0)
            let target = account.emergencyTarget(monthlyIncome: 0)

            #expect(target == 0)
        }
    }

    // MARK: - Emergency Progress

    @Suite("Emergency Progress")
    struct EmergencyProgress {

        @Test("Progress percentage calculated correctly",
              arguments: [
                (balance: Decimal(0), expected: 0.0),
                (balance: Decimal(15000), expected: 0.5),   // 50%
                (balance: Decimal(30000), expected: 1.0),   // 100%
                (balance: Decimal(7500), expected: 0.25)    // 25%
              ])
        func progressPercentage(balance: Decimal, expected: Double) {
            let account = AccountEntry.emergency(
                name: "Emergency",
                multiplier: 3.0,
                currentBalance: balance
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)
            // Target is 30000 (10000 * 3)

            #expect(progress != nil)
            if let progress = progress {
                #expect(abs(progress - expected) < 0.001)
            }
        }

        @Test("Progress capped at 100% when over-funded")
        func progressCappedAt100() {
            let account = AccountEntry.emergency(
                name: "Emergency",
                multiplier: 3.0,
                currentBalance: 50000 // Over the 30000 target
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)

            #expect(progress == 1.0)
        }

        @Test("Progress is nil for non-emergency accounts")
        func progressNilForNonEmergency() {
            let savings = AccountEntry.savings()
            let progress = savings.emergencyProgress(monthlyIncome: 10000)

            #expect(progress == nil)
        }

        @Test("Progress with zero target is nil")
        func progressWithZeroTarget() {
            let account = AccountEntry.emergency(name: "Emergency", multiplier: 3.0)
            let progress = account.emergencyProgress(monthlyIncome: 0)

            // Target would be 0 * 3 = 0, which causes division by zero
            #expect(progress == nil)
        }
    }

    // MARK: - Emergency Completion

    @Suite("Emergency Completion")
    struct EmergencyCompletion {

        @Test("isComplete true when balance reaches target")
        func completeWhenTargetReached() {
            let account = AccountEntry.emergency(
                name: "Emergency",
                multiplier: 3.0,
                currentBalance: 30000
            )

            let isComplete = account.isEmergencyComplete(monthlyIncome: 10000)
            #expect(isComplete == true)
        }

        @Test("isComplete true when balance exceeds target")
        func completeWhenOverFunded() {
            let account = AccountEntry.emergency(
                name: "Emergency",
                multiplier: 3.0,
                currentBalance: 35000
            )

            let isComplete = account.isEmergencyComplete(monthlyIncome: 10000)
            #expect(isComplete == true)
        }

        @Test("isComplete false when below target")
        func incompleteWhenBelowTarget() {
            let account = AccountEntry.emergency(
                name: "Emergency",
                multiplier: 3.0,
                currentBalance: 29999
            )

            let isComplete = account.isEmergencyComplete(monthlyIncome: 10000)
            #expect(isComplete == false)
        }

        @Test("isComplete false for non-emergency accounts")
        func incompleteForNonEmergency() {
            let savings = AccountEntry.savings()
            let isComplete = savings.isEmergencyComplete(monthlyIncome: 10000)

            #expect(isComplete == false)
        }
    }

    // MARK: - Factory Methods

    @Suite("Factory Methods")
    struct FactoryMethods {

        @Test("Primary factory creates correct account")
        func primaryFactory() {
            let account = AccountEntry.primary()

            #expect(account.accountType == .primary)
            #expect(account.isPrimary == true)
            #expect(account.isPrimarySavings == false)
            #expect(account.emergencyMultiplier == nil)
        }

        @Test("Primary factory with custom name")
        func primaryFactoryCustomName() {
            let account = AccountEntry.primary(name: "BT Checking")

            #expect(account.name == "BT Checking")
            #expect(account.accountType == .primary)
        }

        @Test("Emergency factory creates correct account")
        func emergencyFactory() {
            let account = AccountEntry.emergency(
                name: "My Emergency Fund",
                multiplier: 4.5,
                currentBalance: 5000
            )

            #expect(account.name == "My Emergency Fund")
            #expect(account.accountType == .emergency)
            #expect(account.emergencyMultiplier == 4.5)
            #expect(account.currentBalance == 5000)
            #expect(account.isPrimary == false)
            #expect(account.isPrimarySavings == false)
        }

        @Test("Emergency factory default multiplier is 3.0")
        func emergencyFactoryDefaultMultiplier() {
            let account = AccountEntry.emergency()

            #expect(account.emergencyMultiplier == 3.0)
        }

        @Test("Savings factory creates correct account")
        func savingsFactory() {
            let account = AccountEntry.savings()

            #expect(account.accountType == .savings)
            #expect(account.isPrimarySavings == true)
            #expect(account.isPrimary == false)
        }

        @Test("Savings factory can be non-primary savings")
        func savingsFactoryNonPrimary() {
            let account = AccountEntry.savings(name: "Extra Savings", isPrimarySavings: false)

            #expect(account.name == "Extra Savings")
            #expect(account.isPrimarySavings == false)
            #expect(account.accountType == .savings)
        }

        @Test("Personal factory creates correct account")
        func personalFactory() {
            let account = AccountEntry.personal()

            #expect(account.accountType == .personal)
            #expect(account.isPrimary == false)
            #expect(account.isPrimarySavings == false)
        }

        @Test("Joint factory creates correct account")
        func jointFactory() {
            let account = AccountEntry.joint()

            #expect(account.accountType == .joint)
            #expect(account.isPrimary == false)
        }

        @Test("Defaults returns single primary account")
        func defaultsReturnsOneAccount() {
            let defaults = AccountEntry.defaults

            #expect(defaults.count == 1)
            #expect(defaults.first?.accountType == .primary)
            #expect(defaults.first?.isPrimary == true)
        }
    }

    // MARK: - Identity

    @Suite("Identity")
    struct Identity {

        @Test("Each account has unique ID")
        func uniqueIDs() {
            let account1 = AccountEntry.primary()
            let account2 = AccountEntry.primary()
            let account3 = AccountEntry.savings()

            #expect(account1.id != account2.id)
            #expect(account2.id != account3.id)
            #expect(account1.id != account3.id)
        }

        @Test("Account ID persists across property changes")
        func idPersistsAcrossChanges() {
            var account = AccountEntry.savings()
            let originalId = account.id

            account.name = "Changed Name"
            account.currentBalance = 1000
            account.isPrimarySavings = false

            #expect(account.id == originalId)
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCases {

        @Test("Very large balance doesn't overflow")
        func largeBalanceHandling() {
            let account = AccountEntry.emergency(
                name: "Emergency",
                multiplier: 3.0,
                currentBalance: Decimal(string: "999999999999")! // ~1 trillion
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)
            #expect(progress == 1.0) // Should cap at 100%

            let isComplete = account.isEmergencyComplete(monthlyIncome: 10000)
            #expect(isComplete == true)
        }

        @Test("Decimal precision maintained in calculations")
        func decimalPrecision() {
            let account = AccountEntry.emergency(
                name: "Emergency",
                multiplier: 3.0,
                currentBalance: Decimal(string: "10000.50")!
            )

            let target = account.emergencyTarget(monthlyIncome: Decimal(string: "3333.50")!)
            // 3333.50 * 3 = 10000.50
            #expect(target == Decimal(string: "10000.50"))
        }

        @Test("Negative balance handled gracefully")
        func negativeBalance() {
            let account = AccountEntry.emergency(
                name: "Emergency",
                multiplier: 3.0,
                currentBalance: -5000
            )

            let progress = account.emergencyProgress(monthlyIncome: 10000)
            // Progress should be clamped to 0
            #expect(progress == 0.0)
        }
    }
}
