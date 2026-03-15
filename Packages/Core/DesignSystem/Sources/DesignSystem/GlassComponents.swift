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

}

