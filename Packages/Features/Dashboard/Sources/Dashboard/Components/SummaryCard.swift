import SwiftUI
import DesignSystem
import Domain
import Utilities

struct SummaryCard: View {
    let income: Decimal
    let expenses: Decimal
    let savings: Decimal
    let remainingMoney: Decimal
    let remainingDestination: RemainingMoneyDestination
    let shortfall: Decimal
    let currency: Currency

    /// The last row names where the leftover money goes, not always personal spending.
    static func remainingLabel(for destination: RemainingMoneyDestination) -> String {
        switch destination {
        case .personal: "Personal Spending".localized
        case .primarySavings: "Extra Savings".localized
        case .primary: "Stays in Primary".localized
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label {
                Text("Monthly Summary".localized)
                    .font(.headline)
            } icon: {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(DiamerisColors.accentPrimary)
            }
            .accessibilityAddTraits(.isHeader)

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
                    label: Self.remainingLabel(for: remainingDestination),
                    amount: remainingMoney,
                    style: .neutral,
                    currency: currency,
                    isTotal: true
                )
            }

            if shortfall > 0 {
                ShortfallWarning(shortfall: shortfall, currency: currency)
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
        .accessibilityElement(children: .combine)
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
        remainingMoney: 573,
        remainingDestination: .personal,
        shortfall: 0,
        currency: .ron
    )
    .padding()
}
