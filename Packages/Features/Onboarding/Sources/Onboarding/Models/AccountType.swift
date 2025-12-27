import Foundation

/// Type of bank account for categorization and smart suggestions.
public enum AccountType: String, CaseIterable, Identifiable, Codable, Sendable {
    case checking   // Primary account where salary lands
    case savings    // General savings account
    case personal   // Flexible spending / fun money
    case joint      // Shared expenses (optional)
    case other      // Custom account type

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .checking: return String(localized: "Checking")
        case .savings: return String(localized: "Savings")
        case .personal: return String(localized: "Personal")
        case .joint: return String(localized: "Joint")
        case .other: return String(localized: "Other")
        }
    }

    public var icon: String {
        switch self {
        case .checking: return "building.columns.fill"
        case .savings: return "banknote.fill"
        case .personal: return "person.fill"
        case .joint: return "person.2.fill"
        case .other: return "creditcard.fill"
        }
    }

    public var description: String {
        switch self {
        case .checking: return String(localized: "Where your salary lands")
        case .savings: return String(localized: "For your savings goals")
        case .personal: return String(localized: "Flexible spending money")
        case .joint: return String(localized: "Shared with someone else")
        case .other: return String(localized: "Custom account")
        }
    }
}
