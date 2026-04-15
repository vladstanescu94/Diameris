import Foundation

/// Temporary savings allocation entry used during onboarding flow.
/// Not persisted - converted to SavingsAllocation model on completion.
public struct SavingsAllocationEntry: Identifiable, Sendable {
    public let id: UUID

    // MARK: - Prioritized Mode Fields

    /// Percentage of available income to save (0.05 - 0.50 = 5% - 50%)
    public var percentage: Double

    /// Whether savings boost mode is enabled (only applies in percentage + prioritized mode)
    public var boostEnabled: Bool

    /// Multiplier when boost is enabled (typically 2x or 3x)
    public var boostMultiplier: Double

    // MARK: - Allocation Strategy

    /// How savings are distributed between emergency and savings accounts
    public var allocationMode: AllocationMode

    /// How the total savings amount is determined (percentage vs fixed amount)
    public var savingsInputMode: SavingsInputMode

    /// Total savings amount when savingsInputMode == .fixedAmount
    public var fixedAmount: Decimal

    // MARK: - Split Mode Fields

    /// Input mode for emergency allocation in split mode
    public var splitEmergencyInputMode: SavingsInputMode

    /// Monthly emergency fund contribution as fixed amount (used when splitEmergencyInputMode == .fixedAmount)
    public var splitEmergencyAmount: Decimal

    /// Emergency fund contribution as percentage of available income (used when splitEmergencyInputMode == .percentage)
    public var splitEmergencyPercentage: Double

    /// Input mode for savings allocation in split mode
    public var splitSavingsInputMode: SavingsInputMode

    /// Monthly savings contribution as fixed amount (used when splitSavingsInputMode == .fixedAmount)
    public var splitSavingsAmount: Decimal

    /// Savings contribution as percentage of available income (used when splitSavingsInputMode == .percentage)
    public var splitSavingsPercentage: Double

    public init(
        id: UUID = UUID(),
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
        self.id = id
        self.percentage = percentage
        self.boostEnabled = boostEnabled
        self.boostMultiplier = boostMultiplier
        self.allocationMode = allocationMode
        self.savingsInputMode = savingsInputMode
        self.fixedAmount = fixedAmount
        self.splitEmergencyInputMode = splitEmergencyInputMode
        self.splitEmergencyAmount = splitEmergencyAmount
        self.splitEmergencyPercentage = splitEmergencyPercentage
        self.splitSavingsInputMode = splitSavingsInputMode
        self.splitSavingsAmount = splitSavingsAmount
        self.splitSavingsPercentage = splitSavingsPercentage
    }

    // MARK: - Computed Properties

    /// The effective percentage after applying boost multiplier.
    /// Capped at 1.0 (100%) to prevent invalid savings rates.
    /// Only meaningful in percentage + prioritized mode.
    public var effectivePercentage: Double {
        guard isBoostApplicable && boostEnabled else { return percentage }
        return min(1.0, percentage * boostMultiplier)
    }

    /// Calculate the total savings amount from available income.
    /// In percentage mode: uses effective percentage of available income.
    /// In fixed amount mode: returns the fixed amount, capped at available income.
    public func calculateSavings(availableIncome: Decimal) -> Decimal {
        switch savingsInputMode {
        case .percentage:
            return availableIncome * Decimal(effectivePercentage)
        case .fixedAmount:
            return min(fixedAmount, max(0, availableIncome))
        }
    }

    /// Resolved emergency amount in split mode, accounting for input mode.
    public func resolvedSplitEmergencyAmount(availableIncome: Decimal) -> Decimal {
        switch splitEmergencyInputMode {
        case .percentage: return availableIncome * Decimal(splitEmergencyPercentage)
        case .fixedAmount: return splitEmergencyAmount
        }
    }

    /// Resolved savings amount in split mode, accounting for input mode.
    public func resolvedSplitSavingsAmount(availableIncome: Decimal) -> Decimal {
        switch splitSavingsInputMode {
        case .percentage: return availableIncome * Decimal(splitSavingsPercentage)
        case .fixedAmount: return splitSavingsAmount
        }
    }

    /// Total intended allocation in split mode, resolved against available income.
    public func splitTotal(availableIncome: Decimal) -> Decimal {
        resolvedSplitEmergencyAmount(availableIncome: availableIncome) +
        resolvedSplitSavingsAmount(availableIncome: availableIncome)
    }

    /// Whether boost is applicable (only in percentage + prioritized mode)
    public var isBoostApplicable: Bool {
        savingsInputMode == .percentage && allocationMode == .prioritized
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

    /// Check if the current configuration is valid
    public var isValid: Bool {
        switch allocationMode {
        case .prioritized:
            switch savingsInputMode {
            case .percentage:
                return percentage >= Self.minimumPercentage && percentage <= Self.maximumPercentage
            case .fixedAmount:
                return fixedAmount > 0
            }
        case .split:
            let hasEmergency = splitEmergencyInputMode == .percentage
                ? splitEmergencyPercentage > 0
                : splitEmergencyAmount > 0
            let hasSavings = splitSavingsInputMode == .percentage
                ? splitSavingsPercentage > 0
                : splitSavingsAmount > 0
            return hasEmergency || hasSavings
        }
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
