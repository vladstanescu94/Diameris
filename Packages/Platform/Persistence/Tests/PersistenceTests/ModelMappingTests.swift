import Foundation
import Testing
@testable import Persistence

/// SwiftData models ↔ Domain entries. Mapping must be lossless (ids included — expenses link
/// to accounts by id), and calculations must come from Domain rather than being re-implemented.
struct ModelMappingTests {

    @Test func expenseRoundTripsThroughItsEntry() {
        let entry = ExpenseEntry(
            name: "Insurance",
            amount: 2400,
            frequency: .annual,
            icon: "shield.fill",
            categoryId: ExpenseCategory.autoTransport.id,
            linkedAccountId: UUID(),
            isEnabled: false,
            notes: "Annual payment"
        )

        #expect(Expense(from: entry).toEntry() == entry)
    }

    @Test func accountRoundTripsThroughItsEntry() {
        let entry = AccountEntry(
            name: "Emergency",
            purpose: "Rainy day",
            accountType: .emergency,
            emergencyMultiplier: 6,
            emergencyHardCap: 20000,
            currentBalance: 5000
        )

        let roundTripped = Account(from: entry, sortOrder: 2).toEntry()

        #expect(roundTripped.id == entry.id)
        #expect(roundTripped.name == entry.name)
        #expect(roundTripped.purpose == entry.purpose)
        #expect(roundTripped.accountType == entry.accountType)
        #expect(roundTripped.emergencyMultiplier == entry.emergencyMultiplier)
        #expect(roundTripped.emergencyHardCap == entry.emergencyHardCap)
        #expect(roundTripped.currentBalance == entry.currentBalance)
    }

    @Test func savingsAllocationUpdateCopiesEverySetting() {
        let allocation = SavingsAllocation()
        let entry = SavingsAllocationEntry(
            percentage: 0.3, boostEnabled: true, boostMultiplier: 2, allocationMode: .split,
            savingsInputMode: .fixedAmount, fixedAmount: 400,
            splitEmergencyInputMode: .percentage, splitEmergencyAmount: 10, splitEmergencyPercentage: 0.2,
            splitSavingsInputMode: .percentage, splitSavingsAmount: 20, splitSavingsPercentage: 0.25
        )

        allocation.update(from: entry)
        let stored = allocation.toEntry()

        #expect(stored.id == allocation.id, "update keeps the stored identity")
        #expect(stored.percentage == 0.3)
        #expect(stored.boostMultiplier == 2)
        #expect(stored.allocationMode == .split)
        #expect(stored.savingsInputMode == .fixedAmount)
        #expect(stored.fixedAmount == 400)
        #expect(stored.splitEmergencyInputMode == .percentage)
        #expect(stored.splitEmergencyPercentage == 0.2)
        #expect(stored.splitSavingsPercentage == 0.25)
    }

    @Test func customCategoryConvertsToACustomDomainCategory() {
        let category = CustomCategory(name: "Pets", icon: "pawprint", colorHex: "#FF0000", sortOrder: 50)

        let domain = category.toCategory()

        #expect(domain.id == category.id)
        #expect(domain.name == "Pets")
        #expect(domain.isDefault == false)
        #expect(domain.sortOrder == 50)
    }

    // MARK: - Delegation to Domain

    @Test func modelCalculationsMatchDomain() {
        let expense = Expense(name: "Insurance", amount: 2400, icon: "shield.fill", frequency: .annual)
        #expect(expense.monthlyAmount == expense.toEntry().monthlyAmount)

        let account = Account(name: "Emergency", accountType: .emergency, emergencyMultiplier: 6, currentBalance: 15000)
        #expect(account.emergencyTarget(monthlyIncome: 5000) == account.toEntry().emergencyTarget(monthlyIncome: 5000))
        #expect(account.emergencyProgress(monthlyIncome: 5000) == account.toEntry().emergencyProgress(monthlyIncome: 5000))

        let allocation = SavingsAllocation(percentage: 0.2, boostEnabled: true, boostMultiplier: 2)
        #expect(allocation.effectivePercentage == allocation.toEntry().effectivePercentage)
        #expect(allocation.calculateSavings(availableIncome: 1000) == allocation.toEntry().calculateSavings(availableIncome: 1000))
    }

    @Test func annualIncomeConvertsToAnExactMonthlyAmount() {
        #expect(Income(amount: 1200, frequency: .annual).monthlyAmount == 100)
    }
}
