import SwiftUI
import DesignSystem
import Utilities

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
        .tint(DiamerisColors.accentPrimaryFill)
        .disabled(!isEnabled) // The glass style dims itself; no extra opacity on glass.
        .onChange(of: isEnabled) { oldValue, newValue in
            if !oldValue && newValue {
                HapticManager.lightTap()
            }
        }
    }
}

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
    VStack(spacing: Spacing.lg) {
        OnboardingButton("Continue", isEnabled: true) {}
        OnboardingButton("Continue", isEnabled: false) {}
        OnboardingSecondaryButton("Skip for now") {}
    }
    .padding()
}
