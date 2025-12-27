import Foundation

/// Temporary account entry used during onboarding flow.
/// Not persisted - converted to Account model on completion.
public struct AccountEntry: Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var purpose: String?
    public var accountType: AccountType
    public var isPrimary: Bool

    public init(
        name: String,
        purpose: String? = nil,
        accountType: AccountType = .other,
        isPrimary: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.purpose = purpose
        self.accountType = accountType
        self.isPrimary = isPrimary
    }
}

// MARK: - Smart Default Accounts

extension AccountEntry {
    /// Primary checking account where salary lands
    public static func primaryChecking(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Main Checking".localized,
            purpose: "Where your salary lands".localized,
            accountType: .checking,
            isPrimary: true
        )
    }

    /// Savings account for general savings
    public static func savings(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Savings".localized,
            purpose: "For your savings goals".localized,
            accountType: .savings
        )
    }

    /// Personal account for flexible spending
    public static func personal(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Personal".localized,
            purpose: "Flexible spending money".localized,
            accountType: .personal
        )
    }

    /// Joint account for shared expenses
    public static func joint(name: String? = nil) -> AccountEntry {
        AccountEntry(
            name: name ?? "Joint".localized,
            purpose: "Shared expenses".localized,
            accountType: .joint
        )
    }

    /// Smart default accounts for onboarding
    public static var defaults: [AccountEntry] {
        [
            .primaryChecking(),
            .savings(),
            .personal()
        ]
    }
}
