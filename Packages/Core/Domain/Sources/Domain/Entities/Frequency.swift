import Foundation

/// Represents how often an expense occurs
public enum Frequency: String, CaseIterable, Codable, Sendable {
    case monthly
    case annual

    /// Multiplier to convert amount to monthly equivalent
    public var monthlyMultiplier: Decimal {
        switch self {
        case .monthly: return 1
        case .annual: return Decimal(1) / 12
        }
    }

    /// Multiplier to convert amount to annual equivalent
    public var annualMultiplier: Decimal {
        switch self {
        case .monthly: return 12
        case .annual: return 1
        }
    }

    /// SF Symbol icon for this frequency
    public var icon: String {
        switch self {
        case .monthly: return "calendar"
        case .annual: return "calendar.badge.clock"
        }
    }
}
