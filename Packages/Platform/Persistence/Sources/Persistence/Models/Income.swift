import Foundation
import SwiftData
import Domain

@Model
public final class Income {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var amount: Decimal
    public var frequencyRaw: String
    public var isActive: Bool
    public var createdAt: Date

    public init(
        name: String = "Salary",
        amount: Decimal,
        frequency: Frequency = .monthly
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.frequencyRaw = frequency.rawValue
        self.isActive = true
        self.createdAt = Date()
    }

    // MARK: - Computed Properties

    public var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    public var monthlyAmount: Decimal {
        frequency.monthlyEquivalent(of: amount)
    }

    public var annualAmount: Decimal {
        amount * frequency.annualMultiplier
    }
}
