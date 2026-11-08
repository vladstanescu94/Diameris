import SwiftUI

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

    /// 80pt - Large hero icons (success states, celebrations)
    public static let hero: CGFloat = 80
}

// MARK: - Dynamic Type Scaling

/// Sizes an SF Symbol from a base point size that scales with Dynamic Type, tracking `textStyle`.
struct ScaledIconFont: ViewModifier {
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat, relativeTo textStyle: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size))
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply small icon size (16pt at the default text size, scales like body text)
    func iconSm() -> some View {
        modifier(ScaledIconFont(size: IconSize.sm, relativeTo: .body))
    }

    /// Apply medium icon size (24pt at the default text size, scales like title3)
    func iconMd() -> some View {
        modifier(ScaledIconFont(size: IconSize.md, relativeTo: .title3))
    }

    /// Apply large icon size (32pt at the default text size, scales like title)
    func iconLg() -> some View {
        modifier(ScaledIconFont(size: IconSize.lg, relativeTo: .title))
    }

    /// Apply extra large icon size (48pt at the default text size, scales like largeTitle)
    func iconXl() -> some View {
        modifier(ScaledIconFont(size: IconSize.xl, relativeTo: .largeTitle))
    }

    /// Apply hero icon size (64pt). Fixed: decorative hero art would crowd out content if it
    /// grew with accessibility text sizes.
    func iconXxl() -> some View {
        font(.system(size: IconSize.xxl))
    }

    /// Apply large hero icon size (80pt). Fixed, like `iconXxl()`.
    func iconHero() -> some View {
        font(.system(size: IconSize.hero))
    }
}
