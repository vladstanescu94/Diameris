import SwiftUI

/// Corner radius constants for consistent rounded corners
public enum CornerRadius {
    /// 8pt - Small radius for chips, tags, small elements
    public static let small: CGFloat = 8

    /// 12pt - Medium radius for buttons, small cards
    public static let medium: CGFloat = 12

    /// 16pt - Large radius for cards, sheets
    public static let large: CGFloat = 16

    /// 24pt - Extra large radius for large containers
    public static let xl: CGFloat = 24
}

// MARK: - RoundedRectangle Convenience

public extension RoundedRectangle {
    /// Small corner radius (8pt)
    static let small = RoundedRectangle(cornerRadius: CornerRadius.small)

    /// Medium corner radius (12pt)
    static let medium = RoundedRectangle(cornerRadius: CornerRadius.medium)

    /// Large corner radius (16pt)
    static let large = RoundedRectangle(cornerRadius: CornerRadius.large)

    /// Extra large corner radius (24pt)
    static let xl = RoundedRectangle(cornerRadius: CornerRadius.xl)
}

// MARK: - View Extensions

public extension View {
    /// Clip to small rounded rectangle (8pt)
    func clipSmall() -> some View {
        clipShape(.rect(cornerRadius: CornerRadius.small))
    }

    /// Clip to medium rounded rectangle (12pt)
    func clipMedium() -> some View {
        clipShape(.rect(cornerRadius: CornerRadius.medium))
    }

    /// Clip to large rounded rectangle (16pt)
    func clipLarge() -> some View {
        clipShape(.rect(cornerRadius: CornerRadius.large))
    }
}
