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
            header
            Divider()
            summaryRows
        }
        .glassCard()
    }
}

// MARK: - Subviews

private extension SummaryCard {
    var header: some View {
        Label {
            Text("Monthly Summary".localized)
                .font(.headline)
        } icon: {
            Image(systemName: "chart.pie.fill")
                .foregroundStyle(DiamerisColors.accentPrimary)
        }
    }

    var summaryRows: some View {
        VStack(spacing: Spacing.sm) {
            summaryRow(
                label: "Income".localized,
                amount: income,
                style: .neutral
            )
            summaryRow(
                label: "Expenses".localized,
                amount: expenses,
                style: .negative
            )
            summaryRow(
                label: "Savings".localized,
                amount: savings,
                style: .positive
            )
            Divider()
            summaryRow(
                label: "Personal Spending".localized,
                amount: personalSpending,
                style: .neutral,
                isTotal: true
            )
        }
    }

    enum RowStyle {
        case neutral
        case positive
        case negative
    }

    func summaryRow(
        label: String,
        amount: Decimal,
        style: RowStyle,
        isTotal: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .foregroundStyle(isTotal ? .primary : .secondary)

            Spacer()

            Text(formatAmount(amount, style: style))
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .semibold : .regular)
                .foregroundStyle(color(for: style))
        }
    }

    func formatAmount(_ amount: Decimal, style: RowStyle) -> String {
        let prefix = style == .negative && amount > 0 ? "-" : ""
        return prefix + AmountFormatter.formatForDisplay(amount, currency: currency.rawValue)
    }

    func color(for style: RowStyle) -> Color {
        switch style {
        case .neutral: return .primary
        case .positive: return DiamerisColors.positive
        case .negative: return DiamerisColors.negative
        }
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
