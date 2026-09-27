import Foundation

/// The user's savings settings (Persistence's `SavingsAllocation` maps to this).
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

    public var allocationMode: AllocationMode

    public var savingsInputMode: SavingsInputMode

    /// Total savings amount when savingsInputMode == .fixedAmount
    public var fixedAmount: Decimal

    // MARK: - Split Mode Fields

    public var splitEmergencyInputMode: SavingsInputMode

    /// Monthly emergency fund contribution as fixed amount (used when splitEmergencyInputMode == .fixedAmount)
    public var splitEmergencyAmount: Decimal

    /// Emergency fund contribution as percentage of available income (used when splitEmergencyInputMode == .percentage)
    public var splitEmergencyPercentage: Double

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

    /// Percentage mode: the effective percentage of available income. Fixed mode: the fixed
    /// amount, capped at available income. Always whole cents and never negative.
    public func calculateSavings(availableIncome: Decimal) -> Decimal {
        let available = max(0, availableIncome)
        switch savingsInputMode {
        case .percentage:
            return Self.share(effectivePercentage, of: available)
        case .fixedAmount:
            return min(max(0, fixedAmount), available)
        }
    }

    public func resolvedSplitEmergencyAmount(availableIncome: Decimal) -> Decimal {
        switch splitEmergencyInputMode {
        case .percentage: return Self.share(splitEmergencyPercentage, of: max(0, availableIncome))
        case .fixedAmount: return max(0, splitEmergencyAmount)
        }
    }

    public func resolvedSplitSavingsAmount(availableIncome: Decimal) -> Decimal {
        switch splitSavingsInputMode {
        case .percentage: return Self.share(splitSavingsPercentage, of: max(0, availableIncome))
        case .fixedAmount: return max(0, splitSavingsAmount)
        }
    }

    /// `percentage` (clamped to 0–100%) of `amount`, in whole cents.
    private static func share(_ percentage: Double, of amount: Decimal) -> Decimal {
        let rate = Decimal(rate: min(1, max(0, percentage)))
        return (amount * rate).roundedToCents
    }

    public func splitTotal(availableIncome: Decimal) -> Decimal {
        resolvedSplitEmergencyAmount(availableIncome: availableIncome) +
        resolvedSplitSavingsAmount(availableIncome: availableIncome)
    }

    /// Whether boost may be switched on: it must be applicable, and the boosted rate must not
    /// exceed 100% of available income (so 3× is allowed up to a 33.3% base rate).
    public var canEnableBoost: Bool {
        isBoostApplicable && Decimal(rate: percentage) * Decimal(rate: boostMultiplier) <= 1
    }

    /// A copy with boost switched off when it applies but the boosted rate would exceed 100%.
    /// Inapplicable boost (fixed amounts, split mode) is kept for when the user switches back.
    public var withSafeBoost: SavingsAllocationEntry {
        var entry = self
        if isBoostApplicable && boostEnabled && !canEnableBoost {
            entry.boostEnabled = false
        }
        return entry
    }

    /// Whether boost is applicable (only in percentage + prioritized mode)
    public var isBoostApplicable: Bool {
        savingsInputMode == .percentage && allocationMode == .prioritized
    }

    /// Format percentage for display (e.g., "25%")
    public var percentageDisplay: String {
        percentage.wholePercentText
    }

    /// Format effective percentage for display (e.g., "75%" when boosted)
    public var effectivePercentageDisplay: String {
        effectivePercentage.wholePercentText
    }
}

// MARK: - Validation

extension SavingsAllocationEntry {
    public static let minimumPercentage: Double = 0.05

    public static let maximumPercentage: Double = 0.50

    public static let presets: [Double] = [0.10, 0.15, 0.20, 0.25, 0.30]

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
    public static let recommendedPercentage: Double = 0.25

    public static var recommendationText: String {
        String(localized: "Financial experts recommend saving 20-30% of your income", bundle: .module)
    }
}
