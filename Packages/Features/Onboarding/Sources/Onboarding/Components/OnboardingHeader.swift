import SwiftUI
import DesignSystem

/// Reusable header component for onboarding screens
/// Displays an icon, title, and optional subtitle in a centered vertical stack
struct OnboardingHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    var useHeroIcon: Bool = false

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        useHeroIcon: Bool = false
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.useHeroIcon = useHeroIcon
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .modifier(IconSizeModifier(useHero: useHeroIcon))
                .foregroundStyle(iconColor)

            Text(title)
                .font(useHeroIcon ? .largeTitle : .title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
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
