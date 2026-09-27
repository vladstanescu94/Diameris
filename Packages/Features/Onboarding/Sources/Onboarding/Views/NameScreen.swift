import SwiftUI
import DesignSystem
import Utilities

struct NameScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool
    @State private var contentAppeared = false

    var body: some View {
        OnboardingScrollContainer {
            Spacer()
            header
            nameTextField
            Spacer()
            continueButton
        }
        .onAppear { triggerAnimations() }
        .task {
            try? await Task.sleep(for: .seconds(AnimationDuration.slow))
            HapticManager.softTap()
        }
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
        .textContentType(.givenName)
        .submitLabel(.continue)
        .onSubmit {
            viewModel.advance()
        }
        .onChange(of: viewModel.name) { _, newValue in
            // Enforce the length limit while typing rather than silently disabling Continue.
            if newValue.count > OnboardingViewModel.maximumNameLength {
                viewModel.name = String(newValue.prefix(OnboardingViewModel.maximumNameLength))
            }
        }
        .entrance(contentAppeared, y: SlideOffset.standard)
    }

    var continueButton: some View {
        OnboardingButton("Continue".localized, isEnabled: viewModel.canAdvance) {
            viewModel.advance()
        }
        .entrance(contentAppeared, y: SlideOffset.standard)
        .accessibilityHint("Continues to the next step".localized)
    }
}

// MARK: - Animations

private extension NameScreen {
    func triggerAnimations() {
        withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
            contentAppeared = true
        }
    }
}

#Preview {
    NameScreen(viewModel: OnboardingViewModel())
}
