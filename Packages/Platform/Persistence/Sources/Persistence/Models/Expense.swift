import Foundation
import SwiftData
import Domain

@Model
public final class Expense {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var amount: Decimal
    public var frequencyRaw: String
    public var icon: String
    public var isEnabled: Bool
    /// nil means the Primary account.
    public var linkedAccountId: UUID?
    public var categoryId: UUID?
    public var notes: String?
    public var createdAt: Date
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        icon: String,
        frequency: Frequency = .monthly,
        linkedAccountId: UUID? = nil,
        categoryId: UUID? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.icon = icon
        self.frequencyRaw = frequency.rawValue
        self.isEnabled = isEnabled
        self.linkedAccountId = linkedAccountId
        self.categoryId = categoryId
        self.notes = notes
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    /// Keeps the entry's id.
    public convenience init(from entry: ExpenseEntry, sortOrder: Int = 0) {
        self.init(
            id: entry.id,
            name: entry.name,
            amount: entry.amount,
            icon: entry.icon,
            frequency: entry.frequency,
            linkedAccountId: entry.linkedAccountId,
            categoryId: entry.categoryId,
            notes: entry.notes,
            isEnabled: entry.isEnabled,
            sortOrder: sortOrder
        )
    }

    // MARK: - Computed Properties

    public var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    public func toEntry() -> ExpenseEntry {
        ExpenseEntry(
            id: id,
            name: name,
            amount: amount,
            frequency: frequency,
            icon: icon,
            categoryId: categoryId,
            linkedAccountId: linkedAccountId,
            isEnabled: isEnabled,
            notes: notes
        )
    }

    public var monthlyAmount: Decimal {
        toEntry().monthlyAmount
    }

    public var annualAmount: Decimal {
        toEntry().annualAmount
    }
}
