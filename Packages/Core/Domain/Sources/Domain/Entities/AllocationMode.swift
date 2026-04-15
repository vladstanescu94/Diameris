import Foundation

/// How savings are distributed between emergency and savings accounts.
///
/// - `prioritized`: Emergency fund fills first from total savings pool,
///   savings account gets the remainder. Best for aggressively building
///   an emergency fund.
/// - `split`: Emergency and savings each get independent, fixed monthly
///   amounts. Best for steady contributions to both accounts regardless
///   of emergency fund status.
public enum AllocationMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case prioritized  // Emergency fills first, savings gets remainder (default)
    case split        // Independent fixed amounts for emergency and savings

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .prioritized: return "Priority".localized
        case .split: return "Split".localized
        }
    }

    public var description: String {
        switch self {
        case .prioritized: return "Emergency fund fills first, then savings".localized
        case .split: return "Fixed amounts to each account every month".localized
        }
    }
}
