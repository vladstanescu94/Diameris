import SwiftUI
import DesignSystem
import Domain
import Utilities

struct ExpenseBreakdownCard: View {
    let expenses: [DashboardExpense]
    let totalExpenses: Decimal
    let currency: Currency

    private static let visibleExpenseCount = 5

    var body: some View {
        let topExpenses = self.topExpenses

        VStack(alignment: .leading, spacing: Spacing.md) {
            Label {
                Text("Expense Breakdown".localized)
                    .font(.headline)
            } icon: {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(DiamerisColors.accentSecondary)
            }
            .accessibilityAddTraits(.isHeader)

            if topExpenses.isEmpty {
                Text("No expenses set".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(topExpenses) { expense in
                        BreakdownExpenseRow(
                            expense: expense,
                            totalExpenses: totalExpenses,
                            currency: currency
                        )
                    }
                }
            }
        }
        .glassCard()
    }

    private var topExpenses: [DashboardExpense] {
        Array(
            expenses
                .filter { $0.amount > 0 }
                .sorted { $0.amount > $1.amount }
                .prefix(Self.visibleExpenseCount)
        )
    }
}

// MARK: - Breakdown Expense Row

private struct BreakdownExpenseRow: View {
    let expense: DashboardExpense
    let totalExpenses: Decimal
    let currency: Currency

    @ScaledMetric(relativeTo: .body) private var iconWidth = ComponentSize.iconContainer

    private var share: Double {
        expense.toExpenseEntry().share(ofTotal: totalExpenses)
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: expense.icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            Text(expense.name)
                .font(.subheadline)

            Spacer()

            Text(AmountFormatter.formatForDisplay(expense.amount, currency: currency.rawValue))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(share, format: .percent.precision(.fractionLength(0)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(Color.secondary.opacity(Opacity.faint), in: Capsule())
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ExpenseBreakdownCard(
        expenses: [
            DashboardExpense(id: UUID(), name: "Auto", amount: 3600, icon: "car.fill", linkedAccountId: nil),
            DashboardExpense(id: UUID(), name: "Food", amount: 3000, icon: "cart.fill", linkedAccountId: nil),
            DashboardExpense(id: UUID(), name: "Subscriptions", amount: 605, icon: "creditcard.fill", linkedAccountId: nil)
        ],
        totalExpenses: 7205,
        currency: .ron
    )
    .padding()
}
