import Foundation

public enum Frequency: String, CaseIterable, Codable, Sendable {
    case monthly
    case annual

    public static let monthsPerYear: Decimal = 12

    /// Prefer `monthlyEquivalent(of:)` for money: `1/12` is a repeating decimal, so
    /// `1200 × monthlyMultiplier` is `99.999…96` rather than `100`.
    public var monthlyMultiplier: Decimal {
        switch self {
        case .monthly: return 1
        case .annual: return 1 / Self.monthsPerYear
        }
    }

    public var annualMultiplier: Decimal {
        switch self {
        case .monthly: return Self.monthsPerYear
        case .annual: return 1
        }
    }

    /// `amount` expressed per month. Divides instead of multiplying by `monthlyMultiplier`, so
    /// annual amounts divisible by 12 stay exact (`1200` → `100`).
    public func monthlyEquivalent(of amount: Decimal) -> Decimal {
        switch self {
        case .monthly: return amount
        case .annual: return amount / Self.monthsPerYear
        }
    }

    public var icon: String {
        switch self {
        case .monthly: return "calendar"
        case .annual: return "calendar.badge.clock"
        }
    }

    public var displayName: String {
        switch self {
        case .monthly: return String(localized: "Monthly", bundle: .module)
        case .annual: return String(localized: "Annual", bundle: .module)
        }
    }
}
