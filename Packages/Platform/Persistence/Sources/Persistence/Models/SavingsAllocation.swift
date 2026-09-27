import Foundation
import SwiftData
import Domain

@Model
public final class SavingsAllocation {
    @Attribute(.unique) public var id: UUID

    /// Fraction of available income, 0.05–0.50.
    public var percentage: Double

    public var boostEnabled: Bool

    public var boostMultiplier: Double

    public var createdAt: Date

    // MARK: - Allocation Strategy Fields
    // Added after release: each needs a property-level default so existing stores migrate.

    public var allocationModeRaw: String = "prioritized"

    public var savingsInputModeRaw: String = "percentage"

    public var fixedAmount: Decimal = 0

    public var splitEmergencyInputModeRaw: String = "fixedAmount"

    public var splitEmergencyAmount: Decimal = 0

    public var splitEmergencyPercentage: Double = 0.10

    public var splitSavingsInputModeRaw: String = "fixedAmount"

    public var splitSavingsAmount: Decimal = 0

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

    /// Copies every setting; keeps `id` and `createdAt`.
    public func update(from entry: SavingsAllocationEntry) {
        percentage = entry.percentage
        boostEnabled = entry.boostEnabled
        boostMultiplier = entry.boostMultiplier
        allocationMode = entry.allocationMode
        savingsInputMode = entry.savingsInputMode
        fixedAmount = entry.fixedAmount
        splitEmergencyInputMode = entry.splitEmergencyInputMode
        splitEmergencyAmount = entry.splitEmergencyAmount
        splitEmergencyPercentage = entry.splitEmergencyPercentage
        splitSavingsInputMode = entry.splitSavingsInputMode
        splitSavingsAmount = entry.splitSavingsAmount
        splitSavingsPercentage = entry.splitSavingsPercentage
    }

    // MARK: - Type-Safe Computed Properties

    public var allocationMode: AllocationMode {
        get { AllocationMode(rawValue: allocationModeRaw) ?? .prioritized }
        set { allocationModeRaw = newValue.rawValue }
    }

    public var savingsInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: savingsInputModeRaw) ?? .percentage }
        set { savingsInputModeRaw = newValue.rawValue }
    }

    public var splitEmergencyInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: splitEmergencyInputModeRaw) ?? .fixedAmount }
        set { splitEmergencyInputModeRaw = newValue.rawValue }
    }

    public var splitSavingsInputMode: SavingsInputMode {
        get { SavingsInputMode(rawValue: splitSavingsInputModeRaw) ?? .fixedAmount }
        set { splitSavingsInputModeRaw = newValue.rawValue }
    }

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

    public var effectivePercentage: Double {
        toEntry().effectivePercentage
    }

    public func calculateSavings(availableIncome: Decimal) -> Decimal {
        toEntry().calculateSavings(availableIncome: availableIncome)
    }
}
