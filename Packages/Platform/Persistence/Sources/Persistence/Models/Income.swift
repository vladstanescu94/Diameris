import Foundation
import SwiftData
import Domain

/// SwiftData entity for persisted income sources
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

    /// Type-safe frequency access
    public var frequency: Frequency {
        get { Frequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    /// Monthly equivalent amount.
    /// Note: Uses Domain's Frequency.monthlyMultiplier directly as Income is a simple
    /// data model without complex business logic requiring a separate Domain entity.
    public var monthlyAmount: Decimal {
        amount * frequency.monthlyMultiplier
    }

    /// Annual equivalent amount.
    /// Note: Uses Domain's Frequency.annualMultiplier directly as Income is a simple
    /// data model without complex business logic requiring a separate Domain entity.
    public var annualAmount: Decimal {
        amount * frequency.annualMultiplier
    }
}
