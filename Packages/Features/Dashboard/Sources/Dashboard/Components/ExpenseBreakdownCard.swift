import SwiftUI
import DesignSystem
import Utilities

/// Card displaying expense breakdown by category.
struct ExpenseBreakdownCard: View {
    let expenses: [DashboardExpense]
    let totalExpenses: Decimal
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            header
            if sortedExpenses.isEmpty {
                emptyState
            } else {
                expenseList
            }
        }
        .glassCard()
    }

    private var sortedExpenses: [DashboardExpense] {
        expenses
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }
}

// MARK: - Subviews

private extension ExpenseBreakdownCard {
    var header: some View {
        Label {
            Text("Expense Breakdown".localized)
                .font(.headline)
        } icon: {
            Image(systemName: "chart.pie.fill")
                .foregroundStyle(DiamerisColors.accentSecondary)
        }
    }

    var emptyState: some View {
        Text("No expenses set".localized)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    var expenseList: some View {
        VStack(spacing: Spacing.xs) {
            ForEach(sortedExpenses.prefix(5)) { expense in
                expenseRow(expense)
            }
        }
    }

    func expenseRow(_ expense: DashboardExpense) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: expense.icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: ComponentSize.iconContainer)

            Text(expense.name)
                .font(.subheadline)

            Spacer()

            Text(AmountFormatter.formatForDisplay(expense.amount, currency: currency.rawValue))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            percentageBadge(for: expense)
        }
    }

    func percentageBadge(for expense: DashboardExpense) -> some View {
        let percentage: Int = {
            guard totalExpenses > 0 else { return 0 }
            let amount = NSDecimalNumber(decimal: expense.amount).doubleValue
            let total = NSDecimalNumber(decimal: totalExpenses).doubleValue
            return Int((amount / total) * 100)
        }()

        return Text("\(percentage)%")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.xxs)
            .background(Color.secondary.opacity(0.1), in: Capsule())
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
