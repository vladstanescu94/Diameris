import Foundation
import Testing
@testable import Onboarding
import Domain

/// Tests for SavingsAllocationEntry - validates savings percentage calculations,
/// boost multiplier logic, and validation rules.
@Suite("SavingsAllocationEntry Tests")
struct SavingsAllocationEntryTests {

    // MARK: - Basic Calculations

    @Suite("Basic Calculations")
    struct BasicCalculations {

        @Test("Calculate savings from available income",
              arguments: [
                (income: Decimal(10000), percentage: 0.25, expected: Decimal(2500)),
                (income: Decimal(8000), percentage: 0.10, expected: Decimal(800)),
                (income: Decimal(5000), percentage: 0.50, expected: Decimal(2500)),
                (income: Decimal(15000), percentage: 0.05, expected: Decimal(750))
              ])
        func calculateSavings(income: Decimal, percentage: Double, expected: Decimal) {
            let allocation = SavingsAllocationEntry(percentage: percentage)
            let savings = allocation.calculateSavings(availableIncome: income)

            #expect(savings == expected)
        }

        @Test("Zero income produces zero savings")
        func zeroIncome() {
            let allocation = SavingsAllocationEntry(percentage: 0.25)
            let savings = allocation.calculateSavings(availableIncome: 0)

            #expect(savings == 0)
        }

        @Test("Zero percentage produces zero savings")
        func zeroPercentage() {
            let allocation = SavingsAllocationEntry(percentage: 0)
            let savings = allocation.calculateSavings(availableIncome: 10000)

            #expect(savings == 0)
        }
    }

    // MARK: - Boost Mode

    @Suite("Boost Mode")
    struct BoostMode {

        @Test("Effective percentage with boost enabled")
        func effectivePercentageWithBoost() {
            let allocation = SavingsAllocationEntry(
                percentage: 0.20,
                boostEnabled: true,
                boostMultiplier: 3.0
            )

            // 20% * 3 = 60%
            #expect(abs(allocation.effectivePercentage - 0.60) < 0.0001)
        }

        @Test("Effective percentage equals base when boost disabled")
        func effectivePercentageWithoutBoost() {
            let allocation = SavingsAllocationEntry(
                percentage: 0.20,
                boostEnabled: false,
                boostMultiplier: 3.0
            )

            #expect(allocation.effectivePercentage == 0.20)
        }

        @Test("Calculate savings with boost multiplier",
              arguments: [
                (percentage: 0.10, multiplier: 3.0, expected: Decimal(3000)),  // 10% * 3 = 30%
                (percentage: 0.15, multiplier: 2.0, expected: Decimal(3000)),  // 15% * 2 = 30%
                (percentage: 0.20, multiplier: 3.0, expected: Decimal(6000)),  // 20% * 3 = 60%
                (percentage: 0.25, multiplier: 2.5, expected: Decimal(6250))   // 25% * 2.5 = 62.5%
              ])
        func boostedSavingsCalculation(percentage: Double, multiplier: Double, expected: Decimal) {
            let allocation = SavingsAllocationEntry(
                percentage: percentage,
                boostEnabled: true,
                boostMultiplier: multiplier
            )

            let savings = allocation.calculateSavings(availableIncome: 10000)
            #expect(abs(savings - expected) < 0.01)
        }

        @Test("Different boost multipliers",
              arguments: [2.0, 2.5, 3.0, 4.0])
        func differentMultipliers(multiplier: Double) {
            let allocation = SavingsAllocationEntry(
                percentage: 0.10,
                boostEnabled: true,
                boostMultiplier: multiplier
            )

            let expectedPercentage = 0.10 * multiplier
            #expect(allocation.effectivePercentage == expectedPercentage)
        }

        @Test("Boost can exceed 100%")
        func boostCanExceed100() {
            // This is allowed at the model level (UI should prevent it)
            let allocation = SavingsAllocationEntry(
                percentage: 0.50,
                boostEnabled: true,
                boostMultiplier: 3.0
            )

            // 50% * 3 = 150%
            #expect(allocation.effectivePercentage == 1.50)

            // Savings would be more than income (edge case)
            let savings = allocation.calculateSavings(availableIncome: 10000)
            #expect(savings == 15000)
        }
    }

    // MARK: - Validation

    @Suite("Validation")
    struct Validation {

        @Test("Valid percentages are recognized",
              arguments: [0.05, 0.10, 0.25, 0.40, 0.50])
        func validPercentages(percentage: Double) {
            let allocation = SavingsAllocationEntry(percentage: percentage)
            #expect(allocation.isValid == true)
        }

        @Test("Invalid percentages below minimum")
        func belowMinimum() {
            let allocation = SavingsAllocationEntry(percentage: 0.04) // 4% < 5%
            #expect(allocation.isValid == false)
        }

        @Test("Invalid percentages above maximum")
        func aboveMaximum() {
            let allocation = SavingsAllocationEntry(percentage: 0.51) // 51% > 50%
            #expect(allocation.isValid == false)
        }

