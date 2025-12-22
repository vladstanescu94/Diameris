import SwiftUI
import DesignSystem

struct IncomeScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isAmountFocused: Bool
    @State private var contentAppeared = false

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
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : SlideOffset.standard)

            Text("This is your salary after all deductions.", comment: "Helper text explaining net income")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(contentAppeared ? 1 : 0)

            Spacer()

            OnboardingButton("Continue", isEnabled: viewModel.canAdvance) {
                viewModel.advance()
            }
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : SlideOffset.standard)
            .accessibilityHint(String(localized: "Continues to the expenses step"))
        }
        .padding(Spacing.lg)
        .onAppear {
            withAnimation(SpringPreset.smooth.delay(StaggerDelay.initial)) {
                contentAppeared = true
            }
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    return IncomeScreen(viewModel: vm)
}
