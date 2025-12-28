import SwiftUI
import DesignSystem
import Utilities

/// Card displaying the monthly financial summary.
struct SummaryCard: View {
    let income: Decimal
    let expenses: Decimal
    let available: Decimal
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
            Text("Available This Month".localized)
                .font(.headline)
        } icon: {
            Image(systemName: "dollarsign.circle.fill")
                .foregroundStyle(DiamerisColors.accentPrimary)
        }
    }

    var summaryRows: some View {
        VStack(spacing: Spacing.sm) {
            summaryRow(
                label: "Income".localized,
                amount: income,
                isNegative: false
            )
            summaryRow(
                label: "Expenses".localized,
                amount: expenses,
                isNegative: true
            )
            Divider()
            summaryRow(
                label: "Available".localized,
                amount: available,
                isNegative: false,
                isTotal: true
            )
        }
    }

    func summaryRow(
        label: String,
        amount: Decimal,
        isNegative: Bool,
        isTotal: Bool = false
    ) -> some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .foregroundStyle(isTotal ? .primary : .secondary)

            Spacer()

            Text(formatAmount(amount, isNegative: isNegative))
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .semibold : .regular)
                .foregroundStyle(isNegative ? DiamerisColors.negative : .primary)
        }
    }

    func formatAmount(_ amount: Decimal, isNegative: Bool) -> String {
        let prefix = isNegative && amount > 0 ? "-" : ""
        return prefix + AmountFormatter.formatForDisplay(amount, currency: currency.rawValue)
    }
}

#Preview {
    SummaryCard(
        income: 14303,
        expenses: 7205,
        available: 7098,
        currency: .ron
    )
    .padding()
}
