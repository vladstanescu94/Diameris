import SwiftUI

/// Spacing constants following an 8pt grid system
public enum Spacing {
    /// 4pt - Extra extra small spacing
    public static let xxs: CGFloat = 4

    /// 8pt - Extra small spacing
    public static let xs: CGFloat = 8

    /// 12pt - Small spacing
    public static let sm: CGFloat = 12

    /// 16pt - Medium spacing (default)
    public static let md: CGFloat = 16

    /// 24pt - Large spacing
    public static let lg: CGFloat = 24

    /// 32pt - Extra large spacing
    public static let xl: CGFloat = 32

    /// 48pt - Extra extra large spacing
    public static let xxl: CGFloat = 48
}

// MARK: - View Extensions for Padding

public extension View {
    /// Apply small padding (12pt)
    func paddingSm() -> some View {
        padding(Spacing.sm)
    }

    /// Apply medium padding (16pt)
    func paddingMd() -> some View {
        padding(Spacing.md)
    }

    /// Apply large padding (24pt)
    func paddingLg() -> some View {
        padding(Spacing.lg)
    }
}
