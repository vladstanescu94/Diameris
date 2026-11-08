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

    // MARK: - Behavioral Properties

    /// Savings accounts only: receives the automatic savings allocation.
    public var isPrimarySavings: Bool

    /// Emergency accounts only: target = monthly income × multiplier (3–6).
    public var emergencyMultiplier: Double?

    /// Emergency accounts only: caps the target at this amount.
    public var emergencyHardCap: Decimal?

    public var currentBalance: Decimal

    public var createdAt: Date

    public init(
        id: UUID = UUID(),
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
        self.id = id
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

    /// Keeps the entry's id so expenses linked to it (`linkedAccountId`) stay linked.
    public convenience init(from entry: AccountEntry, sortOrder: Int) {
        self.init(
            id: entry.id,
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

    public func emergencyTarget(monthlyIncome: Decimal) -> Decimal? {
        toEntry().emergencyTarget(monthlyIncome: monthlyIncome)
    }

    public func emergencyProgress(monthlyIncome: Decimal) -> Double? {
        toEntry().emergencyProgress(monthlyIncome: monthlyIncome)
    }
}
