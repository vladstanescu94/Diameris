import SwiftUI
import DesignSystem

struct ExpensesScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            OnboardingHeader(
                icon: "creditcard.fill",
                iconColor: DiamerisColors.accentPrimaryLight,
                title: String(localized: "Let's estimate your main expenses"),
                subtitle: String(localized: "Enter your typical monthly spending. You can skip this and add expenses later.")
            )

            GlassEffectContainer {
                VStack(spacing: Spacing.sm) {
                    ForEach($viewModel.expenses) { $expense in
                        ExpenseRow(
                            icon: expense.icon,
                            name: expense.name,
                            amount: $expense.amount,
                            currency: viewModel.currency
                        )
                    }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "Expense categories"))

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button {
                    viewModel.advance()
                } label: {
                    Text("Continue", comment: "Primary button to advance to next onboarding step")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: ComponentSize.buttonHeight)
                }
                .buttonStyle(.glassProminent)
                .accessibilityHint(String(localized: "Continues to the accounts step"))

                Button {
                    for index in viewModel.expenses.indices {
                        viewModel.expenses[index].amount = 0
                    }
                    viewModel.advance()
                } label: {
                    Text("Skip for now", comment: "Secondary button to skip expenses entry")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, minHeight: ComponentSize.buttonHeight)
                }
                .buttonStyle(.glass)
                .accessibilityHint(String(localized: "Skips expense entry and continues to accounts"))
            }
        }
        .padding(Spacing.lg)
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    return ExpensesScreen(viewModel: vm)
}
