import Foundation
import SwiftData
import Domain

/// SwiftData entity for savings allocation settings
@Model
public final class SavingsAllocation {
    @Attribute(.unique) public var id: UUID

    /// Percentage of available income to save (0.05 - 0.50 = 5% - 50%)
    public var percentage: Double

    /// Whether savings boost mode is enabled
    public var boostEnabled: Bool

    /// Multiplier when boost is enabled (typically 2x or 3x)
    public var boostMultiplier: Double

    /// Date the allocation settings were created
    public var createdAt: Date

    // MARK: - Allocation Strategy Fields

    /// How savings are distributed: "prioritized" or "split"
    public var allocationModeRaw: String = "prioritized"

    /// How total savings is determined: "percentage" or "fixedAmount"
    public var savingsInputModeRaw: String = "percentage"

    /// Total savings amount when savingsInputMode == .fixedAmount
    public var fixedAmount: Decimal = 0

    /// Input mode for emergency in split mode: "percentage" or "fixedAmount"
    public var splitEmergencyInputModeRaw: String = "fixedAmount"

    /// Monthly emergency fund contribution as fixed amount
    public var splitEmergencyAmount: Decimal = 0

    /// Emergency fund contribution as percentage of available income
    public var splitEmergencyPercentage: Double = 0.10

    /// Input mode for savings in split mode: "percentage" or "fixedAmount"
    public var splitSavingsInputModeRaw: String = "fixedAmount"

    /// Monthly savings contribution as fixed amount
    public var splitSavingsAmount: Decimal = 0

    /// Savings contribution as percentage of available income
    public var splitSavingsPercentage: Double = 0.15

    public init(
        percentage: Double = 0.25,
        boostEnabled: Bool = false,
        boostMultiplier: Double = 3.0,
        allocationMode: AllocationMode = .prioritized,
        savingsInputMode: SavingsInputMode = .percentage,
        fixedAmount: Decimal = 0,
        splitEmergencyInputMode: SavingsInputMode = .fixedAmount,
        splitEmergencyAmount: Decimal = 0,
        splitEmergencyPercentage: Double = 0.10,
        splitSavingsInputMode: SavingsInputMode = .fixedAmount,
        splitSavingsAmount: Decimal = 0,
        splitSavingsPercentage: Double = 0.15
    ) {
        self.id = UUID()
        self.percentage = percentage
        self.boostEnabled = boostEnabled
        self.boostMultiplier = boostMultiplier
        self.createdAt = .now
        self.allocationModeRaw = allocationMode.rawValue
        self.savingsInputModeRaw = savingsInputMode.rawValue
        self.fixedAmount = fixedAmount
        self.splitEmergencyInputModeRaw = splitEmergencyInputMode.rawValue
        self.splitEmergencyAmount = splitEmergencyAmount
        self.splitEmergencyPercentage = splitEmergencyPercentage
        self.splitSavingsInputModeRaw = splitSavingsInputMode.rawValue
        self.splitSavingsAmount = splitSavingsAmount
        self.splitSavingsPercentage = splitSavingsPercentage
    }

    /// Convenience initializer from Domain SavingsAllocationEntry
    public convenience init(from entry: SavingsAllocationEntry) {
        self.init(
            percentage: entry.percentage,
            boostEnabled: entry.boostEnabled,
            boostMultiplier: entry.boostMultiplier,
            allocationMode: entry.allocationMode,
            savingsInputMode: entry.savingsInputMode,
            fixedAmount: entry.fixedAmount,
            splitEmergencyInputMode: entry.splitEmergencyInputMode,
            splitEmergencyAmount: entry.splitEmergencyAmount,
            splitEmergencyPercentage: entry.splitEmergencyPercentage,
            splitSavingsInputMode: entry.splitSavingsInputMode,
            splitSavingsAmount: entry.splitSavingsAmount,
            splitSavingsPercentage: entry.splitSavingsPercentage
        )
    }

    // MARK: - Type-Safe Computed Properties

    /// Type-safe access to allocation mode
    public var allocationMode: AllocationMode {
        get { AllocationMode(rawValue: allocationModeRaw) ?? .prioritized }
        set { allocationModeRaw = newValue.rawValue }
    }

    /// Type-safe access to savings input mode
    public var savingsInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: savingsInputModeRaw) ?? .percentage }
        set { savingsInputModeRaw = newValue.rawValue }
    }

    /// Type-safe access to split emergency input mode
    public var splitEmergencyInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: splitEmergencyInputModeRaw) ?? .fixedAmount }
        set { splitEmergencyInputModeRaw = newValue.rawValue }
    }

    /// Type-safe access to split savings input mode
    public var splitSavingsInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: splitSavingsInputModeRaw) ?? .fixedAmount }
        set { splitSavingsInputModeRaw = newValue.rawValue }
    }

    /// Convert to Domain SavingsAllocationEntry
    public func toEntry() -> SavingsAllocationEntry {
        SavingsAllocationEntry(
            id: id,
            percentage: percentage,
            boostEnabled: boostEnabled,
            boostMultiplier: boostMultiplier,
            allocationMode: allocationMode,
            savingsInputMode: savingsInputMode,
            fixedAmount: fixedAmount,
            splitEmergencyInputMode: splitEmergencyInputMode,
            splitEmergencyAmount: splitEmergencyAmount,
            splitEmergencyPercentage: splitEmergencyPercentage,
            splitSavingsInputMode: splitSavingsInputMode,
            splitSavingsAmount: splitSavingsAmount,
            splitSavingsPercentage: splitSavingsPercentage
        )
    }

    /// The effective percentage after applying boost multiplier.
    /// Delegates to Domain's SavingsAllocationEntry for the actual calculation.
    public var effectivePercentage: Double {
        toEntry().effectivePercentage
    }

    /// Calculate the savings amount from available income.
    /// Delegates to Domain's SavingsAllocationEntry for the actual calculation.
    public func calculateSavings(availableIncome: Decimal) -> Decimal {
        toEntry().calculateSavings(availableIncome: availableIncome)
    }

    /// Format percentage for display (e.g., "25%")
    public var percentageDisplay: String {
        "\(Int(percentage * 100))%"
    }

    /// Format effective percentage for display
    public var effectivePercentageDisplay: String {
        "\(Int(effectivePercentage * 100))%"
    }
}
