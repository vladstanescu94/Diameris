import SwiftUI

// MARK: - Usage Notes
//
// iOS 26 Liquid Glass automatically styles system controls:
// - Toolbar buttons
// - Tab bar items
// - Navigation bar elements
// - Standard buttons in sheets
//
// Only use .buttonStyle(.glass) or .glassEffect() for CUSTOM views
// outside of these system contexts to avoid double-glass effects.

// MARK: - Glass Card Modifier

/// A view modifier that applies consistent glass card styling
public struct GlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isInteractive: Bool

    public init(cornerRadius: CGFloat = CornerRadius.large, isInteractive: Bool = false) {
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
    }

    public func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .glassEffect(
                isInteractive ? .regular.interactive() : .regular,
                in: .rect(cornerRadius: cornerRadius)
            )
    }
}

// MARK: - View Extensions

public extension View {
    /// Apply glass card styling with default large corner radius (16pt)
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }

    /// Apply glass card styling with custom corner radius
    func glassCard(cornerRadius: CGFloat) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    /// Apply interactive glass card styling
    func glassCardInteractive() -> some View {
        modifier(GlassCardModifier(isInteractive: true))
    }

    /// Apply glass effect with large corner radius (16pt)
    func glassLarge() -> some View {
        glassEffect(in: .rect(cornerRadius: CornerRadius.large))
    }

    /// Apply glass effect with medium corner radius (12pt)
    func glassMedium() -> some View {
        glassEffect(in: .rect(cornerRadius: CornerRadius.medium))
    }

    /// Apply interactive glass effect with large corner radius
    func glassLargeInteractive() -> some View {
        glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.large))
    }

    /// Apply glass effect tinted with the primary accent color
    func glassPrimaryTint() -> some View {
        glassEffect(
            .regular.tint(DiamerisColors.accentPrimaryLight),
            in: .rect(cornerRadius: CornerRadius.large)
        )
    }

    /// Apply glass effect tinted with the secondary accent color
    func glassSecondaryTint() -> some View {
        glassEffect(
            .regular.tint(DiamerisColors.accentSecondaryLight),
            in: .rect(cornerRadius: CornerRadius.large)
        )
    }
}

// MARK: - Pressable Card Style

/// A pressable card with subtle scale animation
public struct PressableCardStyle: ViewModifier {
    @State private var isPressed = false

    public func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
    }
}

public extension View {
    /// Make a view pressable with subtle scale feedback
    func pressable() -> some View {
        modifier(PressableCardStyle())
    }
}
