import Foundation
import SwiftData
import Domain

@Model
public final class UserProfile {
    public var name: String
    public var currencyCode: String
    public var createdAt: Date
    /// Where remaining money after expenses and savings should go
    public var remainingMoneyDestinationRaw: String

    public init(
        name: String,
        currencyCode: String,
        remainingMoneyDestination: String = RemainingMoneyDestination.primarySavings.rawValue
    ) {
        self.name = name
        self.currencyCode = currencyCode
        self.createdAt = Date()
        self.remainingMoneyDestinationRaw = remainingMoneyDestination
    }

    /// Computed property for type-safe access
    public var remainingMoneyDestination: RemainingMoneyDestination {
        get { RemainingMoneyDestination(rawValue: remainingMoneyDestinationRaw) ?? .primarySavings }
        set { remainingMoneyDestinationRaw = newValue.rawValue }
    }
}
