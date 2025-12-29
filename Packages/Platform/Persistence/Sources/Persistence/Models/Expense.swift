import Foundation
import SwiftData
import Domain

/// SwiftData entity for persisted expenses
@Model
public final class Expense {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var amount: Decimal
    public var frequencyRaw: String
    public var icon: String
    public var isEnabled: Bool
    /// Optional link to account - nil means Primary account (default)
    public var linkedAccountId: UUID?
    /// Optional category ID from Domain.Category
    public var categoryId: UUID?
    /// Optional subcategory ID from Domain.Subcategory
    public var subcategoryId: UUID?
    /// User notes about this expense
    public var notes: String?
    /// Creation date for sorting
    public var createdAt: Date
    /// Sort order within category
    public var sortOrder: Int

    public init(
        name: String,
        amount: Decimal,
        icon: String,
        frequency: Frequency = .monthly,
        linkedAccountId: UUID? = nil,
        categoryId: UUID? = nil,
        subcategoryId: UUID? = nil,
        notes: String? = nil,
        isEnabled: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.icon = icon
        self.frequencyRaw = frequency.rawValue
        self.isEnabled = isEnabled
        self.linkedAccountId = linkedAccountId
        self.categoryId = categoryId
        self.subcategoryId = subcategoryId
        self.notes = notes
        self.createdAt = Date()
        self.sortOrder = sortOrder
    }

    /// Convenience initializer from Domain ExpenseEntry
    public convenience init(from entry: ExpenseEntry, sortOrder: Int = 0) {
        self.init(
            name: entry.name,
            amount: entry.amount,
            icon: entry.icon,
            frequency: entry.frequency,
            linkedAccountId: entry.linkedAccountId,
            categoryId: entry.categoryId,
            subcategoryId: entry.subcategoryId,
            notes: entry.notes,
            sortOrder: sortOrder
        )
    }

    // MARK: - Computed Properties

    /// Type-safe frequency access
    public var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    /// Convert to Domain ExpenseEntry
    public func toEntry() -> ExpenseEntry {
        ExpenseEntry(
            id: id,
            name: name,
            amount: amount,
            frequency: frequency,
            icon: icon,
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            linkedAccountId: linkedAccountId,
            isEnabled: isEnabled,
            notes: notes
        )
    }

    /// Amount converted to monthly equivalent
    public var monthlyAmount: Decimal {
        amount * frequency.monthlyMultiplier
    }

    /// Amount converted to annual equivalent
    public var annualAmount: Decimal {
        amount * frequency.annualMultiplier
    }
}
