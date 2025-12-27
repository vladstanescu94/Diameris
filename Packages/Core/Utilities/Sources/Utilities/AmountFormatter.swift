import Foundation

/// Utility for formatting monetary amounts.
public enum AmountFormatter {
    /// Formats a Decimal for display (with grouping separator, no decimals).
    /// - Parameters:
    ///   - amount: The amount to format
    ///   - currency: The currency code to append
    /// - Returns: Formatted string like "14,303 RON"
    public static func formatForDisplay(_ amount: Decimal, currency: String) -> String {
        let number = NSDecimalNumber(decimal: amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: number) ?? "0"
        return "\(formatted) \(currency)"
    }

    /// Formats a Decimal for editing (no grouping, up to 2 decimals).
    /// - Parameter amount: The amount to format
    /// - Returns: Plain number string for text field editing
    public static func formatForEditing(_ amount: Decimal) -> String {
        guard amount > 0 else { return "" }
        let number = NSDecimalNumber(decimal: amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.groupingSeparator = ""
        return formatter.string(from: number) ?? "0"
    }

    /// Parses a string into a Decimal, handling comma/period separators.
    /// - Parameter text: The text to parse
    /// - Returns: Parsed Decimal, or 0 if empty/invalid
    public static func parse(_ text: String) -> Decimal {
        let cleaned = text.replacingOccurrences(of: ",", with: ".")
        if let value = Decimal(string: cleaned) {
            return value
        }
        return 0
    }
}
