import Foundation
import SwiftData
import Domain

/// Settings for how much of available income goes to savings goals.
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

    public init(
        percentage: Double = 0.25,
        boostEnabled: Bool = false,
        boostMultiplier: Double = 3.0
    ) {
        self.id = UUID()
        self.percentage = percentage
        self.boostEnabled = boostEnabled
        self.boostMultiplier = boostMultiplier
        self.createdAt = Date()
    }

    /// Convenience initializer from onboarding entry
    public convenience init(from entry: SavingsAllocationEntry) {
        self.init(
            percentage: entry.percentage,
            boostEnabled: entry.boostEnabled,
            boostMultiplier: entry.boostMultiplier
        )
    }

    // MARK: - Computed Properties

    /// The effective percentage after applying boost multiplier
    public var effectivePercentage: Double {
        boostEnabled ? min(1.0, percentage * boostMultiplier) : percentage
    }

    /// Calculate the savings amount from available income
    public func calculateSavings(availableIncome: Decimal) -> Decimal {
        availableIncome * Decimal(effectivePercentage)
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
