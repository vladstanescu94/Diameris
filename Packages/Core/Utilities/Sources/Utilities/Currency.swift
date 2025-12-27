import Foundation

/// Supported currencies for the app.
public enum Currency: String, CaseIterable, Identifiable, Sendable {
    case ron = "RON"
    case eur = "EUR"
    case usd = "USD"

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .ron: return "lei"
        case .eur: return "€"
        case .usd: return "$"
        }
    }

    public var displayName: String {
        switch self {
        case .ron: return "Romanian Leu (RON)"
        case .eur: return "Euro (EUR)"
        case .usd: return "US Dollar (USD)"
        }
    }

    public static func fromLocale() -> Currency {
        guard let code = Locale.current.currency?.identifier else { return .ron }
        return Currency(rawValue: code) ?? .ron
    }
}
