import Foundation
import SwiftData
import Domain

@Model
public final class Account {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var purpose: String?
    public var isPrimary: Bool
    public var sortOrder: Int
    public var accountTypeRaw: String

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
        name: String,
        purpose: String? = nil,
        isPrimary: Bool = false,
        sortOrder: Int = 0,
        accountType: AccountType = .other,
        isPrimarySavings: Bool = false,
        emergencyMultiplier: Double? = nil,
        currentBalance: Decimal = 0
    ) {
        self.id = UUID()
        self.name = name
        self.purpose = purpose
        self.isPrimary = isPrimary
        self.sortOrder = sortOrder
        self.accountTypeRaw = accountType.rawValue
        self.isPrimarySavings = isPrimarySavings
        self.emergencyMultiplier = emergencyMultiplier
        self.currentBalance = currentBalance
    }

    /// Convenience initializer from onboarding entry
    public convenience init(from entry: AccountEntry, sortOrder: Int) {
        self.init(
            name: entry.name,
            purpose: entry.purpose,
            isPrimary: entry.isPrimary,
            sortOrder: sortOrder,
            accountType: entry.accountType,
            isPrimarySavings: entry.isPrimarySavings,
            emergencyMultiplier: entry.emergencyMultiplier,
            currentBalance: entry.currentBalance
        )
    }

    // MARK: - Computed Properties

    public var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .other }
        set { accountTypeRaw = newValue.rawValue }
    }

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
        let progress = NSDecimalNumber(decimal: currentBalance / target).doubleValue
        return min(1.0, max(0.0, progress))
    }
}
