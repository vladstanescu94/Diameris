import SwiftUI
import DesignSystem

/// Reusable header component for onboarding screens
/// Displays an icon, title, and optional subtitle with staggered entrance animations
struct OnboardingHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    var useHeroIcon: Bool = false
    var animate: Bool = true

    @State private var iconAppeared = false
    @State private var titleAppeared = false
    @State private var subtitleAppeared = false

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        useHeroIcon: Bool = false,
        animate: Bool = true
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.useHeroIcon = useHeroIcon
        self.animate = animate
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Icon with bounce animation
            Image(systemName: icon)
                .modifier(IconSizeModifier(useHero: useHeroIcon))
                .foregroundStyle(iconColor)
                .scaleEffect(iconAppeared ? 1.0 : Opacity.subtle)
                .opacity(iconAppeared ? 1.0 : 0)
                .symbolEffect(.bounce, value: iconAppeared)

            // Title with slide up animation
            Text(title)
                .font(useHeroIcon ? .largeTitle : .title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .offset(y: titleAppeared ? 0 : SlideOffset.small)
                .opacity(titleAppeared ? 1.0 : 0)

            // Subtitle with fade in animation
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .offset(y: subtitleAppeared ? 0 : SlideOffset.subtle)
                    .opacity(subtitleAppeared ? 1.0 : 0)
            }
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            guard animate else {
                iconAppeared = true
                titleAppeared = true
                subtitleAppeared = true
                return
            }
            triggerStaggeredAnimations()
        }
    }

    private func triggerStaggeredAnimations() {
        // Icon bounces in first
        withAnimation(SpringPreset.bouncy) {
            iconAppeared = true
        }

        // Title slides up
        withAnimation(SpringPreset.responsive.delay(StaggerDelay.standard)) {
            titleAppeared = true
        }

        // Subtitle fades in last
        withAnimation(SpringPreset.smooth.delay(AnimationDuration.fast)) {
            subtitleAppeared = true
        }
    }
}

/// Helper modifier for icon sizing
private struct IconSizeModifier: ViewModifier {
    let useHero: Bool

    func body(content: Content) -> some View {
        if useHero {
            content.iconHero()
        } else {
            content.iconXxl()
        }
    }
}

#Preview {
    VStack(spacing: Spacing.xxl) {
        OnboardingHeader(
            icon: "person.circle.fill",
            iconColor: DiamerisColors.accentPrimaryLight,
            title: "What should we call you?",
            subtitle: "We'll use this to personalize your experience."
        )

        Divider()

        OnboardingHeader(
            icon: "checkmark.circle.fill",
            iconColor: DiamerisColors.accentSecondaryLight,
            title: "You're all set!",
            subtitle: nil,
            useHeroIcon: true
        )
    }
    .padding()
}
