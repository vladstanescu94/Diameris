import Foundation
import Testing
@testable import Domain

struct SavingsAllocationEntryTests {

    @Test(arguments: [
        (0.25, false, Decimal(2125)),
        (0.10, true, Decimal(2550)),         // 3× boost
        (0.40, true, Decimal(8500)),         // 120% boosted, capped at everything available
        (0.07, false, Decimal(595)),         // Decimal(0.07) alone is 0.0700000000000000102
        (0.0033, false, Decimal(string: "28.05")!)
    ])
    func `Percentage savings are whole cents of available income`(
        percentage: Double,
        boost: Bool,
        expected: Decimal
    ) {
        let allocation = SavingsAllocationEntry(percentage: percentage, boostEnabled: boost, boostMultiplier: 3)
        #expect(allocation.calculateSavings(availableIncome: 8500) == expected)
    }

    @Test(arguments: [Decimal(-100), 0])
    func `No available income means no savings`(availableIncome: Decimal) {
        #expect(SavingsAllocationEntry(percentage: 0.25).calculateSavings(availableIncome: availableIncome) == 0)
        #expect(
            SavingsAllocationEntry(savingsInputMode: .fixedAmount, fixedAmount: 500)
                .calculateSavings(availableIncome: availableIncome) == 0
        )
    }

    @Test(arguments: [
        (0.25, 3.0, SavingsInputMode.percentage, AllocationMode.prioritized, true),
        (0.33, 3.0, .percentage, .prioritized, true),
        (0.34, 3.0, .percentage, .prioritized, false),    // 102% of available income
        (0.5, 2.0, .percentage, .prioritized, true),
        (0.2, 3.0, .fixedAmount, .prioritized, false),
        (0.2, 3.0, .percentage, .split, false)
    ])
    func `Boost can only be enabled when the boosted rate fits in available income`(
        percentage: Double,
        multiplier: Double,
        inputMode: SavingsInputMode,
        allocationMode: AllocationMode,
        expected: Bool
    ) {
        let allocation = SavingsAllocationEntry(
            percentage: percentage,
            boostMultiplier: multiplier,
            allocationMode: allocationMode,
            savingsInputMode: inputMode
        )
        #expect(allocation.canEnableBoost == expected)
    }

    @Test func `Boost only applies to percentage savings in prioritized mode`() {
        let fixed = SavingsAllocationEntry(percentage: 0.2, boostEnabled: true, savingsInputMode: .fixedAmount)
        let split = SavingsAllocationEntry(percentage: 0.2, boostEnabled: true, allocationMode: .split)

        #expect(fixed.effectivePercentage == 0.2)
        #expect(split.effectivePercentage == 0.2)
    }

    @Test func `Split percentages resolve to cents and fixed amounts are never negative`() {
        let allocation = SavingsAllocationEntry(
            allocationMode: .split,
            splitEmergencyInputMode: .percentage,
            splitEmergencyPercentage: 0.07,
            splitSavingsInputMode: .fixedAmount,
            splitSavingsAmount: -200
        )

        #expect(allocation.resolvedSplitEmergencyAmount(availableIncome: 4321) == Decimal(string: "302.47"))
        #expect(allocation.resolvedSplitSavingsAmount(availableIncome: 4321) == 0)
        #expect(allocation.splitTotal(availableIncome: 4321) == Decimal(string: "302.47"))
    }

    @Test(arguments: [
        (SavingsAllocationEntry(percentage: 0.05), true),
        (SavingsAllocationEntry(percentage: 0.50), true),
        (SavingsAllocationEntry(percentage: 0.04), false),
        (SavingsAllocationEntry(percentage: 0.51), false),
        (SavingsAllocationEntry(savingsInputMode: .fixedAmount, fixedAmount: 0), false),
        (SavingsAllocationEntry(savingsInputMode: .fixedAmount, fixedAmount: 1), true),
        (Fixture.split(emergency: 0, savings: 0), false),
        (Fixture.split(emergency: 0, savings: 300), true)
    ])
    func `Validation per mode`(allocation: SavingsAllocationEntry, isValid: Bool) {
        #expect(allocation.isValid == isValid)
    }

    @Test(arguments: zip([0.29, 0.57, 0.1 * 3], ["29%", "57%", "30%"]))
    func `Percentage display rounds instead of truncating Double noise`(percentage: Double, display: String) {
        #expect(SavingsAllocationEntry(percentage: percentage).percentageDisplay == display)
    }
}
