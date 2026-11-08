import Foundation
import SwiftData
import Domain

@Model
public final class UserProfile {
    public var name: String
    public var currencyCode: String
    public var createdAt: Date
    public var remainingMoneyDestinationRaw: String

    public init(
        name: String,
        currencyCode: String,
        remainingMoneyDestination: RemainingMoneyDestination = .primarySavings
    ) {
        self.name = name
        self.currencyCode = currencyCode
        self.createdAt = Date()
        self.remainingMoneyDestinationRaw = remainingMoneyDestination.rawValue
    }

    // MARK: - Computed Properties

    public var remainingMoneyDestination: RemainingMoneyDestination {
        get { RemainingMoneyDestination(rawValue: remainingMoneyDestinationRaw) ?? .primarySavings }
        set { remainingMoneyDestinationRaw = newValue.rawValue }
    }
}
