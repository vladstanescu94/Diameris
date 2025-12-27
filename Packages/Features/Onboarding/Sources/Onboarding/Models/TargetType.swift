import Foundation

/// Type of target for a savings goal.
public enum TargetType: String, CaseIterable, Identifiable, Codable, Sendable {
    /// Target = X * monthly income (e.g., 3x for emergency fund)
    case incomeMultiplier
    /// Target = fixed amount (e.g., 5000 for vacation)
    case fixedAmount
    /// No cap - regular savings bucket
    case unlimited

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .incomeMultiplier: return String(localized: "Based on income", bundle: .module)
        case .fixedAmount: return String(localized: "Fixed amount", bundle: .module)
        case .unlimited: return String(localized: "No limit", bundle: .module)
        }
    }

    public var description: String {
        switch self {
        case .incomeMultiplier: return String(localized: "Target is a multiple of your monthly income", bundle: .module)
        case .fixedAmount: return String(localized: "Target is a specific amount", bundle: .module)
        case .unlimited: return String(localized: "Keep saving with no upper limit", bundle: .module)
        }
    }
}
