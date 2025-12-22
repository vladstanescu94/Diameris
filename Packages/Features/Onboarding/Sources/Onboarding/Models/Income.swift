import Foundation
import SwiftData

@Model
public final class Income {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var amount: Decimal
    public var frequency: String
    public var isActive: Bool

    public init(name: String = "Salary", amount: Decimal, frequency: String = "monthly") {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.frequency = frequency
        self.isActive = true
    }
}
