import SwiftUI
import DesignSystem
import SharedUI
import Utilities
import Domain

/// Split-mode input for one destination (emergency or savings):
/// a percentage-or-fixed toggle plus the matching slider or amount field.
struct SplitAmountInput: View {
    let title: String
    let icon: String
    @Binding var inputMode: SavingsInputMode
    @Binding var percentage: Double
    @Binding var amount: Decimal
    @Binding var currency: Currency
    /// Monthly amount the percentage resolves to (Domain calculation), shown next to it.
    let resolvedAmount: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(title, selection: $inputMode) {
                ForEach(SavingsInputMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch inputMode {
            case .percentage:
                percentageInput
            case .fixedAmount:
                CurrencyAmountField(
                    amount: $amount,
                    currency: $currency,
                    showCurrencyPicker: false,
                    accessibilityLabel: String(localized: "\(title) amount", bundle: .module)
                )
            }
        }
    }

    private var percentageInput: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(percentage, format: .percent.precision(.fractionLength(0)))
                    .font(.title3)
                    .bold()
                    .monospacedDigit()

                Spacer()

                if resolvedAmount > 0 {
                    Text(AmountFormatter.formatForDisplay(resolvedAmount, currency: currency.rawValue))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHidden(true) // The slider announces the same value.

            Slider(
                value: $percentage,
                in: SavingsAllocationEntry.minimumPercentage...SavingsAllocationEntry.maximumPercentage,
                step: Self.percentageStep
            ) {
                Text(title)
            }
            .tint(DiamerisColors.accentSecondary)
            .accessibilityValue(String(
                localized: "\(percentage.formatted(.percent.precision(.fractionLength(0)))), \(AmountFormatter.formatForDisplay(resolvedAmount, currency: currency.rawValue)) per month",
                bundle: .module
            ))
        }
    }

    private static let percentageStep = 0.01
}
