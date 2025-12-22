import Foundation

/// Temporary expense entry used during onboarding flow
/// Not persisted - converted to Expense model on completion
public struct ExpenseEntry: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var amount: Decimal
    public var icon: String

    public init(name: String, amount: Decimal, icon: String) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.icon = icon
    }
}
