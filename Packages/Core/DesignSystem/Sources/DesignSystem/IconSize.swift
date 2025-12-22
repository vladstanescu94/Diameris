import SwiftUI

/// Icon size constants for consistent SF Symbol sizing
public enum IconSize {
    /// 16pt - Small icons (inline with text)
    public static let sm: CGFloat = 16

    /// 24pt - Medium icons (list rows, buttons)
    public static let md: CGFloat = 24

    /// 32pt - Large icons (section headers)
    public static let lg: CGFloat = 32

    /// 48pt - Extra large icons (empty states, cards)
    public static let xl: CGFloat = 48

    /// 64pt - Hero icons (splash screens, onboarding)
    public static let xxl: CGFloat = 64
}

// MARK: - View Extensions

public extension View {
    /// Apply small icon size (16pt)
    func iconSm() -> some View {
        font(.system(size: IconSize.sm))
    }

    /// Apply medium icon size (24pt)
    func iconMd() -> some View {
        font(.system(size: IconSize.md))
    }

    /// Apply large icon size (32pt)
    func iconLg() -> some View {
        font(.system(size: IconSize.lg))
    }

    /// Apply extra large icon size (48pt)
    func iconXl() -> some View {
        font(.system(size: IconSize.xl))
    }

    /// Apply hero icon size (64pt)
    func iconXxl() -> some View {
        font(.system(size: IconSize.xxl))
    }
}
