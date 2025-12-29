import Foundation

/// Cached DateFormatter instances for common date formatting needs.
/// DateFormatters are expensive to create, so we cache them here.
public enum DateFormatters {
    /// Formats dates as "December 2025" (full month name + year)
    public static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    /// Formats dates as "Dec 2025" (abbreviated month + year)
    public static let shortMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
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
