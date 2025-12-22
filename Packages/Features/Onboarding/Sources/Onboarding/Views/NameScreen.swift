import SwiftUI
import DesignSystem

struct NameScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool
    @State private var contentAppeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            OnboardingHeader(
                icon: "person.circle.fill",
                iconColor: DiamerisColors.accentPrimaryLight,
                title: String(localized: "What should we call you?"),
                subtitle: String(localized: "We'll use this to personalize your experience.")
            )

            OnboardingTextField(
                "",
                text: $viewModel.name,
                prompt: String(localized: "Your name")
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

            Spacer()

            OnboardingButton("Continue", isEnabled: viewModel.canAdvance) {
                viewModel.advance()
            }
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : SlideOffset.standard)
            .accessibilityHint(String(localized: "Continues to the next step"))
        }
        .padding(Spacing.lg)
        .onAppear {
            withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
                contentAppeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + AnimationDuration.slow) {
                HapticManager.softTap()
            }
        }
    }
}

#Preview {
    NameScreen(viewModel: OnboardingViewModel())
}
