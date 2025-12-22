import SwiftUI
import DesignSystem

struct IncomeScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isAmountFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "banknote.fill")
                    .iconXxl()
                    .foregroundStyle(DiamerisColors.accentSecondaryLight)

                Text("Welcome, \(viewModel.trimmedName)!")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("How much do you receive each month after taxes?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Monthly net income")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                CurrencyAmountField(
                    amount: $viewModel.monthlyIncome,
                    currency: $viewModel.currency
                )
            }

            Text("This is your salary after all deductions.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

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
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    return IncomeScreen(viewModel: vm)
}
