import SwiftUI

/// Entrance effect for staggered onboarding content.
/// Always fades; slides and scales only when Reduce Motion is off.
private struct EntranceEffect: ViewModifier {
    let isVisible: Bool
    let offset: CGSize
    let scale: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let showsMotion = !isVisible && !reduceMotion
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(showsMotion ? scale : 1)
            .offset(showsMotion ? offset : .zero)
    }
}

extension View {
    /// Hides the view until `isVisible`, sliding by `x`/`y` and scaling from `scale` on the way in.
    func entrance(_ isVisible: Bool, x: CGFloat = 0, y: CGFloat = 0, scale: CGFloat = 1) -> some View {
        modifier(EntranceEffect(isVisible: isVisible, offset: CGSize(width: x, height: y), scale: scale))
    }
}
