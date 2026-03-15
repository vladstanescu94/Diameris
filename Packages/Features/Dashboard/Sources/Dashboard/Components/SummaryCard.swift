import SwiftUI
import DesignSystem
import Utilities

/// Card displaying the monthly financial summary.
struct SummaryCard: View {
    let income: Decimal
    let expenses: Decimal
    let savings: Decimal
    let personalSpending: Decimal
    let currency: Currency

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label {
                Text("Monthly Summary".localized)
                    .font(.headline)
            } icon: {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(DiamerisColors.accentPrimary)
            }

            Divider()

            VStack(spacing: Spacing.sm) {
                SummaryRow(
                    label: "Income".localized,
                    amount: income,
                    style: .neutral,
                    currency: currency
                )
                SummaryRow(
                    label: "Expenses".localized,
                    amount: expenses,
                    style: .negative,
                    currency: currency
                )
                SummaryRow(
                    label: "Savings".localized,
                    amount: savings,
                    style: .positive,
                    currency: currency
                )
                Divider()
                SummaryRow(
                    label: "Personal Spending".localized,
                    amount: personalSpending,
                    style: .neutral,
                    currency: currency,
                    isTotal: true
                )
            }
        }
        .glassCard()
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let label: String
    let amount: Decimal
    let style: RowStyle
    let currency: Currency
    var isTotal: Bool = false

    enum RowStyle {
        case neutral
        case positive
        case negative

        var color: Color {
            switch self {
            case .neutral: .primary
            case .positive: DiamerisColors.positive
            case .negative: DiamerisColors.negative
            }
        }
    }

    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .foregroundStyle(isTotal ? .primary : .secondary)

            Spacer()

            Text(formattedAmount)
                .font(isTotal ? .headline : .subheadline)
                .bold(isTotal)
                .foregroundStyle(style.color)
        }
    }

    private var formattedAmount: String {
        let prefix = style == .negative && amount > 0 ? "-" : ""
        return prefix + AmountFormatter.formatForDisplay(amount, currency: currency.rawValue)
    }
}

#Preview {
    SummaryCard(
        income: 14303,
        expenses: 5555,
        savings: 2397,
        personalSpending: 573,
        currency: .ron
    )
    .padding()
}
