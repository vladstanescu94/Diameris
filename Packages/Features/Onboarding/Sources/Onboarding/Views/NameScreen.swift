import SwiftUI
import DesignSystem

struct NameScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool

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

            Spacer()

            Button {
                viewModel.advance()
            } label: {
                Text("Continue", comment: "Primary button to advance to next onboarding step")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: ComponentSize.buttonHeight)
            }
            .buttonStyle(.glassProminent)
            .disabled(!viewModel.canAdvance)
            .accessibilityHint(String(localized: "Continues to the next step"))
        }
        .padding(Spacing.lg)
        .onAppear {
            isNameFocused = true
        }
    }
}

#Preview {
    NameScreen(viewModel: OnboardingViewModel())
}
