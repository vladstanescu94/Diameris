import Foundation
import SwiftData

@Model
public final class Expense {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var amount: Decimal
    public var frequency: String
    public var icon: String
    public var isEnabled: Bool

    public init(name: String, amount: Decimal, icon: String, frequency: String = "monthly") {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.icon = icon
        self.frequency = frequency
        self.isEnabled = true
    }
}
