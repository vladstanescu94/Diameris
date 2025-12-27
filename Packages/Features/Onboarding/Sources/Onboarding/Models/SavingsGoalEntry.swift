import Foundation

/// Temporary savings goal entry used during onboarding flow.
/// Not persisted - converted to SavingsGoal model on completion.
public struct SavingsGoalEntry: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var targetType: TargetType
    public var targetValue: Decimal?      // Multiplier (e.g., 3) or fixed amount (e.g., 5000)
    public var currentBalance: Decimal    // How much already saved
    public var priority: Int              // 1 = highest priority, fills first
    public var isActive: Bool

    public init(
        name: String,
        icon: String,
        targetType: TargetType,
        targetValue: Decimal? = nil,
        currentBalance: Decimal = 0,
        priority: Int,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.targetType = targetType
        self.targetValue = targetValue
        self.currentBalance = currentBalance
        self.priority = priority
        self.isActive = isActive
    }

    /// Calculate the target amount based on monthly income.
    public func calculateTarget(monthlyIncome: Decimal) -> Decimal? {
        switch targetType {
        case .incomeMultiplier:
            guard let multiplier = targetValue else { return nil }
            return monthlyIncome * multiplier
        case .fixedAmount:
            return targetValue
        case .unlimited:
            return nil  // No target - always accepting more
        }
    }

    /// Calculate progress percentage (0.0 - 1.0) based on monthly income.
    /// Returns nil if target is unlimited.
    public func progressPercentage(monthlyIncome: Decimal) -> Double? {
        guard let target = calculateTarget(monthlyIncome: monthlyIncome), target > 0 else {
            return nil
        }
        return min(1.0, Double(truncating: (currentBalance / target) as NSNumber))
    }

    /// Calculate remaining amount to reach target.
    /// Returns nil if target is unlimited.
    public func remainingAmount(monthlyIncome: Decimal) -> Decimal? {
        guard let target = calculateTarget(monthlyIncome: monthlyIncome) else {
            return nil
        }
        return max(0, target - currentBalance)
    }

    /// Check if goal is complete based on current balance and target.
    public func isComplete(monthlyIncome: Decimal) -> Bool {
        guard let target = calculateTarget(monthlyIncome: monthlyIncome) else {
            return false  // Unlimited goals are never "complete"
        }
        return currentBalance >= target
    }
}

// MARK: - Default Goals

extension SavingsGoalEntry {
    /// Default emergency fund goal (3x monthly income, priority 1)
    public static func emergencyFund() -> SavingsGoalEntry {
        SavingsGoalEntry(
            name: String(localized: "Emergency Fund"),
            icon: "shield.checkered",
            targetType: .incomeMultiplier,
            targetValue: 3,
            priority: 1
        )
    }

    /// Default regular savings goal (unlimited, priority 2)
    public static func regularSavings() -> SavingsGoalEntry {
        SavingsGoalEntry(
            name: String(localized: "Savings"),
            icon: "banknote.fill",
            targetType: .unlimited,
            priority: 2
        )
    }

    /// Default goals for onboarding
    public static var defaults: [SavingsGoalEntry] {
        [emergencyFund(), regularSavings()]
    }
}
