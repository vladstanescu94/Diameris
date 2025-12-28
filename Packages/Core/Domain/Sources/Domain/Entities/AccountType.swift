import Foundation

/// Type of bank account with behavioral meaning for transfer calculations.
///
/// Account types drive how money flows in the transfer plan:
/// - `primary`: Where salary lands, pays bills
/// - `emergency`: Fills FIRST until income multiplier target reached (3x-6x)
/// - `savings`: Fills AFTER emergency is full (or first if no emergency)
/// - `personal`: Gets remaining money after expenses and savings
/// - `joint`: For linked shared expenses
/// - `other`: No special behavior
public enum AccountType: String, CaseIterable, Identifiable, Codable, Sendable {
    case primary    // Where salary lands (renamed from checking)
    case emergency  // Fills first, has income multiplier target
    case savings    // Regular savings, fills after emergency
    case personal   // Gets remaining money
    case joint      // Shared expenses
    case other      // No special behavior

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .primary: return "Primary".localized
        case .emergency: return "Emergency".localized
        case .savings: return "Savings".localized
        case .personal: return "Personal".localized
        case .joint: return "Joint".localized
        case .other: return "Other".localized
        }
    }

    public var icon: String {
        switch self {
        case .primary: return "building.columns.fill"
        case .emergency: return "shield.fill"
        case .savings: return "banknote.fill"
        case .personal: return "person.fill"
        case .joint: return "person.2.fill"
        case .other: return "creditcard.fill"
        }
    }

    /// Short description of what this account type means.
    public var description: String {
        switch self {
        case .primary: return "Where your salary lands".localized
        case .emergency: return "Fills first until target reached".localized
        case .savings: return "Receives savings after emergency".localized
        case .personal: return "Your flexible spending money".localized
        case .joint: return "For shared expenses".localized
        case .other: return "Custom account".localized
        }
    }

    /// Whether this account type has special behavior in the transfer calculator.
    public var hasBehavior: Bool {
        switch self {
        case .primary, .emergency, .savings, .personal: return true
        case .joint, .other: return false
        }
    }

    /// Whether only one account of this type is allowed.
    public var isUnique: Bool {
        switch self {
        case .emergency: return true  // Only one emergency account allowed
        case .primary, .savings, .personal, .joint, .other: return false
        }
    }
}