        @Test("Boundary values are valid")
        func boundaryValues() {
            let minimum = SavingsAllocationEntry(percentage: SavingsAllocationEntry.minimumPercentage)
            let maximum = SavingsAllocationEntry(percentage: SavingsAllocationEntry.maximumPercentage)

            #expect(minimum.isValid == true)
            #expect(maximum.isValid == true)
        }

        @Test("Zero percentage is invalid")
        func zeroIsInvalid() {
            let allocation = SavingsAllocationEntry(percentage: 0)
            #expect(allocation.isValid == false)
        }

        @Test("Negative percentage is invalid")
        func negativeIsInvalid() {
            let allocation = SavingsAllocationEntry(percentage: -0.10)
            #expect(allocation.isValid == false)
        }
    }

    // MARK: - Display Formatting

    @Suite("Display Formatting")
    struct DisplayFormatting {

        @Test("Percentage display format",
              arguments: [
                (percentage: 0.05, expected: "5%"),
                (percentage: 0.10, expected: "10%"),
                (percentage: 0.25, expected: "25%"),
                (percentage: 0.50, expected: "50%")
              ])
        func percentageDisplayFormat(percentage: Double, expected: String) {
            let allocation = SavingsAllocationEntry(percentage: percentage)
            #expect(allocation.percentageDisplay == expected)
        }

        @Test("Effective percentage display without boost")
        func effectiveDisplayWithoutBoost() {
            let allocation = SavingsAllocationEntry(
                percentage: 0.20,
                boostEnabled: false
            )

            #expect(allocation.effectivePercentageDisplay == "20%")
        }

        @Test("Effective percentage display with boost")
        func effectiveDisplayWithBoost() {
            let allocation = SavingsAllocationEntry(
                percentage: 0.20,
                boostEnabled: true,
                boostMultiplier: 3.0
            )

            // 20% * 3 = 60%
            #expect(allocation.effectivePercentageDisplay == "60%")
        }
    }

    // MARK: - Default Values

    @Suite("Default Values")
    struct DefaultValues {

        @Test("Default percentage is 25%")
        func defaultPercentage() {
            let allocation = SavingsAllocationEntry()
            #expect(allocation.percentage == 0.25)
        }

        @Test("Default boost is disabled")
        func defaultBoostDisabled() {
            let allocation = SavingsAllocationEntry()
            #expect(allocation.boostEnabled == false)
        }

        @Test("Default boost multiplier is 3.0")
        func defaultMultiplier() {
            let allocation = SavingsAllocationEntry()
            #expect(allocation.boostMultiplier == 3.0)
        }

        @Test("Recommended percentage constant")
        func recommendedPercentage() {
            #expect(SavingsAllocationEntry.recommendedPercentage == 0.25)
        }
    }

    // MARK: - Static Properties

    @Suite("Static Properties")
    struct StaticProperties {

        @Test("Minimum percentage is 5%")
        func minimumPercentage() {
            #expect(SavingsAllocationEntry.minimumPercentage == 0.05)
        }

        @Test("Maximum percentage is 50%")
        func maximumPercentage() {
            #expect(SavingsAllocationEntry.maximumPercentage == 0.50)
        }

        @Test("Presets are within valid range")
        func presetsInRange() {
            for preset in SavingsAllocationEntry.presets {
                #expect(preset >= SavingsAllocationEntry.minimumPercentage)
                #expect(preset <= SavingsAllocationEntry.maximumPercentage)
            }
        }

        @Test("Presets are in ascending order")
        func presetsAscending() {
            let presets = SavingsAllocationEntry.presets
            for i in 0..<(presets.count - 1) {
                #expect(presets[i] < presets[i + 1])
            }
        }

        @Test("Presets include common percentages")
        func presetsIncludeCommon() {
            let presets = SavingsAllocationEntry.presets
            #expect(presets.contains(0.10)) // 10%
            #expect(presets.contains(0.20)) // 20%
            #expect(presets.contains(0.25)) // 25%
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCases {

        @Test("Very small percentage calculation")
        func verySmallPercentage() {
            let allocation = SavingsAllocationEntry(percentage: 0.05)
            let savings = allocation.calculateSavings(availableIncome: Decimal(string: "100.50")!)

            // 100.50 * 0.05 = 5.025
            #expect(savings == Decimal(string: "5.025"))
        }

        @Test("Large income with small percentage")
        func largeIncomeSmallPercentage() {
            let allocation = SavingsAllocationEntry(percentage: 0.05)
            let savings = allocation.calculateSavings(availableIncome: 1_000_000)

            #expect(savings == 50_000)
        }

        @Test("Fractional percentage")
        func fractionalPercentage() {
            // Not a preset but technically valid
            let allocation = SavingsAllocationEntry(percentage: 0.123)
            let savings = allocation.calculateSavings(availableIncome: 10000)

            #expect(savings == 1230)
        }

        @Test("Boost multiplier of 1.0 is effectively no boost")
        func boostMultiplierOne() {
            let allocation = SavingsAllocationEntry(
                percentage: 0.20,
                boostEnabled: true,
                boostMultiplier: 1.0
            )

            #expect(allocation.effectivePercentage == 0.20)
        }
    }
}
