import SwiftUI
import DesignSystem

struct IncomeScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            OnboardingHeader(
                icon: "banknote.fill",
                iconColor: DiamerisColors.accentSecondaryLight,
                title: String(localized: "Welcome, \(viewModel.trimmedName)!"),
                subtitle: String(localized: "How much do you receive each month after taxes?")
            )

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Monthly net income", comment: "Label for income input field")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                CurrencyAmountField(
                    amount: $viewModel.monthlyIncome,
                    currency: $viewModel.currency
                )
                .accessibilityLabel(String(localized: "Monthly income amount"))
            }

            Text("This is your salary after all deductions.", comment: "Helper text explaining net income")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

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
            .accessibilityHint(String(localized: "Continues to the expenses step"))
        }
        .padding(Spacing.lg)
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    return IncomeScreen(viewModel: vm)
}
