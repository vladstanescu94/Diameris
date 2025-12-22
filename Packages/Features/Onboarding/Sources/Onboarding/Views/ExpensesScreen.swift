import SwiftUI
import DesignSystem

struct ExpensesScreen: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(DiamerisColors.accentPrimaryLight)

                Text("Let's estimate your main expenses")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Enter your typical monthly spending. You can skip this and add expenses later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

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

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button {
                    viewModel.advance()
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)

                Button {
                    for index in viewModel.expenses.indices {
                        viewModel.expenses[index].amount = 0
                    }
                    viewModel.advance()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                }
                .buttonStyle(.glass)
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
