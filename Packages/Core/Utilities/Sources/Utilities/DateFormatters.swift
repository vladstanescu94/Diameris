import Foundation

/// Cached because DateFormatters are expensive to create. Month/year use localized templates so
/// each locale gets its own field order rather than a hardcoded English pattern.
public enum DateFormatters {
    /// Formats dates as "December 2025" (full month name + year)
    public static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return formatter
    }()

    /// Formats dates as "Dec 2025" (abbreviated month + year)
    public static let shortMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMyyyy")
        return formatter
    }()

    /// Formats dates as "December 29, 2025" (full date)
    public static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    /// Formats dates as "12/29/25" (short date)
    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
