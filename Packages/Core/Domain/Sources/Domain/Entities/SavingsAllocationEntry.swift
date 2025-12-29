import Foundation

/// Temporary savings allocation entry used during onboarding flow.
/// Not persisted - converted to SavingsAllocation model on completion.
public struct SavingsAllocationEntry: Identifiable, Sendable {
    public let id: UUID

    /// Percentage of available income to save (0.05 - 0.50 = 5% - 50%)
    public var percentage: Double

    /// Whether savings boost mode is enabled
    public var boostEnabled: Bool

    /// Multiplier when boost is enabled (typically 2x or 3x)
    public var boostMultiplier: Double

    public init(
        id: UUID = UUID(),
        percentage: Double = 0.25,
        boostEnabled: Bool = false,
        boostMultiplier: Double = 3.0
    ) {
        self.id = id
        self.percentage = percentage
        self.boostEnabled = boostEnabled
        self.boostMultiplier = boostMultiplier
    }

    /// The effective percentage after applying boost multiplier
    public var effectivePercentage: Double {
        boostEnabled ? percentage * boostMultiplier : percentage
    }

    /// Calculate the savings amount from available income
    public func calculateSavings(availableIncome: Decimal) -> Decimal {
        availableIncome * Decimal(effectivePercentage)
    }

    /// Format percentage for display (e.g., "25%")
    public var percentageDisplay: String {
        "\(Int(percentage * 100))%"
    }

    /// Format effective percentage for display (e.g., "75%" when boosted)
    public var effectivePercentageDisplay: String {
        "\(Int(effectivePercentage * 100))%"
    }
}

// MARK: - Validation

extension SavingsAllocationEntry {
    /// Minimum allowed savings percentage
    public static let minimumPercentage: Double = 0.05  // 5%

    /// Maximum allowed savings percentage
    public static let maximumPercentage: Double = 0.50  // 50%

    /// Common percentage presets for quick selection
    public static let presets: [Double] = [0.10, 0.15, 0.20, 0.25, 0.30]

    /// Check if the current percentage is valid
    public var isValid: Bool {
        percentage >= Self.minimumPercentage && percentage <= Self.maximumPercentage
    }
}

// MARK: - Recommendations

extension SavingsAllocationEntry {
    /// Recommended percentage based on financial advice
    public static let recommendedPercentage: Double = 0.25  // 25%

    /// Description of the recommendation
    public static var recommendationText: String {
        String(localized: "Financial experts recommend saving 20-30% of your income", bundle: .module)
    }
}
