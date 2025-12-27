import SwiftUI
import DesignSystem
import Utilities

struct NameScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool
    @State private var contentAppeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            header
            nameTextField
            Spacer()
            continueButton
        }
        .padding(Spacing.lg)
        .onAppear { triggerAnimations() }
    }
}

// MARK: - Subviews

private extension NameScreen {
    var header: some View {
        OnboardingHeader(
            icon: "person.circle.fill",
            iconColor: DiamerisColors.accentPrimary,
            title: "First, let's get acquainted".localized,
            subtitle: "What should we call you?".localized
        )
    }

    var nameTextField: some View {
        OnboardingTextField(
            "",
            text: $viewModel.name,
            prompt: "Your name".localized
        )
        .focused($isNameFocused)
        .submitLabel(.continue)
        .onSubmit {
            if viewModel.canAdvance {
                viewModel.advance()
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : SlideOffset.standard)
    }

    var continueButton: some View {
        OnboardingButton("Continue".localized, isEnabled: viewModel.canAdvance) {
            viewModel.advance()
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : SlideOffset.standard)
        .accessibilityHint("Continues to the next step".localized)
    }
}

// MARK: - Animations

private extension NameScreen {
    func triggerAnimations() {
        withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
            contentAppeared = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.slow) {
            HapticManager.softTap()
        }
    }
}

#Preview {
    NameScreen(viewModel: OnboardingViewModel())
}
