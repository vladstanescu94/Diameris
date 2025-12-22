import SwiftUI
import DesignSystem

struct CompleteScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(DiamerisColors.accentSecondaryLight)

                Text("You're all set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Hi \(viewModel.trimmedName), your budget is ready.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            summaryCard

            Text("You can add more details anytime in the Budget tab.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Start Planning")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(Spacing.lg)
    }

    private var summaryCard: some View {
        VStack(spacing: Spacing.md) {
            SummaryRow(
                icon: "banknote.fill",
                label: "Monthly Income",
                value: formatAmount(viewModel.monthlyIncome)
            )

            Divider()

            SummaryRow(
                icon: "creditcard.fill",
                label: "Expenses",
                value: formatAmount(totalExpenses)
            )

            Divider()

            SummaryRow(
                icon: "building.columns.fill",
                label: "Accounts",
                value: "\(totalAccounts)"
            )
        }
        .glassCard()
    }

    private var totalExpenses: Decimal {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
    }

    private var totalAccounts: Int {
        1 + viewModel.additionalAccounts.count
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        let formatted = formatter.string(from: number) ?? "0"
        return "\(formatted) \(viewModel.currency.rawValue)"
    }
}

private struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 32)

            Text(label)
                .font(.body)

            Spacer()

            Text(value)
                .font(.headline)
        }
    }
}

#Preview {
    let vm = OnboardingViewModel()
    vm.name = "Vlad"
    vm.monthlyIncome = 14303
    vm.expenses[0].amount = 3000
    vm.expenses[2].amount = 300
    return CompleteScreen(viewModel: vm, onComplete: {})
}
