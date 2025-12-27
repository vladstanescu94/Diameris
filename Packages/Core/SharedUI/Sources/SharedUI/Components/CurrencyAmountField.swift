import SwiftUI
import DesignSystem
import Utilities

/// A text field for entering monetary amounts with currency picker.
public struct CurrencyAmountField: View {
    @Binding var amount: Decimal
    @Binding var currency: Currency
    let showCurrencyPicker: Bool

    @State private var amountText: String = ""
    @FocusState private var isFocused: Bool

    public init(
        amount: Binding<Decimal>,
        currency: Binding<Currency>,
        showCurrencyPicker: Bool = true
    ) {
        self._amount = amount
        self._currency = currency
        self.showCurrencyPicker = showCurrencyPicker
    }

    public var body: some View {
        HStack(spacing: Spacing.sm) {
            currencySelector
            amountTextField
        }
        .padding(Spacing.md)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - Subviews

private extension CurrencyAmountField {
    @ViewBuilder
    var currencySelector: some View {
        if showCurrencyPicker {
            Menu {
                ForEach(Currency.allCases) { curr in
                    Button(curr.displayName) {
                        currency = curr
                    }
                }
            } label: {
                HStack(spacing: Spacing.xxs) {
                    Text(currency.rawValue)
                        .font(.headline)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.glass)
            .accessibilityLabel(String(localized: "Currency: \(currency.displayName)"))
            .accessibilityHint(String(localized: "Double tap to change currency"))
        } else {
            Text(currency.rawValue)
                .font(.headline)
                .padding(.horizontal, Spacing.sm)
        }
    }

    var amountTextField: some View {
        TextField("0", text: $amountText)
            .font(.title2)
            .fontWeight(.semibold)
            .keyboardType(.decimalPad)
            .focused($isFocused)
            .multilineTextAlignment(.trailing)
            .onChange(of: amountText) { _, newValue in
                amount = AmountFormatter.parse(newValue)
            }
            .onAppear {
                if amount > 0 {
                    amountText = AmountFormatter.formatForEditing(amount)
                }
            }
            .accessibilityLabel(String(localized: "Amount"))
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        CurrencyAmountField(
            amount: .constant(0),
            currency: .constant(.ron)
        )

        CurrencyAmountField(
            amount: .constant(14303),
            currency: .constant(.eur)
        )
    }
    .padding()
}
