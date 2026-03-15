import Foundation
import SwiftData
import Domain

/// SwiftData entity for persisted accounts
@Model
public final class Account {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var purpose: String?
    public var isPrimary: Bool
    public var sortOrder: Int
    public var accountTypeRaw: String

    // MARK: - Behavioral Properties

    /// For savings-type accounts: marks this as the primary savings account
    /// that receives automatic savings allocation.
    public var isPrimarySavings: Bool

    /// For emergency-type accounts: income multiplier for target calculation (3.0-6.0).
    /// Target = monthlyIncome × emergencyMultiplier
    public var emergencyMultiplier: Double?

    /// For emergency-type accounts: optional hard cap on the target amount.
    /// When set, target = min(monthlyIncome × emergencyMultiplier, emergencyHardCap)
    public var emergencyHardCap: Decimal?

    /// Current balance in this account (for progress tracking).
    public var currentBalance: Decimal

    /// Creation date for audit
    public var createdAt: Date

    public init(
        name: String,
        purpose: String? = nil,
        isPrimary: Bool = false,
        sortOrder: Int = 0,
        accountType: AccountType = .other,
        isPrimarySavings: Bool = false,
        emergencyMultiplier: Double? = nil,
        emergencyHardCap: Decimal? = nil,
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
        self.emergencyHardCap = emergencyHardCap
        self.currentBalance = currentBalance
        self.createdAt = Date()
    }

    /// Convenience initializer from Domain AccountEntry
    public convenience init(from entry: AccountEntry, sortOrder: Int) {
        self.init(
            name: entry.name,
            purpose: entry.purpose,
            isPrimary: entry.isPrimary,
            sortOrder: sortOrder,
            accountType: entry.accountType,
            isPrimarySavings: entry.isPrimarySavings,
            emergencyMultiplier: entry.emergencyMultiplier,
            emergencyHardCap: entry.emergencyHardCap,
            currentBalance: entry.currentBalance
        )
    }

    // MARK: - Computed Properties

    public var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .other }
        set { accountTypeRaw = newValue.rawValue }
    }

    /// Convert to Domain AccountEntry
    public func toEntry() -> AccountEntry {
        AccountEntry(
            id: id,
            name: name,
            purpose: purpose,
            accountType: accountType,
            isPrimary: isPrimary,
            isPrimarySavings: isPrimarySavings,
            emergencyMultiplier: emergencyMultiplier,
            emergencyHardCap: emergencyHardCap,
            currentBalance: currentBalance
        )
    }

    /// Calculates the emergency fund target based on monthly income.
    /// When a hard cap is set, returns the minimum of calculated target and hard cap.
    /// Returns nil if this is not an emergency account.
    /// - Note: Delegates to the domain entity to avoid code duplication.
    public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
        toEntry().emergencyTarget(monthlyIncome: monthlyIncome)
    }

    /// Progress percentage toward emergency target (0.0 to 1.0).
    /// Returns nil if not an emergency account or target is 0.
    /// - Note: Delegates to the domain entity to avoid code duplication.
    public func emergencyProgress(monthlyIncome: Decimal) -> Double? {
        toEntry().emergencyProgress(monthlyIncome: monthlyIncome)
    }
}
