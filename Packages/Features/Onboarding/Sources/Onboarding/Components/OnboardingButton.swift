import SwiftUI
import DesignSystem
import Utilities

/// Primary onboarding button with haptic feedback
struct OnboardingButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.mediumTap()
            action()
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: ComponentSize.buttonHeight)
        }
        .buttonStyle(.glassProminent)
        .opacity(isEnabled ? 1.0 : Opacity.dimmed)
        .disabled(!isEnabled)
        .onChange(of: isEnabled) { oldValue, newValue in
            if !oldValue && newValue {
                // Just became enabled - haptic pulse
                HapticManager.lightTap()
            }
        }
    }
}

/// Secondary onboarding button (skip, etc.)
struct OnboardingSecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button {
            HapticManager.lightTap()
            action()
        } label: {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, minHeight: ComponentSize.buttonHeight)
        }
        .buttonStyle(.glass)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingButton("Continue", isEnabled: true) {}
        OnboardingButton("Continue", isEnabled: false) {}
        OnboardingSecondaryButton("Skip for now") {}
    }
    .padding()
}
