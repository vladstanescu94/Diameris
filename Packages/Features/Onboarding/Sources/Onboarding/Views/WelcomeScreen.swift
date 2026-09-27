import SwiftUI
import DesignSystem
import Utilities

struct WelcomeScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var iconAppeared = false
    @State private var contentAppeared = false
    @State private var buttonAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        OnboardingScrollContainer {
            Spacer()
            heroIcon
            contentSection
            valueBullets
            Spacer()
            ctaButton
        }
        .onAppear {
            triggerAnimations()
        }
    }
}

// MARK: - Hero Icon

private extension WelcomeScreen {
    var heroIcon: some View {
        ZStack {
            glowEffect
            iconContainer
        }
        .accessibilityHidden(true)
    }

    var glowEffect: some View {
        Circle()
            .fill(DiamerisColors.accentPrimary.opacity(Opacity.light))
            .frame(width: Hero.glowSize, height: Hero.glowSize)
            .blur(radius: Hero.glowBlur)
            .entrance(iconAppeared, scale: Opacity.half)
    }

    var iconContainer: some View {
        ZStack {
            Circle()
                .fill(DiamerisColors.accentPrimary.opacity(Opacity.light))
                .frame(width: Hero.circleSize, height: Hero.circleSize)

            Image(systemName: "sparkles")
                .font(.system(size: IconSize.hero))
                .foregroundStyle(DiamerisColors.accentPrimary)
                .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
        }
        .entrance(iconAppeared, scale: Opacity.subtle)
    }

    enum Hero {
        static let circleSize: CGFloat = 120
        static let glowSize: CGFloat = 140
        static let glowBlur: CGFloat = 20
    }
}

// MARK: - Content Section

private extension WelcomeScreen {
    var contentSection: some View {
        VStack(spacing: Spacing.md) {
            titleText
            subtitleText
        }
        .padding(.horizontal, Spacing.md)
    }

    var titleText: some View {
        Text("Take control of your money".localized)
            .font(.largeTitle)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .accessibilityAddTraits(.isHeader)
            .entrance(contentAppeared, y: SlideOffset.standard)
    }

    var subtitleText: some View {
        Text("In the next few minutes, we'll build your personalized transfer plan — so payday becomes effortless.".localized)
            .font(.title3)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .entrance(contentAppeared, y: SlideOffset.small)
    }
}

// MARK: - Value Bullets

private extension WelcomeScreen {
    var valueBullets: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            ValueBullet(
                icon: "target",
                text: "Set savings goals that fill automatically".localized,
                color: DiamerisColors.accentSecondary,
                appeared: contentAppeared,
                delay: StaggerDelay.standard
            )

            ValueBullet(
                icon: "arrow.left.arrow.right",
                text: "Know exactly where to transfer your money".localized,
                color: DiamerisColors.accentPrimary,
                appeared: contentAppeared,
                delay: StaggerDelay.standard * 2
            )

            ValueBullet(
                icon: "chart.line.uptrend.xyaxis",
                text: "Watch your progress grow".localized,
                color: DiamerisColors.accentSecondary,
                appeared: contentAppeared,
                delay: StaggerDelay.standard * 3
            )
        }
        .padding(.horizontal, Spacing.lg)
        .opacity(contentAppeared ? 1 : 0)
    }
}

// MARK: - CTA Button

private extension WelcomeScreen {
    var ctaButton: some View {
        OnboardingButton("Let's Go".localized, isEnabled: true) {
            viewModel.advance()
        }
        .entrance(buttonAppeared, y: SlideOffset.standard)
    }
}

// MARK: - Animations

private extension WelcomeScreen {
    func triggerAnimations() {
        withAnimation(SpringPreset.bouncy.delay(StaggerDelay.initial)) {
            iconAppeared = true
        }

        withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial + AnimationDuration.fast)) {
            contentAppeared = true
        }

        withAnimation(SpringPreset.responsive.delay(StaggerDelay.initial + AnimationDuration.medium)) {
            buttonAppeared = true
        }

        HapticManager.softTap()
    }
}

// MARK: - Value Bullet

private struct ValueBullet: View {
    let icon: String
    let text: String
    let color: Color
    let appeared: Bool
    let delay: Double

    @State private var itemAppeared = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: IconSize.md)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .entrance(itemAppeared, x: -SlideOffset.small)
        .onChange(of: appeared) { _, newValue in
            if newValue {
                withAnimation(SpringPreset.responsive.delay(delay)) {
                    itemAppeared = true
                }
            }
        }
    }
}

#Preview {
    WelcomeScreen(viewModel: OnboardingViewModel())
}
