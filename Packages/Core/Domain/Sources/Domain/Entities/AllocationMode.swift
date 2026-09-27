import Foundation

/// How savings are distributed between emergency and savings accounts.
///
/// - `prioritized`: Emergency fund fills first from total savings pool,
///   savings account gets the remainder. Best for aggressively building
///   an emergency fund.
/// - `split`: Emergency and savings each get their own monthly amount (fixed or a percentage of
///   income after expenses). Best for steady contributions to both regardless of emergency status.
public enum AllocationMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case prioritized
    case split

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
        case .split: return String(localized: "Separate monthly amounts for emergency and savings", bundle: .module)
        }
    }
}
