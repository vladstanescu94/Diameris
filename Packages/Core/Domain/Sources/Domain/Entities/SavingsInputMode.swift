import Foundation

/// How the total savings amount is determined in prioritized allocation mode.
///
/// - `percentage`: A percentage of available income (5-50%), the existing slider behavior.
/// - `fixedAmount`: An exact currency amount per month (e.g., "1000 RON").
public enum SavingsInputMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case percentage    // Percentage of available income (default)
    case fixedAmount   // Exact currency amount per month

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .percentage: return "Percentage".localized
        case .fixedAmount: return "Fixed Amount".localized
        }
    }
}
