import SwiftUI
import DesignSystem

struct CompleteScreen: View {
    @Bindable var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            OnboardingHeader(
                icon: "checkmark.circle.fill",
                iconColor: DiamerisColors.accentSecondaryLight,
                title: String(localized: "You're all set!"),
                subtitle: String(localized: "Hi \(viewModel.trimmedName), your budget is ready."),
                useHeroIcon: true
            )

            summaryCard

            Text("You can add more details anytime in the Budget tab.", comment: "Helper text on completion screen")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Start Planning", comment: "Final onboarding button to enter the app")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: ComponentSize.buttonHeight)
            }
            .buttonStyle(.glassProminent)
            .accessibilityHint(String(localized: "Completes onboarding and opens the main app"))
        }
        .padding(Spacing.lg)
    }

    private var summaryCard: some View {
        VStack(spacing: Spacing.md) {
            SummaryRow(
                icon: "banknote.fill",
                label: String(localized: "Monthly Income"),
                value: AmountFormatter.formatForDisplay(viewModel.monthlyIncome, currency: viewModel.currency.rawValue)
            )

            Divider()

            SummaryRow(
                icon: "creditcard.fill",
                label: String(localized: "Expenses"),
                value: AmountFormatter.formatForDisplay(totalExpenses, currency: viewModel.currency.rawValue)
            )

            Divider()

            SummaryRow(
                icon: "building.columns.fill",
                label: String(localized: "Accounts"),
                value: "\(totalAccounts)"
            )
        }
        .glassCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "Budget summary"))
    }

    private var totalExpenses: Decimal {
        viewModel.expenses.reduce(0) { $0 + $1.amount }
    }

    private var totalAccounts: Int {
        1 + viewModel.additionalAccounts.count
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
                .frame(width: ComponentSize.iconContainer)
                .accessibilityHidden(true)

            Text(label)
                .font(.body)

            Spacer()

            Text(value)
                .font(.headline)
        }
        .accessibilityElement(children: .combine)
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
