import SwiftUI
import DesignSystem

/// Icon, title and optional subtitle with a staggered entrance.
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
            Image(systemName: icon)
                .modifier(IconSizeModifier(useHero: useHeroIcon))
                .foregroundStyle(iconColor)
                .entrance(iconAppeared, scale: Opacity.subtle)
                .symbolEffect(.bounce, value: iconAppeared)
                .accessibilityHidden(true)

            Text(title)
                .font(useHeroIcon ? .largeTitle : .title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .entrance(titleAppeared, y: SlideOffset.small)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(subtitleAppeared, y: SlideOffset.subtle)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
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
        withAnimation(SpringPreset.bouncy) {
            iconAppeared = true
        }

        withAnimation(SpringPreset.responsive.delay(StaggerDelay.standard)) {
            titleAppeared = true
        }

        withAnimation(SpringPreset.smooth.delay(AnimationDuration.fast)) {
            subtitleAppeared = true
        }
    }
}

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
            iconColor: DiamerisColors.accentPrimary,
            title: "What should we call you?",
            subtitle: "We'll use this to personalize your experience."
        )

        Divider()

        OnboardingHeader(
            icon: "checkmark.circle.fill",
            iconColor: DiamerisColors.accentSecondary,
            title: "You're all set!",
            subtitle: nil,
            useHeroIcon: true
        )
    }
    .padding()
}
