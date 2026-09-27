import SwiftUI
import DesignSystem

/// Full-height layout for short onboarding screens that still scrolls when content
/// outgrows the screen — at large Dynamic Type sizes or with the keyboard up.
struct OnboardingScrollContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    content
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
    }
}
