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
        case .checking: return "Checking".localized
        case .savings: return "Savings".localized
        case .personal: return "Personal".localized
        case .joint: return "Joint".localized
        case .other: return "Other".localized
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
        case .checking: return "Where your salary lands".localized
        case .savings: return "For your savings goals".localized
        case .personal: return "Flexible spending money".localized
        case .joint: return "Shared with someone else".localized
        case .other: return "Custom account".localized
        }
    }
}
