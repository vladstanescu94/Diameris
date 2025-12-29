import Foundation

/// Temporary account entry used during onboarding flow.
/// Not persisted - converted to Account model on completion.
public struct AccountEntry: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var purpose: String?
    public var accountType: AccountType
    public var isPrimary: Bool

    // MARK: - New Behavioral Properties

    /// For savings-type accounts: marks this as the primary savings account
    /// that receives automatic savings allocation.
    public var isPrimarySavings: Bool

    /// For emergency-type accounts: income multiplier for target calculation (3.0-6.0).
    /// Target = monthlyIncome × emergencyMultiplier
    public var emergencyMultiplier: Double?

    /// Current balance in this account (for progress tracking).
    public var currentBalance: Decimal

    public init(
        id: UUID = UUID(),
        name: String,
        purpose: String? = nil,
        accountType: AccountType = .other,
        isPrimary: Bool = false,
        isPrimarySavings: Bool = false,
        emergencyMultiplier: Double? = nil,
        currentBalance: Decimal = 0
    ) {
        self.id = id
        self.name = name
        self.purpose = purpose
        self.accountType = accountType
        self.isPrimary = isPrimary
        self.isPrimarySavings = isPrimarySavings
        self.emergencyMultiplier = emergencyMultiplier
        self.currentBalance = currentBalance
    }

    // MARK: - Computed Properties

    /// Calculates the emergency fund target based on monthly income.
    /// Returns nil if this is not an emergency account.
    public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
        guard accountType == .emergency, let multiplier = emergencyMultiplier else {
            return nil
        }
        return monthlyIncome * Decimal(multiplier)
    }

    /// Progress percentage toward emergency target (0.0 to 1.0).
    /// Returns nil if not an emergency account or target is 0.
    public func emergencyProgress(monthlyIncome: Decimal) -> Double? {
        guard let target = emergencyTarget(monthlyIncome: monthlyIncome), target > 0 else {
            return nil
        }
        let progress = (currentBalance / target).doubleValue
        return min(1.0, max(0.0, progress))
    }

    /// Whether this emergency account has reached its target.
    public func isEmergencyComplete(monthlyIncome: Decimal) -> Bool {
        guard let target = emergencyTarget(monthlyIncome: monthlyIncome) else {
            return false
        }
        return currentBalance >= target
    }
}

// MARK: - Smart Default Accounts

extension AccountEntry {
    /// Primary account where salary lands
    public static func primary(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Main Account".localized,
            purpose: "Where your salary lands".localized,
            accountType: .primary,
            isPrimary: true
        )
    }

    /// Emergency fund account with income multiplier target
    public static func emergency(
        name: String? = nil,
        multiplier: Double = 3.0,
        currentBalance: Decimal = 0
    ) -> AccountEntry {
        AccountEntry(
            name: name ?? "Emergency Fund".localized,
            purpose: "Protects you from unexpected expenses".localized,
            accountType: .emergency,
            emergencyMultiplier: multiplier,
            currentBalance: currentBalance
        )
    }

    /// Savings account for regular savings (can be marked as primary savings)
    public static func savings(name: String? = nil, isPrimarySavings: Bool = true) -> AccountEntry {
        AccountEntry(
            name: name ?? "Savings".localized,
            purpose: "For building wealth over time".localized,
            accountType: .savings,
            isPrimarySavings: isPrimarySavings
        )
    }

    /// Personal account for flexible spending
    public static func personal(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Personal".localized,
            purpose: "Your flexible spending money".localized,
            accountType: .personal
        )
    }

    /// Joint account for shared expenses
    public static func joint(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Joint".localized,
            purpose: "For shared expenses".localized,
            accountType: .joint
        )
    }

    /// Smart default accounts for onboarding (minimal - just primary)
    /// User will be prompted to add emergency and savings accounts.
    public static var defaults: [AccountEntry] {
        [.primary()]
    }
}

// MARK: - Decimal Extension

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
