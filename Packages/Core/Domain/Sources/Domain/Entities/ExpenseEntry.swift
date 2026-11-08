import Foundation

/// An expense as budgeting logic sees it; `amount` is per `frequency`.
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
    public var monthlyAmount: Decimal {
        frequency.monthlyEquivalent(of: amount)
    }

    public var annualAmount: Decimal {
        amount * frequency.annualMultiplier
    }

    public func displayAmount(for viewFrequency: Frequency) -> Decimal {
        switch viewFrequency {
        case .monthly:
            return monthlyAmount
        case .annual:
            return annualAmount
        }
    }
}

// MARK: - Share & Totals

extension ExpenseEntry {
    /// This expense's fraction (0...1) of a **monthly** total, e.g. for "18% of expenses" rows.
    /// Returns 0 when the total is zero or negative. The ratio is the same in annual view.
    public func share(ofTotal monthlyTotal: Decimal) -> Double {
        guard monthlyTotal > 0 else { return 0 }
        let ratio = NSDecimalNumber(decimal: monthlyAmount / monthlyTotal).doubleValue
        return min(1, max(0, ratio))
    }
}

extension Sequence where Element == ExpenseEntry {
    /// Monthly equivalent of all **enabled** expenses.
    public var totalMonthly: Decimal {
        reduce(0) { $1.isEnabled ? $0 + $1.monthlyAmount : $0 }
    }

    /// Annual equivalent of all **enabled** expenses.
    public var totalAnnual: Decimal {
        reduce(0) { $1.isEnabled ? $0 + $1.annualAmount : $0 }
    }
}

// MARK: - Validation

extension ExpenseEntry {
    /// Longest allowed expense name (03-Expenses.md › Validation Rules).
    public static let maximumNameLength = 100

    /// Highest plausible amount (03-Expenses.md › Validation Rules). Zero is allowed, for a
    /// suspended expense.
    public static let maximumAmount: Decimal = 10_000_000

    public enum ValidationError: Error, Equatable, Sendable {
        case nameMissing
        case nameTooLong
        case amountNegative
        case amountTooHigh

        public var message: String {
            switch self {
            case .nameMissing: String(localized: "Please enter an expense name", bundle: .module)
            case .nameTooLong: String(localized: "Name is too long", bundle: .module)
            case .amountNegative: String(localized: "Please enter an amount", bundle: .module)
            case .amountTooHigh: String(localized: "Amount seems too high", bundle: .module)
            }
        }
    }

    /// The first rule `name`/`amount` break, or nil when they are valid. Whitespace-only names
    /// count as missing.
    public static func validationError(name: String, amount: Decimal) -> ValidationError? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty { return .nameMissing }
        if trimmedName.count > maximumNameLength { return .nameTooLong }
        if amount < 0 { return .amountNegative }
        if amount > maximumAmount { return .amountTooHigh }
        return nil
    }

    public static func isValid(name: String, amount: Decimal) -> Bool {
        validationError(name: name, amount: amount) == nil
    }
}

// MARK: - Category Helpers

extension ExpenseEntry {
    public func category() -> Category? {
        guard let categoryId else { return nil }
        return Category.defaultCategory(for: categoryId)
    }
}
