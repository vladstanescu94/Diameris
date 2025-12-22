import SwiftUI
import DesignSystem

struct NameScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "person.circle.fill")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentPrimaryLight)

                Text("What should we call you?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("We'll use this to personalize your experience.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

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
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: ComponentSize.buttonHeight)
            }
            .buttonStyle(.glassProminent)
            .disabled(!viewModel.canAdvance)
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
