import SwiftUI
import DesignSystem
import Utilities

/// Welcome screen - warm introduction to Diameris.
struct WelcomeScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var iconAppeared = false
    @State private var contentAppeared = false
    @State private var buttonAppeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            heroIcon
            contentSection
            valueBullets
            Spacer()
            ctaButton
        }
        .padding(Spacing.lg)
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
            .fill(DiamerisColors.accentPrimary.opacity(0.2))
            .frame(width: 140, height: 140)
            .blur(radius: 20)
            .scaleEffect(iconAppeared ? 1 : 0.5)
            .opacity(iconAppeared ? 1 : 0)
    }

    var iconContainer: some View {
        ZStack {
            Circle()
                .fill(DiamerisColors.accentPrimary.opacity(0.15))
                .frame(width: 120, height: 120)

            Image(systemName: "sparkles")
                .font(.system(size: IconSize.hero))
                .foregroundStyle(DiamerisColors.accentPrimary)
                .symbolEffect(.pulse, options: .repeating)
        }
        .scaleEffect(iconAppeared ? 1 : 0.3)
        .opacity(iconAppeared ? 1 : 0)
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
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : SlideOffset.standard)
    }

    var subtitleText: some View {
        Text("In the next few minutes, we'll build your personalized transfer plan — so payday becomes effortless.".localized)
            .font(.title3)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : SlideOffset.small)
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
                delay: 0.1
            )

            ValueBullet(
                icon: "arrow.left.arrow.right",
                text: "Know exactly where to transfer your money".localized,
                color: DiamerisColors.accentPrimary,
                appeared: contentAppeared,
                delay: 0.2
            )

            ValueBullet(
                icon: "chart.line.uptrend.xyaxis",
                text: "Watch your progress grow".localized,
                color: DiamerisColors.accentSecondary,
                appeared: contentAppeared,
                delay: 0.3
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
        .opacity(buttonAppeared ? 1 : 0)
        .offset(y: buttonAppeared ? 0 : SlideOffset.standard)
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

/// A single value proposition bullet point.
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
                .frame(width: 24)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .opacity(itemAppeared ? 1 : 0)
        .offset(x: itemAppeared ? 0 : -SlideOffset.small)
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
