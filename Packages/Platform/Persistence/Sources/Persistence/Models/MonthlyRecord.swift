import Foundation
import SwiftData

/// Snapshot of an account at the time of a monthly record.
public struct AccountSnapshot: Codable, Sendable {
    public var accountId: UUID
    public var accountName: String
    public var accountType: String
    public var balanceBefore: Decimal
    public var transferAmount: Decimal
    public var balanceAfter: Decimal

    public init(
        accountId: UUID,
        accountName: String,
        accountType: String,
        balanceBefore: Decimal,
        transferAmount: Decimal,
        balanceAfter: Decimal
    ) {
        self.accountId = accountId
        self.accountName = accountName
        self.accountType = accountType
        self.balanceBefore = balanceBefore
        self.transferAmount = transferAmount
        self.balanceAfter = balanceAfter
    }
}

/// A month's income, expenses, savings and transfers, for the planned history view.
/// Not written yet, but part of the stored schema: keep the class name and stored properties.
@Model
public final class MonthlyRecord {
    @Attribute(.unique) public var id: UUID
    /// First day of the month this record represents.
    public var month: Date
    public var incomeAmount: Decimal
    public var totalExpenses: Decimal
    public var totalSavings: Decimal
    public var remainingMoney: Decimal
    /// Whether the user confirmed they made the transfers.
    public var transfersExecuted: Bool
    public var createdAt: Date

    /// JSON-encoded `[AccountSnapshot]`.
    private var accountSnapshotsData: Data?

    public var accountSnapshots: [AccountSnapshot] {
        get {
            guard let data = accountSnapshotsData else { return [] }
            return (try? JSONDecoder().decode([AccountSnapshot].self, from: data)) ?? []
        }
        set {
            accountSnapshotsData = try? JSONEncoder().encode(newValue)
        }
    }

    public init(
        month: Date,
        incomeAmount: Decimal,
        totalExpenses: Decimal,
        totalSavings: Decimal,
        remainingMoney: Decimal,
        transfersExecuted: Bool = false,
        accountSnapshots: [AccountSnapshot] = []
    ) {
        self.id = UUID()
        self.month = month
        self.incomeAmount = incomeAmount
        self.totalExpenses = totalExpenses
        self.totalSavings = totalSavings
        self.remainingMoney = remainingMoney
        self.transfersExecuted = transfersExecuted
        self.createdAt = Date()
        self.accountSnapshotsData = try? JSONEncoder().encode(accountSnapshots)
    }
}
