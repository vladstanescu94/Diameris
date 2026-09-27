import Foundation
import Testing
@testable import Domain

struct AccountEntryTests {

    @Test(arguments: [
        (Decimal(8500), 3.0, Decimal?.none, Decimal(25_500)),
        (Decimal(8500), 4.5, nil, Decimal(38_250)),
        (Decimal(string: "8345.67")!, 4.5, nil, Decimal(string: "37555.52")!),  // not 37 555.515
        (Decimal(8500), 6.0, Decimal(40_000), Decimal(40_000)),   // cap below calculated
        (Decimal(8500), 3.0, Decimal(90_000), Decimal(25_500)),   // cap above calculated is inert
        (Decimal(0), 3.0, nil, Decimal(0))
    ])
    func `Emergency target is income × multiplier, limited by the hard cap`(
        income: Decimal,
        multiplier: Double,
        hardCap: Decimal?,
        expected: Decimal
    ) {
        let account = AccountEntry.emergency(multiplier: multiplier, hardCap: hardCap)
        #expect(account.emergencyTarget(monthlyIncome: income) == expected)
    }

    @Test func `Only emergency accounts with a multiplier have a target`() {
        let savings = AccountEntry(name: "Savings", accountType: .savings, emergencyMultiplier: 3)
        let noMultiplier = AccountEntry(name: "Emergency", accountType: .emergency)

        #expect(savings.emergencyTarget(monthlyIncome: 8500) == nil)
        #expect(noMultiplier.emergencyTarget(monthlyIncome: 8500) == nil)
        #expect(noMultiplier.isEmergencyComplete(monthlyIncome: 8500) == false)
    }

    @Test(arguments: zip([Decimal(0), 12_750, 25_500, 40_000, -500], [0.0, 0.5, 1.0, 1.0, 0.0]))
    func `Progress is clamped to 0–100% of the target`(balance: Decimal, expected: Double) {
        let account = AccountEntry.emergency(multiplier: 3, currentBalance: balance)
        #expect(account.emergencyProgress(monthlyIncome: 8500) == expected)
    }

    @Test func `Hard cap drives progress and completion`() {
        let account = AccountEntry.emergency(multiplier: 6, hardCap: 20_000, currentBalance: 20_000)

        #expect(account.emergencyTarget(monthlyIncome: 8500) == 20_000)
        #expect(account.uncappedEmergencyTarget(monthlyIncome: 8500) == 51_000)

        #expect(account.emergencyProgress(monthlyIncome: 8500) == 1)
        #expect(account.isEmergencyComplete(monthlyIncome: 8500))
    }

    @Test func `Zero target has no meaningful progress`() {
        #expect(AccountEntry.emergency(multiplier: 3).emergencyProgress(monthlyIncome: 0) == nil)
    }
}

struct AccountRulesTests {
    let primary = AccountEntry.primary()
    let emergency = AccountEntry.emergency(multiplier: 3)
    let savings = AccountEntry.savings(isPrimarySavings: false)
    let joint = AccountEntry.joint()

    @Test func `Primary keeps its role; no one else can take it; emergency stays unique`() {
        let accounts = [primary, emergency, savings, joint]

        #expect(accounts.canAssign(.primary, toAccount: primary.id))
        #expect(!accounts.canAssign(.savings, toAccount: primary.id))
        #expect(!accounts.canAssign(.primary, toAccount: joint.id))
        #expect(!accounts.canAssign(.emergency, toAccount: savings.id))
        #expect(!accounts.canAssign(.emergency, toAccount: nil))
        #expect(accounts.canAssign(.emergency, toAccount: emergency.id))
        #expect(accounts.canAssign(.savings, toAccount: joint.id))
    }

    @Test(arguments: [
        ([RemainingMoneyDestination.primarySavings, .personal, .primary], [AccountType.savings, .personal]),
        ([.primary, .primary, .primary], []),
    ])
    func `Destinations without an account fall back to primary`(
        expected: [RemainingMoneyDestination],
        extraTypes: [AccountType]
    ) {
        let accounts = [primary] + extraTypes.map { AccountEntry(name: "\($0)", accountType: $0) }
        let requested: [RemainingMoneyDestination] = [.primarySavings, .personal, .primary]

        #expect(requested.map(accounts.resolvedRemainingDestination) == expected)
    }

    @Test func `Unsafe boost is switched off only when it applies`() {
        #expect(!Fixture.prioritized(0.5, boost: true).withSafeBoost.boostEnabled)
        #expect(Fixture.prioritized(0.3, boost: true).withSafeBoost.boostEnabled)

        var split = Fixture.split(emergency: 100, savings: 100)
        split.boostEnabled = true
        split.percentage = 0.5
        #expect(split.withSafeBoost.boostEnabled)
    }
}
