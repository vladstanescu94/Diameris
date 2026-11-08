import SwiftUI
import DesignSystem
import Utilities

/// Shown when the month's expenses are larger than the income, so no plan can cover them.
struct ShortfallWarning: View {
    let shortfall: Decimal
    let currency: Currency

    var body: some View {
        Label {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DiamerisColors.warning)
        }
        .padding(Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DiamerisColors.warning.opacity(Opacity.faint), in: .rect(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private var message: String {
        let amount = AmountFormatter.formatForDisplay(shortfall, currency: currency.rawValue)
        return String(localized: "Expenses exceed income by \(amount)", bundle: .module)
    }
}

#Preview {
    ShortfallWarning(shortfall: 1250, currency: .ron)
        .padding()
}
