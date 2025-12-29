import Foundation

/// Expense entry used for budget tracking
/// Used during onboarding flow and as view model for expense display
public struct ExpenseEntry: Identifiable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    public var amount: Decimal
    public var frequency: Frequency
    public var icon: String
    public var categoryId: UUID?
    /// Optional link to account - nil means Primary account (default)
    public var linkedAccountId: UUID?
    public var isEnabled: Bool
    public var notes: String?

    public init(
        id: UUID = UUID(),
        name: String,
        amount: Decimal,
        frequency: Frequency = .monthly,
        icon: String,
        categoryId: UUID? = nil,
        linkedAccountId: UUID? = nil,
        isEnabled: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.icon = icon
        self.categoryId = categoryId
        self.linkedAccountId = linkedAccountId
        self.isEnabled = isEnabled
        self.notes = notes
    }

    /// Convenience initializer for simple expense creation (backward compatible)
    public init(name: String, amount: Decimal, icon: String, linkedAccountId: UUID? = nil) {
        self.init(
            name: name,
            amount: amount,
            frequency: .monthly,
            icon: icon,
            linkedAccountId: linkedAccountId
        )
    }
}

// MARK: - Amount Calculations

extension ExpenseEntry {
    /// Amount converted to monthly equivalent
    public var monthlyAmount: Decimal {
        amount * frequency.monthlyMultiplier
    }

    /// Amount converted to annual equivalent
    public var annualAmount: Decimal {
        amount * frequency.annualMultiplier
    }

    /// Returns the display amount based on the selected view frequency
    public func displayAmount(for viewFrequency: Frequency) -> Decimal {
        switch viewFrequency {
        case .monthly:
            return monthlyAmount
        case .annual:
            return annualAmount
        }
    }
}

// MARK: - Category Helpers

extension ExpenseEntry {
    /// Returns the category for this expense, if set
    public func category() -> Category? {
        guard let categoryId else { return nil }
        return Category.defaultCategory(for: categoryId)
    }
}
