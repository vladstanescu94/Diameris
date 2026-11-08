import Foundation

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

    /// Currency name in the user's language plus its code, e.g. "Romanian Leu (RON)" /
    /// "leu românesc (RON)".
    public var displayName: String {
        displayName(locale: .current)
    }

    public func displayName(locale: Locale) -> String {
        let name = locale.localizedString(forCurrencyCode: rawValue) ?? rawValue
        return "\(name) (\(rawValue))"
    }

    public static func fromLocale() -> Currency {
        fromLocale(.current)
    }

    /// The locale's currency if supported, otherwise RON.
    public static func fromLocale(_ locale: Locale) -> Currency {
        guard let code = locale.currency?.identifier else { return .ron }
        return Currency(rawValue: code) ?? .ron
    }
}
