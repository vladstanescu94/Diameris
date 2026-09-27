import Foundation
import Synchronization

public enum AmountFormatter {
    /// Whole amount with the current locale's grouping: "14,303 RON" (English), "14.303 RON" (Romanian).
    public static func formatForDisplay(_ amount: Decimal, currency: String) -> String {
        formatForDisplay(amount, currency: currency, locale: .current)
    }

    /// Formats a Decimal for display using `locale`'s grouping separator. Halves round up
    /// (104.5 → 105), as people expect for money, rather than to even.
    public static func formatForDisplay(_ amount: Decimal, currency: String, locale: Locale) -> String {
        let formatted = displayFormatters.string(from: amount, locale: locale) ?? "0"
        return "\(formatted) \(currency)"
    }

    /// Text-field form: no grouping, up to 2 decimals, blank for non-positive amounts.
    public static func formatForEditing(_ amount: Decimal) -> String {
        formatForEditing(amount, locale: .current)
    }

    /// Formats a Decimal for editing with `locale`'s decimal separator ("1234,5" in Romanian).
    public static func formatForEditing(_ amount: Decimal, locale: Locale) -> String {
        guard amount > 0 else { return "" }
        return editingFormatters.string(from: amount, locale: locale) ?? "0"
    }

    /// `parse(_:locale:)` in the current locale.
    public static func parse(_ text: String) -> Decimal {
        parse(text, locale: .current)
    }

    /// Parses user-typed money in either convention: "1234.56", "1234,56", "1.234,56",
    /// "1,234.56", "1 234,56", "12 500 lei".
    ///
    /// - When both `,` and `.` appear, the last one is the decimal separator.
    /// - A separator that repeats ("1.234.567") is grouping.
    /// - A single separator followed by exactly three digits is grouping only if it is the
    ///   locale's grouping separator — "1.234" is 1234 in Romanian and 1.234 in English.
    ///
    /// Everything else (spaces, currency codes, symbols) is ignored. A leading `-` negates.
    /// - Returns: Parsed Decimal, or 0 if there are no digits.
    public static func parse(_ text: String, locale: Locale) -> Decimal {
        let kept = text.filter { $0.isASCII && ($0.isNumber || separators.contains($0)) }
        guard kept.contains(where: \.isNumber) else { return 0 }

        let decimalIndex = decimalSeparatorIndex(in: kept, locale: locale)
        let integerDigits = kept[..<(decimalIndex ?? kept.endIndex)].filter(\.isNumber)
        let fractionDigits = decimalIndex.map { kept[kept.index(after: $0)...].filter(\.isNumber) } ?? ""

        let normalized = fractionDigits.isEmpty ? integerDigits : "\(integerDigits).\(fractionDigits)"
        guard let value = Decimal(string: normalized, locale: posixLocale) else { return 0 }
        let isNegative = text.trimmingCharacters(in: .whitespaces).hasPrefix("-")
        return isNegative ? -value : value
    }
}

// MARK: - Formatters

private extension AmountFormatter {
    static let displayFormatters = NumberFormatterCache { formatter in
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.roundingMode = .halfUp
    }

    static let editingFormatters = NumberFormatterCache { formatter in
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ""
    }
}

/// One configured `NumberFormatter` per locale. Amounts are formatted inside view bodies, and
/// creating a formatter costs over 10× as much as formatting with one.
private final class NumberFormatterCache: Sendable {
    /// Distinct locales in one session are the user's plus a few in tests; past this the cache
    /// starts over rather than grow.
    private static let capacity = 8

    private let configure: @Sendable (NumberFormatter) -> Void
    private let formatters = Mutex<[Locale: NumberFormatter]>([:])

    init(configure: @escaping @Sendable (NumberFormatter) -> Void) {
        self.configure = configure
    }

    /// Formats under the lock: `NumberFormatter` isn't `Sendable`, so it never leaves it.
    func string(from amount: Decimal, locale: Locale) -> String? {
        formatters.withLock { formatters in
            let formatter: NumberFormatter
            if let cached = formatters[locale] {
                formatter = cached
            } else {
                if formatters.count >= Self.capacity { formatters.removeAll() }
                formatter = NumberFormatter()
                formatter.locale = locale
                configure(formatter)
                formatters[locale] = formatter
            }
            return formatter.string(from: NSDecimalNumber(decimal: amount))
        }
    }
}

// MARK: - Parsing Helpers

private extension AmountFormatter {
    static let separators: Set<Character> = [",", "."]
    static let groupingDigitCount = 3
    static let posixLocale = Locale(identifier: "en_US_POSIX")

    /// Index of the decimal separator in `text`, if it has one.
    static func decimalSeparatorIndex(in text: String, locale: Locale) -> String.Index? {
        let lastComma = text.lastIndex(of: ",")
        let lastPeriod = text.lastIndex(of: ".")

        switch (lastComma, lastPeriod) {
        case (nil, nil):
            return nil
        case let (comma?, period?):
            return max(comma, period)
        case let (only?, nil), let (nil, only?):
            let separator = text[only]
            if text.count(where: { $0 == separator }) > 1 { return nil }
            let digitsAfter = text.distance(from: only, to: text.endIndex) - 1
            let isLocaleGrouping = locale.groupingSeparator == String(separator)
            return digitsAfter == groupingDigitCount && isLocaleGrouping ? nil : only
        }
    }
}
