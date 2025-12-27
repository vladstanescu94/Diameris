import Foundation
import SwiftData

@Model
public final class Account {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var purpose: String?
    public var isPrimary: Bool
    public var sortOrder: Int
    public var accountTypeRaw: String

    public init(
        name: String,
        purpose: String? = nil,
        isPrimary: Bool = false,
        sortOrder: Int = 0,
        accountType: AccountType = .other
    ) {
        self.id = UUID()
        self.name = name
        self.purpose = purpose
        self.isPrimary = isPrimary
        self.sortOrder = sortOrder
        self.accountTypeRaw = accountType.rawValue
    }

    /// Convenience initializer from onboarding entry
    public convenience init(from entry: AccountEntry, sortOrder: Int) {
        self.init(
            name: entry.name,
            purpose: entry.purpose,
            isPrimary: entry.isPrimary,
            sortOrder: sortOrder,
            accountType: entry.accountType
        )
    }

    // MARK: - Computed Properties

    public var accountType: AccountType {
        get { AccountType(rawValue: accountTypeRaw) ?? .other }
        set { accountTypeRaw = newValue.rawValue }
    }
}
