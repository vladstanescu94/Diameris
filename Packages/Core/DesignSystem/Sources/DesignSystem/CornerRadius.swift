import SwiftUI

public enum CornerRadius {
    /// 2pt - Barely rounded tiny shapes (confetti particles)
    public static let xs: CGFloat = 2

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
    static let small = RoundedRectangle(cornerRadius: CornerRadius.small)

    static let medium = RoundedRectangle(cornerRadius: CornerRadius.medium)

    static let large = RoundedRectangle(cornerRadius: CornerRadius.large)

    static let xl = RoundedRectangle(cornerRadius: CornerRadius.xl)
}

// MARK: - View Extensions

public extension View {
    func clipSmall() -> some View {
        clipShape(.rect(cornerRadius: CornerRadius.small))
    }

    func clipMedium() -> some View {
        clipShape(.rect(cornerRadius: CornerRadius.medium))
    }

    func clipLarge() -> some View {
        clipShape(.rect(cornerRadius: CornerRadius.large))
    }
}
