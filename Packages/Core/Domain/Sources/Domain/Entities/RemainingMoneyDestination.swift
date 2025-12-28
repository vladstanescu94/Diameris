import Foundation

/// Where remaining money after expenses and savings should go.
public enum RemainingMoneyDestination: String, CaseIterable, Identifiable, Codable, Sendable {
    case primarySavings  // Add to the primary savings account
    case personal        // Transfer to first personal account
    case primary         // Keep in primary account

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .primarySavings: return "Primary Savings".localized
        case .personal: return "Personal Account".localized
        case .primary: return "Keep in Primary".localized
        }
    }

    public var description: String {
        switch self {
        case .primarySavings: return "Add to your savings for future goals".localized
        case .personal: return "For flexible spending".localized
        case .primary: return "Leave in your main account".localized
        }
    }
}
