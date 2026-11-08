import Foundation
import Testing
@testable import Dashboard
import Domain

/// `DashboardAccount` only maps to Domain's `AccountEntry`; the emergency-fund math itself is
/// covered by `AccountEntryTests` in the Domain package. These tests guard the mapping.
struct DashboardAccountTests {

    @Test func `Maps every field to AccountEntry`() {
        let account = DashboardAccount(
            id: UUID(),
            name: "Emergency",
            accountType: .emergency,
            isPrimary: false,
            isPrimarySavings: true,
            emergencyMultiplier: 4.0,
            emergencyHardCap: 30000,
            currentBalance: 12500
        )

        let entry = account.toAccountEntry()

        #expect(entry.id == account.id)
        #expect(entry.name == "Emergency")
        #expect(entry.accountType == .emergency)
        #expect(entry.isPrimary == false)
        #expect(entry.isPrimarySavings)
        #expect(entry.emergencyMultiplier == 4.0)
        #expect(entry.emergencyHardCap == 30000)
        #expect(entry.currentBalance == 12500)
    }

    @Test(arguments: [nil, 25000] as [Decimal?])
    func `Emergency target and progress match Domain`(hardCap: Decimal?) {
        let account = DashboardAccount(
            id: UUID(),
            name: "Emergency",
            accountType: .emergency,
            isPrimary: false,
            isPrimarySavings: false,
            emergencyMultiplier: 3.0,
            emergencyHardCap: hardCap,
            currentBalance: 15000
        )
        let entry = account.toAccountEntry()

        #expect(account.emergencyTarget(monthlyIncome: 10000) == entry.emergencyTarget(monthlyIncome: 10000))
        #expect(account.emergencyProgress(monthlyIncome: 10000) == entry.emergencyProgress(monthlyIncome: 10000))
    }
}
