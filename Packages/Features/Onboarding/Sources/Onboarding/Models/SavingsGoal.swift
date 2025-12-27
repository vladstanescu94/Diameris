import Foundation
import SwiftData

/// A savings goal with priority-based allocation.
/// Goals are filled in priority order - when one completes, money flows to the next.
@Model
public final class SavingsGoal {
    @Attribute(.unique) public var id: UUID

    /// Display name of the goal (e.g., "Emergency Fund", "Vacation")
    public var name: String

    /// SF Symbol icon for the goal
    public var icon: String

    /// Type of target - multiplier of income, fixed amount, or unlimited
    public var targetTypeRaw: String

    /// Target value - multiplier (e.g., 3.0) or fixed amount (e.g., 5000)
    /// Nil for unlimited targets
    public var targetValue: Decimal?

    /// Current balance saved toward this goal
    public var currentBalance: Decimal

    /// Priority order (1 = highest, fills first)
    public var priority: Int

    /// Optional link to a specific account
    public var linkedAccountId: UUID?

    /// Whether the goal is actively receiving allocations
    public var isActive: Bool

    /// Date the goal was created
    public var createdAt: Date

    public init(
        name: String,
        icon: String,
        targetType: TargetType,
        targetValue: Decimal? = nil,
        currentBalance: Decimal = 0,
        priority: Int,
        linkedAccountId: UUID? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.targetTypeRaw = targetType.rawValue
        self.targetValue = targetValue
        self.currentBalance = currentBalance
        self.priority = priority
        self.linkedAccountId = linkedAccountId
        self.isActive = isActive
        self.createdAt = Date()
    }

    /// Convenience initializer from onboarding entry
    public convenience init(from entry: SavingsGoalEntry) {
        self.init(
            name: entry.name,
            icon: entry.icon,
            targetType: entry.targetType,
            targetValue: entry.targetValue,
            currentBalance: entry.currentBalance,
            priority: entry.priority,
            isActive: entry.isActive
        )
    }

    // MARK: - Computed Properties

    public var targetType: TargetType {
        get { TargetType(rawValue: targetTypeRaw) ?? .unlimited }
        set { targetTypeRaw = newValue.rawValue }
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
            return nil
        }
    }

    /// Calculate progress percentage (0.0 - 1.0) based on monthly income.
    public func progressPercentage(monthlyIncome: Decimal) -> Double? {
        guard let target = calculateTarget(monthlyIncome: monthlyIncome), target > 0 else {
            return nil
        }
        return min(1.0, Double(truncating: (currentBalance / target) as NSNumber))
    }

    /// Calculate remaining amount to reach target.
    public func remainingAmount(monthlyIncome: Decimal) -> Decimal? {
        guard let target = calculateTarget(monthlyIncome: monthlyIncome) else {
            return nil
        }
        return max(0, target - currentBalance)
    }

    /// Check if goal is complete.
    public func isComplete(monthlyIncome: Decimal) -> Bool {
        guard let target = calculateTarget(monthlyIncome: monthlyIncome) else {
            return false  // Unlimited goals are never "complete"
        }
        return currentBalance >= target
    }
}
